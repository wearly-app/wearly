#!/bin/bash

set -e

APP_DIR="/home/ubuntu/app/back"
LOG_FILE="/home/ubuntu/app/deploy.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" | tee -a "$LOG_FILE"
}

cd "$APP_DIR"

log "INFO" "Pull latest source"
git pull origin backend

source deploy.env

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:latest"

log "INFO" "Login to ECR"
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

log "INFO" "Pull latest image"
docker pull "$ECR_IMAGE"

log "INFO" "Restart application container"
docker compose --env-file prod.env -f docker-compose-prod.yml down app
docker compose --env-file prod.env -f docker-compose-prod.yml up -d app

log "INFO" "Deployment complete"
