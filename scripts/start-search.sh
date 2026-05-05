#!/usr/bin/env bash
# Home AI Elite — start optional search profile
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

bash "${SCRIPT_DIR}/start-core.sh"

cd "$STACK_DIR"
echo "Starting search profile..."
docker compose up -d searxng perplexica-backend perplexica-frontend
echo "Search profile started."
echo "Perplexica: http://localhost:3002"
