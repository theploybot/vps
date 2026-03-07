#!/usr/bin/env bash
set -euo pipefail

: "${REMOTE_IMAGES_DIR:?REMOTE_IMAGES_DIR is required}"
: "${ARCHIVE_BASENAME:?ARCHIVE_BASENAME is required}"
: "${IMAGE_REF:?IMAGE_REF is required}"

ARCHIVE_PATH="$REMOTE_IMAGES_DIR/$ARCHIVE_BASENAME"

if [ ! -f "$ARCHIVE_PATH" ]; then
  echo "❌ Archive not found: $ARCHIVE_PATH"
  ls -lah "$REMOTE_IMAGES_DIR" || true
  exit 1
fi

echo "📦 Loading Docker image from: $ARCHIVE_PATH"
sudo docker load -i "$ARCHIVE_PATH"

echo "🔍 Verifying image exists: $IMAGE_REF"
if ! sudo docker image inspect "$IMAGE_REF" >/dev/null 2>&1; then
  echo "❌ Expected image not found after docker load: $IMAGE_REF"
  echo "📋 Available images:"
  sudo docker images
  exit 1
fi

echo "✅ Image loaded successfully: $IMAGE_REF"