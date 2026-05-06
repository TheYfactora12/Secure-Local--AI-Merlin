#!/usr/bin/env bash
# Home AI Elite — start optional automation profile
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

ensure_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi

  local docker_app_cli="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${docker_app_cli}/docker" ]]; then
    export PATH="${docker_app_cli}:$PATH"
    return 0
  fi

  return 1
}

bash "${SCRIPT_DIR}/start-core.sh"

cd "$STACK_DIR"
ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run." >&2
  exit 1
}
docker info >/dev/null 2>&1 || {
  echo "Docker engine not running. Start Docker Desktop, then re-run." >&2
  exit 1
}

echo "Starting automation profile..."
docker compose up -d n8n
echo "Automation profile started."
echo "n8n: http://localhost:5678"
