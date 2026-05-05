#!/usr/bin/env bash
# Home AI Elite — Pull a new Ollama model
# Usage: bash scripts/add-model.sh <model-name>
# Browse: https://ollama.com/library

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if ! command -v docker >/dev/null 2>&1; then
  DOCKER_APP_CLI="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${DOCKER_APP_CLI}/docker" ]]; then
    export PATH="${DOCKER_APP_CLI}:$PATH"
  fi
fi

if [[ -z "${1:-}" ]]; then
  echo "Usage: bash scripts/add-model.sh <model-name>"
  echo ""
  echo "Popular models:"
  echo "  bash scripts/add-model.sh qwen2.5:32b"
  echo "  bash scripts/add-model.sh llama3.3:70b-instruct-q4_K_M"
  echo "  bash scripts/add-model.sh deepseek-r1:14b"
  echo "  bash scripts/add-model.sh mistral:7b"
  echo "  bash scripts/add-model.sh qwen2.5-coder:14b"
  echo ""
  echo "Browse all: https://ollama.com/library"
  exit 1
fi

cd "$STACK_DIR" || exit 1
MODEL="$1"
echo "Pulling: $MODEL"

if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama CLI not found. Install it with: brew install ollama" >&2
    exit 1
  fi
  ollama pull "$MODEL"
else
  docker compose exec -T ollama ollama pull "$MODEL"
fi
echo ""
echo "Done. Model available at http://localhost:11434"
echo ""
if [[ "$(uname -s)" == "Darwin" ]]; then
  ollama list
else
  docker compose exec -T ollama ollama list
fi
