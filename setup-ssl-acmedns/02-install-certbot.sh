#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing certbot and certbot-dns-acmedns plugin..."

if ! command -v certbot >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y certbot python3-pip
fi

if ! python3 -c "import certbot_dns_acmedns" 2>/dev/null; then
  sudo pip3 install --break-system-packages certbot-dns-acmedns
fi

echo "✅ Certbot + plugin ready"