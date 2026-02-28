#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN:?DOMAIN is required}"
: "${WILDCARD:?WILDCARD is required}"
: "${EMAIL:?EMAIL is required}"
: "${CERT_DIR:?CERT_DIR is required}"
: "${FORCE_RENEWAL:?FORCE_RENEWAL is required}"
: "${NGINX_CONTAINER:=}"

echo "🔐 Obtaining SSL certificate with ACME-DNS"
echo "   Domain: $DOMAIN"
echo "   Wildcard: $WILDCARD"

sudo mkdir -p "$CERT_DIR"

ACMEDNS_CREDENTIALS="$CERT_DIR/acmedns/credentials.ini"
sudo test -f "$ACMEDNS_CREDENTIALS"

DOMAIN_ARGS=(-d "$DOMAIN")
if [ "$WILDCARD" = "true" ]; then
  DOMAIN_ARGS+=(-d "*.$DOMAIN")
fi

FORCE_FLAG=()
if [ "$FORCE_RENEWAL" = "true" ]; then
  FORCE_FLAG+=(--force-renewal)
fi

sudo certbot certonly \
  -a dns-acmedns \
  --dns-acmedns-credentials "$ACMEDNS_CREDENTIALS" \
  --dns-acmedns-propagation-seconds 2 \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --key-type ecdsa \
  "${FORCE_FLAG[@]}" \
  "${DOMAIN_ARGS[@]}"

CERT_PATH="$CERT_DIR/live/$DOMAIN/fullchain.pem"
KEY_PATH="$CERT_DIR/live/$DOMAIN/privkey.pem"
sudo test -f "$CERT_PATH"
sudo test -f "$KEY_PATH"

# Deploy hook for renewals
if [ -n "$NGINX_CONTAINER" ]; then
  HOOK_DIR="$CERT_DIR/renewal-hooks/deploy"
  sudo mkdir -p "$HOOK_DIR"
  sudo tee "$HOOK_DIR/reload-nginx.sh" >/dev/null <<HOOK
#!/usr/bin/env bash
set -euo pipefail
NGINX_CONTAINER="${NGINX_CONTAINER}"
if sudo docker ps --format '{{.Names}}' | grep -q "^\\\${NGINX_CONTAINER}\$"; then
  sudo docker exec "\\\${NGINX_CONTAINER}" nginx -s reload
fi
HOOK
  sudo chmod 755 "$HOOK_DIR/reload-nginx.sh"

  # Reload now (best effort)
  if sudo docker ps --format '{{.Names}}' | grep -q "^${NGINX_CONTAINER}$"; then
    sudo docker exec "$NGINX_CONTAINER" nginx -s reload || true
  fi
fi

echo "✅ Certificate issued and deploy hook set."
echo "   $CERT_PATH"
echo "   $KEY_PATH"