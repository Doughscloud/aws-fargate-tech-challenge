#!/usr/bin/env bash
set -euo pipefail
SERVICE_NAME="$1"
IMAGE="$2"
CLUSTER="${ECS_CLUSTER:?ECS_CLUSTER not set}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
CPU="${CPU:-512}"
MEMORY="${MEMORY:-1024}"
PORT="${PORT:-80}"
LOG_GROUP="${LOG_GROUP:-/ecs/$SERVICE_NAME}"
EXEC_ROLE_ARN="${EXEC_ROLE_ARN:?EXEC_ROLE_ARN not set}"
TASK_ROLE_ARN="${TASK_ROLE_ARN:?TASK_ROLE_ARN not set}"
CONTAINER_NAME="${CONTAINER_NAME:-$SERVICE_NAME}"
ENV_VARS="${ENV_VARS:-}"  # KEY=VAL,KEY2=VAL2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKDEF_JSON="$(
  node "$SCRIPT_DIR/render-taskdef-json.js" \
    --family "$SERVICE_NAME" \
    --image "$IMAGE" \
    --cpu "$CPU" \
    --memory "$MEMORY" \
    --port "$PORT" \
    --name "$CONTAINER_NAME" \
    --logGroup "$LOG_GROUP" \
    --region "$REGION" \
    --execRole "$EXEC_ROLE_ARN" \
    --taskRole "$TASK_ROLE_ARN" \
    --env "$ENV_VARS"
)"
REVISION_ARN="$(echo "$TASKDEF_JSON" | aws ecs register-task-definition --cli-input-json file:///dev/stdin --query 'taskDefinition.taskDefinitionArn' --output text)"
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE_NAME" --task-definition "$REVISION_ARN" >/dev/null
echo "Updated $SERVICE_NAME to $REVISION_ARN"
