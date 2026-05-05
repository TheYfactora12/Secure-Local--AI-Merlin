#!/usr/bin/env bash
# Home AI Elite — start optional automation profile
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

bash "${SCRIPT_DIR}/start-core.sh"

cd "$STACK_DIR"
echo "Starting automation profile..."
docker compose up -d n8n
echo "Automation profile started."
echo "n8n: http://localhost:5678"
