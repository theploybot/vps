#!/usr/bin/env bash
set -euo pipefail

: "${HEALTH_CHECK_CMD:?HEALTH_CHECK_CMD is required}"
: "${HEALTH_CHECK_TIMEOUT:?HEALTH_CHECK_TIMEOUT is required}"
: "${CONTAINER_NAME:?CONTAINER_NAME is required}"

echo "🏥 Running health check for container: $CONTAINER_NAME"
echo "   Command: $HEALTH_CHECK_CMD"
echo "   Timeout: ${HEALTH_CHECK_TIMEOUT}s"

for i in $(seq 1 "$HEALTH_CHECK_TIMEOUT"); do
  if bash -lc "$HEALTH_CHECK_CMD"; then
    echo "✅ Health check passed"
    exit 0
  fi

  echo "   attempt $i/${HEALTH_CHECK_TIMEOUT} failed"
  sleep 1
done

echo "❌ Health check failed"
echo "📊 Container status:"
sudo docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

echo "📝 Recent logs:"
sudo docker logs --tail=100 "$CONTAINER_NAME" || true
exit 1