#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop and retry."
  exit 1
fi

docker compose up -d

source .env
ollama pull "${DEFAULT_LOCAL_MODEL:-qwen3:32b}" || true
ollama pull "${DEFAULT_EMBED_MODEL:-nomic-embed-text}" || true
ollama pull "${DEFAULT_CODER_MODEL:-qwen3-coder}" || true

echo ""
echo "Services:"
echo "  Open WebUI  -> http://localhost:3001"
echo "  Qdrant      -> http://localhost:6333/dashboard"
echo "  n8n         -> http://localhost:5678"
grep -q '^ENABLE_OPENHANDS=yes$' .env 2>/dev/null && echo "  OpenHands   -> http://localhost:3000" || true
