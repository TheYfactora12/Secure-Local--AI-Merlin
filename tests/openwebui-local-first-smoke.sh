#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q 'OFFLINE_MODE=${OPEN_WEBUI_OFFLINE_MODE:-true}' "$COMPOSE" \
  || fail "Open WebUI offline mode is not enabled by default"
grep -q 'HF_HUB_OFFLINE=${OPEN_WEBUI_HF_HUB_OFFLINE:-1}' "$COMPOSE" \
  || fail "Open WebUI does not block Hugging Face downloads by default"
grep -q 'ENABLE_VERSION_UPDATE_CHECK=${OPEN_WEBUI_ENABLE_VERSION_UPDATE_CHECK:-false}' "$COMPOSE" \
  || fail "Open WebUI version update checks are not disabled by default"
grep -q 'RAG_EMBEDDING_MODEL_AUTO_UPDATE=${OPEN_WEBUI_RAG_EMBEDDING_MODEL_AUTO_UPDATE:-false}' "$COMPOSE" \
  || fail "Open WebUI embedding model auto-update is not disabled by default"
grep -q 'RAG_RERANKING_MODEL_AUTO_UPDATE=${OPEN_WEBUI_RAG_RERANKING_MODEL_AUTO_UPDATE:-false}' "$COMPOSE" \
  || fail "Open WebUI reranking model auto-update is not disabled by default"
grep -q 'WHISPER_MODEL_AUTO_UPDATE=${OPEN_WEBUI_WHISPER_MODEL_AUTO_UPDATE:-false}' "$COMPOSE" \
  || fail "Open WebUI Whisper model auto-update is not disabled by default"
grep -q 'CORS_ALLOW_ORIGIN=${OPEN_WEBUI_CORS_ALLOW_ORIGIN:-http://localhost:3000}' "$COMPOSE" \
  || fail "Open WebUI CORS origin is not pinned to localhost by default"

echo "PASS: Open WebUI local-first defaults are enforced"
