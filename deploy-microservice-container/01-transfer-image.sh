#!/usr/bin/env bash
set -euo pipefail

: "${REMOTE_IMAGES_DIR:?REMOTE_IMAGES_DIR is required}"

echo "📁 Ensuring remote image directory exists: $REMOTE_IMAGES_DIR"
mkdir -p "$REMOTE_IMAGES_DIR"
echo "✅ Remote directory ready"