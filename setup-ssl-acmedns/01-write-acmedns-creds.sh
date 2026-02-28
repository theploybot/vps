#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN:?DOMAIN is required}"
: "${ACMEDNS_USERNAME:?ACMEDNS_USERNAME is required}"
: "${ACMEDNS_PASSWORD:?ACMEDNS_PASSWORD is required}"
: "${ACMEDNS_FULLDOMAIN:?ACMEDNS_FULLDOMAIN is required}"
: "${ACMEDNS_SUBDOMAIN:?ACMEDNS_SUBDOMAIN is required}"
: "${CERT_DIR:?CERT_DIR is required}"

echo "🔐 Setting up ACME-DNS credentials for $DOMAIN"

ACMEDNS_CONFIG_DIR="$CERT_DIR/acmedns"
sudo mkdir -p "$ACMEDNS_CONFIG_DIR"

ACMEDNS_REGISTRATION="$ACMEDNS_CONFIG_DIR/acmedns.json"
ACMEDNS_CREDENTIALS="$ACMEDNS_CONFIG_DIR/credentials.ini"

tmp_json="$(mktemp)"
cat > "$tmp_json" <<JSON
{
  "$DOMAIN": {
    "username": "$ACMEDNS_USERNAME",
    "password": "$ACMEDNS_PASSWORD",
    "fulldomain": "$ACMEDNS_FULLDOMAIN",
    "subdomain": "$ACMEDNS_SUBDOMAIN",
    "allowfrom": []
  }
}
JSON

sudo install -m 0600 "$tmp_json" "$ACMEDNS_REGISTRATION"
rm -f "$tmp_json"

tmp_ini="$(mktemp)"
cat > "$tmp_ini" <<INI
dns_acmedns_api_url = https://auth.acme-dns.io
dns_acmedns_registration_file = $ACMEDNS_REGISTRATION
INI

sudo install -m 0600 "$tmp_ini" "$ACMEDNS_CREDENTIALS"
rm -f "$tmp_ini"

echo "✅ ACME-DNS credentials configured"
echo "   Registration: $ACMEDNS_REGISTRATION"
echo "   Credentials: $ACMEDNS_CREDENTIALS"