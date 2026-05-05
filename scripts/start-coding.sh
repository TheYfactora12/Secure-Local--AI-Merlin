#!/usr/bin/env bash
# Home AI Elite — start optional coding profile
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

bash "${SCRIPT_DIR}/start-core.sh"

cat <<'TXT'
OpenHands uses Docker socket access and can control containers on this machine.
Start it only when you intentionally need the coding agent.
TXT

if [[ "${HOME_AI_ASSUME_YES:-false}" != "true" ]]; then
  printf "Start OpenHands coding profile? [y/N] "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

cd "$STACK_DIR"
echo "Starting coding profile..."
docker compose up -d openhands
echo "Coding profile started."
echo "OpenHands: http://localhost:3003"
