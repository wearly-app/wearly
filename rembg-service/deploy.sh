#!/bin/bash

set -Eeuo pipefail

APP_DIR="/home/ubuntu/app/wearly/back"
LOG_FILE="/home/ubuntu/app/wearly/back/deploy.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" | tee -a "$LOG_FILE"
}

fail() {
  log "ERROR" "$1"
  exit 1
}

cd "$APP_DIR" || fail "Application directory not found: $APP_DIR"

[[ -f deploy.env ]] || fail "deploy.env not found"
[[ -f prod.env ]] || fail "prod.env not found"

set -a
source deploy.env
source prod.env
set +a

[[ -n "${AWS_REGION:-}" ]] || fail "AWS_REGION is not configured"
[[ -n "${AWS_ACCOUNT_ID:-}" ]] || fail "AWS_ACCOUNT_ID is not configured"
[[ -n "${ECR_REPO:-}" ]] || fail "ECR_REPO is not configured"
[[ -n "${REMBG_ECR_REPO:-}" ]] || fail "REMBG_ECR_REPO is not configured"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:latest"
REMBG_ECR_IMAGE="${ECR_REGISTRY}/${REMBG_ECR_REPO}:latest"

export ECR_IMAGE
export REMBG_ECR_IMAGE

log "INFO" "Login to ECR"
timeout 30 aws ecr get-login-password --region "$AWS_REGION" |
  timeout 30 docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

log "INFO" "Pull latest rembg image"
timeout 300 docker pull "$REMBG_ECR_IMAGE"

log "INFO" "Recreate rembg container"
docker compose \
  --env-file prod.env \
  -f docker-compose-prod.yml \
  up -d --no-deps --force-recreate rembg-service

log "INFO" "Wait for rembg service health check"
for attempt in $(seq 1 60); do
  REMBG_HEALTH_STATUS="$(
    docker inspect \
      -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}starting{{end}}' \
      wearly-rembg \
      2>/dev/null || true
  )"

  if [[ "$REMBG_HEALTH_STATUS" == "healthy" ]]; then
    break
  fi

  if [[ "$REMBG_HEALTH_STATUS" == "unhealthy" ]]; then
    docker logs --tail 100 wearly-rembg | tee -a "$LOG_FILE"
    fail "Rembg container health check failed"
  fi

  if [[ "$attempt" -eq 60 ]]; then
    docker logs --tail 100 wearly-rembg | tee -a "$LOG_FILE"
    fail "Rembg container did not become healthy in time"
  fi

  sleep 5
done

log "INFO" "Rembg container is healthy"
docker compose \
  --env-file prod.env \
  -f docker-compose-prod.yml \
  ps rembg-service

log "INFO" "Remove dangling images after deployment"
docker image prune -f

log "INFO" "Rembg deployment complete"
