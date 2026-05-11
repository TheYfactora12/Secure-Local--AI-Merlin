#!/usr/bin/env bash
# Merlin AI — start optional coding profile
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

ram_gb() {
  if [[ "$(uname -s)" == "Darwin" ]] && command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1 / 1024 / 1024 / 1024}'
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "%.0f", $2 / 1024 / 1024}' /proc/meminfo
  else
    echo 0
  fi
}

bash "${SCRIPT_DIR}/start-core.sh"

cat <<'TXT'
OpenHands uses Docker socket access and can control containers on this machine.
Start it only when you intentionally need the coding agent.
TXT

RAM_GB="$(ram_gb)"
if [[ "$RAM_GB" -gt 0 && "$RAM_GB" -lt 16 ]]; then
  echo "Low-memory warning: ${RAM_GB}GB RAM detected. OpenHands is not recommended on this tier."
fi

if [[ "${HOME_AI_ASSUME_YES:-false}" != "true" ]]; then
  printf "Start OpenHands coding profile? [y/N] "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

cd "$STACK_DIR"
ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run." >&2
  exit 1
}
docker info >/dev/null 2>&1 || {
  echo "Docker engine not running. Start Docker Desktop, then re-run." >&2
  exit 1
}

echo "Starting coding profile..."
docker compose up -d openhands
echo "Coding profile started."
echo "OpenHands: http://localhost:3003"
