#!/usr/bin/env bash
# Home AI Elite — start full profile intentionally
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

cat <<'TXT'
Full profile starts core, search, automation, coding, proxy, and ops services.
This is not recommended on low-memory laptops.
TXT

if [[ "${HOME_AI_ASSUME_YES:-false}" != "true" ]]; then
  printf "Start full profile? [y/N] "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

bash "${SCRIPT_DIR}/start-core.sh"

cd "$STACK_DIR"
echo "Starting full profile..."
if [[ "$(uname -s)" == "Darwin" ]]; then
  docker compose up -d searxng perplexica-backend perplexica-frontend n8n openhands nginx watchtower
else
  docker compose --profile docker-ollama --profile linux-security up -d
fi

echo "Full profile started."
echo "Run: bash scripts/status.sh"
