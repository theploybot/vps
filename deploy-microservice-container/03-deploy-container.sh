#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_REF:?IMAGE_REF is required}"
: "${CONTAINER_NAME:?CONTAINER_NAME is required}"
: "${NETWORK_NAME:?NETWORK_NAME is required}"
: "${DOCKER_RUN_ARGS:=}"
: "${CONTAINER_COMMAND:?CONTAINER_COMMAND is required}"

echo "🚀 Deploying container: $CONTAINER_NAME"
echo "   Image: $IMAGE_REF"
echo "   Network: $NETWORK_NAME"

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed"
  exit 1
fi

sudo docker network create "$NETWORK_NAME" >/dev/null 2>&1 || true

if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "🛑 Removing existing container: $CONTAINER_NAME"
  sudo docker rm -f "$CONTAINER_NAME" || true
fi

echo "🔄 Starting new container"

# shellcheck disable=SC2086
sudo docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network "$NETWORK_NAME" \
  $DOCKER_RUN_ARGS \
  "$IMAGE_REF" \
  sh -c "$CONTAINER_COMMAND"

echo "⏳ Waiting for container to reach running state..."
for i in $(seq 1 30); do
  status="$(sudo docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo none)"
  if [ "$status" = "running" ]; then
    echo "✅ Container is running"
    break
  fi
  if [ "$status" = "exited" ]; then
    echo "❌ Container exited unexpectedly"
    sudo docker logs --tail=100 "$CONTAINER_NAME" || true
    exit 1
  fi
  echo "   attempt $i/30 status=$status"
  sleep 2
done

echo "📊 Container status:"
sudo docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "📝 Recent logs:"
sudo docker logs --tail=50 "$CONTAINER_NAME" || true