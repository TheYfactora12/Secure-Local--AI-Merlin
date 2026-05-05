#!/usr/bin/env bash
# Home AI Elite — start laptop-safe core profile
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

start_native_ollama() {
  if curl -fsS --max-time 2 http://localhost:11434 >/dev/null 2>&1; then
    echo "Native Ollama already running"
    return 0
  fi

  if command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q '^ollama'; then
    brew services start ollama >/dev/null 2>&1 || true
    sleep 2
  elif command -v ollama >/dev/null 2>&1; then
    OLLAMA_HOST=127.0.0.1:11434 ollama serve >/tmp/home-ai-ollama.log 2>&1 &
    sleep 2
  else
    echo "Ollama CLI not found. Install it with: brew install ollama" >&2
    return 1
  fi
}

cd "$STACK_DIR"

if [[ ! -f .env ]]; then
  echo ".env missing. Run bash install.sh first so secrets are generated." >&2
  exit 1
fi

ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run." >&2
  exit 1
}

docker info >/dev/null 2>&1 || {
  echo "Docker engine not running. Start Docker Desktop, then re-run." >&2
  exit 1
}

echo "Starting Home AI Elite core profile..."

if [[ "$(uname -s)" == "Darwin" ]]; then
  start_native_ollama
  docker compose up -d --no-deps dashboard qdrant litellm open-webui
else
  docker compose --profile docker-ollama up -d --no-deps ollama dashboard qdrant litellm open-webui
fi

echo "Core profile started."
echo "Run: bash scripts/status.sh"
