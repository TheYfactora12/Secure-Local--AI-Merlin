#!/usr/bin/env bash
# =============================================================================
# e2e-test.sh — End-to-end smoke test for merlin-ai
#
# Verifies:
#   1. Docker engine is running
#   2. docker compose responds
#   3. Qdrant API is reachable
#   4. Open WebUI is reachable
#   5. Perplexica is reachable
#   6. SearXNG is reachable
#   7. n8n is reachable
#   8. Ollama API is reachable
#   9. Dashboard is reachable
#
# Usage:
#   bash tests/e2e-test.sh
#
# Exit 0 = all checks passed
# Exit 1 = one or more checks failed
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
N8N_URL="${N8N_URL:-http://localhost:5678}"
OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
PERPLEXICA_URL="${PERPLEXICA_URL:-http://localhost:3002}"
SEARXNG_URL="${SEARXNG_URL:-http://localhost:8080}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:8888}"

PASS=0; FAIL=0
FAILED_CHECKS=()

GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"
CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"

pass() {
  echo -e "${GREEN}[PASS]${RESET} $*"
  ((PASS+=1))
}

fail() {
  echo -e "${RED}[FAIL]${RESET} $*"
  ((FAIL+=1))
  FAILED_CHECKS+=("$*")
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $*"
}

check_http() {
  local url="$1"
  local label="$2"
  local timeout_sec="${3:-10}"
  if curl -fsS --max-time "$timeout_sec" "$url" >/dev/null 2>&1; then
    pass "$label ($url)"
  else
    fail "$label ($url)"
  fi
}

echo -e "${CYAN}${BOLD}"
echo " ┌────────────────────────────────────────┐"
echo " │  merlin-ai end-to-end test suite │"
echo " └────────────────────────────────────────┘"
echo -e "${RESET}"

# ---------------------------------------------------------------------------
# 1. Install directory exists
# ---------------------------------------------------------------------------
if [[ -d "$STACK_DIR" ]]; then
  pass "Install directory exists ($STACK_DIR)"
else
  fail "Install directory missing ($STACK_DIR)"
fi

# ---------------------------------------------------------------------------
# 2. .env file exists
# ---------------------------------------------------------------------------
if [[ -f "${STACK_DIR}/.env" ]]; then
  pass ".env file exists"
else
  warn ".env file missing — using .env.example defaults"
fi

# ---------------------------------------------------------------------------
# 3. Docker binary found
# ---------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  DOCKER_APP_CLI="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${DOCKER_APP_CLI}/docker" ]]; then
    export PATH="${DOCKER_APP_CLI}:$PATH"
  fi
fi

if command -v docker >/dev/null 2>&1; then
  DOCKER_VERSION=$(docker --version 2>&1 | head -1)
  pass "Docker binary found: $DOCKER_VERSION"
else
  fail "Docker binary not found"
fi

# ---------------------------------------------------------------------------
# 4. Docker engine running
# ---------------------------------------------------------------------------
if docker info >/dev/null 2>&1; then
  pass "Docker engine running"
else
  fail "Docker engine not running (start Docker Desktop)"
fi

# ---------------------------------------------------------------------------
# 5. docker compose responds
# ---------------------------------------------------------------------------
if docker compose version >/dev/null 2>&1; then
  COMPOSE_VERSION=$(docker compose version 2>&1 | head -1)
  pass "docker compose available: $COMPOSE_VERSION"
else
  fail "docker compose not available"
fi

# ---------------------------------------------------------------------------
# 6. Stack containers running (check docker compose ps)
# ---------------------------------------------------------------------------
if [[ -f "${STACK_DIR}/docker-compose.yml" ]]; then
  RUNNING=$(cd "$STACK_DIR" && docker compose ps --services --filter status=running 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$RUNNING" -gt 0 ]]; then
    pass "$RUNNING stack service(s) running"
  else
    warn "No stack services running — run: bash ~/merlin-ai/scripts/bootstrap.sh"
  fi
else
  fail "docker-compose.yml not found at $STACK_DIR"
fi

# ---------------------------------------------------------------------------
# 7. Service HTTP checks
# ---------------------------------------------------------------------------
check_http "$QDRANT_URL/collections"  "Qdrant API"
check_http "$DASHBOARD_URL"           "Dashboard"
check_http "$OPENWEBUI_URL"           "Open WebUI"
check_http "$PERPLEXICA_URL"          "Perplexica"
check_http "$SEARXNG_URL"             "SearXNG"
check_http "$OLLAMA_URL"              "Ollama API"

# n8n can expose /healthz or just root
if curl -fsS --max-time 10 "${N8N_URL}/healthz" >/dev/null 2>&1 || \
   curl -fsS --max-time 10 "${N8N_URL}" >/dev/null 2>&1; then
  pass "n8n ($N8N_URL)"
else
  fail "n8n ($N8N_URL)"
fi

# ---------------------------------------------------------------------------
# 8. Qdrant collection check
# ---------------------------------------------------------------------------
QDRANT_COLLECTION="${QDRANT_COLLECTION:-home_ai_memory}"
if curl -fsS --max-time 10 "${QDRANT_URL}/collections/${QDRANT_COLLECTION}" >/dev/null 2>&1; then
  pass "Qdrant collection '$QDRANT_COLLECTION' exists"
else
  warn "Qdrant collection '$QDRANT_COLLECTION' not found — run bootstrap.sh to create it"
fi

# ---------------------------------------------------------------------------
# 9. Ollama model check (warn if no models pulled yet)
# ---------------------------------------------------------------------------
if command -v ollama >/dev/null 2>&1; then
  MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  if [[ "$MODEL_COUNT" -gt 0 ]]; then
    pass "Ollama: $MODEL_COUNT model(s) available"
  else
    warn "Ollama: no models pulled yet — run: ollama pull llama3.2"
  fi
else
  warn "Ollama CLI not found in PATH (may still be running in Docker)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗"
  echo -e " ║  ✅ ALL CHECKS PASSED ($PASS passed, 0 failed)  ║"
  echo -e " ╚════════════════════════════════════════╝${RESET}"
  exit 0
else
  echo -e "${RED}${BOLD}╔════════════════════════════════════════╗"
  echo -e " ║  ❌ $FAIL CHECK(S) FAILED  ($PASS passed)        ║"
  echo -e " ╚════════════════════════════════════════╝${RESET}"
  echo ""
  echo " Failed checks:"
  for check in "${FAILED_CHECKS[@]}"; do
    echo -e "   ${RED}✕${RESET} $check"
  done
  exit 1
fi
