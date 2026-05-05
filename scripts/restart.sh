#!/usr/bin/env bash
# Home AI Elite — Restart all services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if ! command -v docker >/dev/null 2>&1; then
  DOCKER_APP_CLI="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${DOCKER_APP_CLI}/docker" ]]; then
    export PATH="${DOCKER_APP_CLI}:$PATH"
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Install Docker Desktop, then re-run this script." >&2
  exit 1
fi

echo "Restarting Home AI Elite services..."
cd "$STACK_DIR"
docker compose restart
echo "Done. Run: bash scripts/status.sh"
