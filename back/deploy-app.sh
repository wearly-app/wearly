#!/bin/bash

set -Eeuo pipefail

APP_DIR="/home/ubuntu/app/wearly/back"
LOG_FILE="/home/ubuntu/app/wearly/back/deploy.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" |
    tee -a "$LOG_FILE"
}

fail() {
  log "ERROR" "$1"
  exit 1
}

cd "$APP_DIR" ||
  fail "Application directory not found: $APP_DIR"

[[ -f deploy.env ]] ||
  fail "deploy.env not found"

[[ -f prod.env ]] ||
  fail "prod.env not found"

set -a
source deploy.env
source prod.env
set +a

[[ -n "${AWS_REGION:-}" ]] ||
  fail "AWS_REGION is not configured"

[[ -n "${AWS_ACCOUNT_ID:-}" ]] ||
  fail "AWS_ACCOUNT_ID is not configured"

[[ -n "${ECR_REPO:-}" ]] ||
  fail "ECR_REPO is not configured"

[[ -n "${REMBG_ECR_REPO:-}" ]] ||
  fail "REMBG_ECR_REPO is not configured"

[[ -n "${AWS_ACCESS_KEY_ID:-}" ]] ||
  fail "AWS_ACCESS_KEY_ID is not configured"

[[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]] ||
  fail "AWS_SECRET_ACCESS_KEY is not configured"

if [[ "$AWS_ACCOUNT_ID" == "YOUR_AWS_ACCOUNT_ID" ]]; then
  fail "AWS_ACCOUNT_ID still has the example value"
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:latest"
REMBG_ECR_IMAGE="${ECR_REGISTRY}/${REMBG_ECR_REPO}:latest"

export ECR_IMAGE
export REMBG_ECR_IMAGE

log "INFO" "Login to ECR"

ECR_PASSWORD="$(
  AWS_EC2_METADATA_DISABLED=true \
  AWS_MAX_ATTEMPTS=1 \
  AWS_RETRY_MODE=standard \
  timeout 60 aws ecr get-login-password \
    --region "$AWS_REGION" \
    --cli-connect-timeout 5 \
    --cli-read-timeout 15
)" || fail "Failed to get ECR login password"

[[ -n "$ECR_PASSWORD" ]] ||
  fail "ECR login password is empty"

printf '%s' "$ECR_PASSWORD" |
  timeout 60 docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY" ||
  fail "Failed to login to ECR"

unset ECR_PASSWORD

log "INFO" "Pull latest application image"

timeout 180 docker pull "$ECR_IMAGE" ||
  fail "Failed to pull application image"

log "INFO" "Recreate application container"

docker compose \
  --env-file deploy.env \
  --env-file prod.env \
  -f docker-compose-prod.yml \
  up -d \
  --no-deps \
  --force-recreate app ||
  fail "Failed to recreate application container"

log "INFO" "Wait for application startup"

sleep 10

if ! docker inspect -f '{{.State.Running}}' wearly-app |
  grep -q true; then
  docker logs --tail 100 wearly-app |
    tee -a "$LOG_FILE"

  fail "Application container failed to start"
fi

log "INFO" "Application container is running"

docker compose \
  --env-file deploy.env \
  --env-file prod.env \
  -f docker-compose-prod.yml \
  ps

log "INFO" "Remove images unused after deployment"

docker image prune -f

log "INFO" "Application deployment complete"