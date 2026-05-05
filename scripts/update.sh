#!/usr/bin/env bash
# Home AI Elite — Pull latest Docker images and restart
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

ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run this script." >&2
  exit 1
}

cd "$STACK_DIR"
echo "Pulling latest images..."
docker compose pull
echo "Restarting with new images..."
if [[ "$(uname -s)" == "Darwin" ]]; then
  SERVICES=()
  while IFS= read -r service; do
    SERVICES+=("$service")
  done < <(docker compose config --services 2>/dev/null | grep -v '^ollama$')
  docker compose up -d "${SERVICES[@]}"
else
  docker compose --profile docker-ollama --profile linux-security up -d
fi
echo "Update complete. Run: bash scripts/status.sh"
