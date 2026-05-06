#!/usr/bin/env bash
# Static smoke test for the optional search profile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eq "$pattern" "$file" || fail "$label"
}

require_grep 'searxng' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing searxng service mapping"
require_grep 'perplexica-backend' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing Perplexica backend service mapping"
require_grep 'perplexica-frontend' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing Perplexica frontend service mapping"

require_grep 'bash "\$\{SCRIPT_DIR\}/start-core\.sh"' "${STACK_DIR}/scripts/start-search.sh" "start-search does not start core first"
require_grep 'ensure_docker_cli' "${STACK_DIR}/scripts/start-search.sh" "start-search does not verify Docker CLI"
require_grep 'docker info >/dev/null 2>&1' "${STACK_DIR}/scripts/start-search.sh" "start-search does not verify Docker engine"
require_grep 'docker compose up -d searxng perplexica-backend perplexica-frontend' "${STACK_DIR}/scripts/start-search.sh" "start-search starts the wrong services"

require_grep '127\.0\.0\.1.*SEARXNG_PORT' "${STACK_DIR}/docker-compose.yml" "SearXNG is not localhost-bound by default"
require_grep '127\.0\.0\.1.*PERPLEXICA_BACKEND_PORT' "${STACK_DIR}/docker-compose.yml" "Perplexica backend is not localhost-bound by default"
require_grep '127\.0\.0\.1.*PERPLEXICA_FRONTEND_PORT' "${STACK_DIR}/docker-compose.yml" "Perplexica frontend is not localhost-bound by default"
require_grep 'OLLAMA_HOST=.*OLLAMA_BASE_URL' "${STACK_DIR}/docker-compose.yml" "Perplexica backend is not wired to Ollama URL"
require_grep 'SEARXNG_SECRET_KEY=.*REQUIRED_CHANGE_ME' "${STACK_DIR}/docker-compose.yml" "SearXNG secret fallback is not guarded"

require_grep 'OLLAMA = "http://host\.docker\.internal:11434"' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica is not configured for local/native Ollama"
require_grep 'SEARXNG = "http://searxng:8080"' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica is not configured for local SearXNG"
require_grep 'CHAT_MODEL_PROVIDER = "ollama"' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica chat provider is not local Ollama by default"
require_grep 'EMBEDDING_MODEL_PROVIDER = "ollama"' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica embedding provider is not local Ollama by default"
require_grep 'OPENAI = ""' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica OpenAI key should be blank by default"
require_grep 'GROQ = ""' "${STACK_DIR}/configs/perplexica/config.toml" "Perplexica Groq key should be blank by default"

require_grep 'formats:' "${STACK_DIR}/configs/searxng/settings.yml" "SearXNG formats missing"
require_grep 'json' "${STACK_DIR}/configs/searxng/settings.yml" "SearXNG JSON format missing"
require_grep 'enable_metrics: false' "${STACK_DIR}/configs/searxng/settings.yml" "SearXNG metrics should be disabled by default"

echo "PASS: search profile static configuration is safe"
