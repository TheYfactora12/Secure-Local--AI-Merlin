#!/usr/bin/env bash
# home-ai-elite — Generate self-signed TLS certificate for Nginx (v0.7)
# Run once on first boot. Re-run to regenerate.
# Output: <repo>/certs/selfsigned.crt + selfsigned.key

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STACK_DIR="${HOME_AI_STACK_DIR:-$( cd "${SCRIPT_DIR}/.." && pwd )}"
CERTS_DIR="${HOME_AI_CERTS_DIR:-${STACK_DIR}/certs}"
DAYS=3650  # 10-year self-signed cert

mkdir -p "${CERTS_DIR}"

echo "🔐 Generating self-signed TLS certificate..."
openssl req -x509 \
  -newkey rsa:4096 \
  -keyout "${CERTS_DIR}/selfsigned.key" \
  -out "${CERTS_DIR}/selfsigned.crt" \
  -days ${DAYS} \
  -nodes \
  -subj "/C=US/ST=Local/L=Local/O=HomeAIElite/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
  2>/dev/null

chmod 600 "${CERTS_DIR}/selfsigned.key"
chmod 644 "${CERTS_DIR}/selfsigned.crt"

echo "✅ Certificate generated: ${CERTS_DIR}/selfsigned.crt"
echo "✅ Private key:          ${CERTS_DIR}/selfsigned.key"
echo ""
echo "💡 Add localhost exception in your browser (certificate is self-signed)."
echo "   Chrome: type 'thisisunsafe' on the warning page."
echo "   Safari: Advanced > Trust Certificate."
