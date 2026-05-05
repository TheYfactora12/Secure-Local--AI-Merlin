#!/usr/bin/env bash
# Live smoke test for the laptop-safe core profile.
#
# This test is intentionally local-only:
# - no model pulls
# - no cloud API calls
# - no secret output
# - no optional search/automation/coding services required
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:8888}"
OPENWEBUI_URL="${OPENWEBUI_URL:-http://localhost:3000}"
LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

LITELLM_MODEL="${LITELLM_SMOKE_MODEL:-qwen7b}"
PROMPT_OLLAMA="Reply with exactly: Merlin core online"
PROMPT_LITELLM="Reply with exactly: Merlin gateway online"

PASS=0
FAIL=0
WARN=0
FAILED_CHECKS=()

pass() {
  echo "[PASS] $*"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $*" >&2
  FAIL=$((FAIL + 1))
  FAILED_CHECKS+=("$*")
}

warn() {
  echo "[WARN] $*" >&2
  WARN=$((WARN + 1))
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_http() {
  local url="$1"
  local label="$2"
  local timeout_sec="${3:-10}"
  if curl -fsS --max-time "$timeout_sec" "$url" >/dev/null 2>&1; then
    pass "$label reachable ($url)"
  else
    fail "$label unreachable ($url)"
  fi
}

env_value() {
  local key="$1"
  local file="${STACK_DIR}/.env"
  [[ -f "$file" ]] || return 1
  awk -F= -v key="$key" '
    $1 == key {
      value = substr($0, length(key) + 2)
      gsub(/^["'\'']|["'\'']$/, "", value)
      print value
      exit
    }
  ' "$file"
}

first_ollama_model() {
  ollama list 2>/dev/null | awk 'NR > 1 && $1 != "" { print $1; exit }'
}

echo "Home AI Elite core live smoke test"
echo "Stack: ${STACK_DIR}"
echo ""

if [[ -d "$STACK_DIR" ]]; then
  pass "Stack directory exists"
else
  fail "Stack directory missing: $STACK_DIR"
fi

if have_cmd curl; then
  pass "curl available"
else
  fail "curl not found"
fi

if have_cmd docker; then
  if docker info >/dev/null 2>&1; then
    pass "Docker engine running"
  else
    fail "Docker engine not running"
  fi
else
  fail "Docker CLI not found"
fi

if [[ -f "${STACK_DIR}/docker-compose.yml" ]] && have_cmd docker; then
  running_services="$(cd "$STACK_DIR" && docker compose ps --services --filter status=running 2>/dev/null || true)"
  for service in dashboard open-webui litellm qdrant; do
    if printf '%s\n' "$running_services" | grep -qx "$service"; then
      pass "Core service running: $service"
    else
      fail "Core service not running: $service"
    fi
  done
fi

check_http "$DASHBOARD_URL" "Dashboard"
check_http "$OPENWEBUI_URL" "Open WebUI"
check_http "${LITELLM_URL}/health/readiness" "LiteLLM readiness"
check_http "${QDRANT_URL}/healthz" "Qdrant"
check_http "${OLLAMA_URL}/api/tags" "Ollama API"

if have_cmd ollama; then
  pass "Ollama CLI available"
  OLLAMA_MODEL="${OLLAMA_SMOKE_MODEL:-$(first_ollama_model)}"
  if [[ -n "${OLLAMA_MODEL:-}" ]]; then
    pass "Ollama model available: ${OLLAMA_MODEL}"
    ollama_payload="{\"model\":\"${OLLAMA_MODEL}\",\"prompt\":\"${PROMPT_OLLAMA}\",\"stream\":false}"
    if curl -fsS --max-time 120 "${OLLAMA_URL}/api/generate" -d "$ollama_payload" | grep -q "Merlin core online"; then
      pass "Ollama local generation works"
    else
      fail "Ollama local generation failed for ${OLLAMA_MODEL}"
    fi
  else
    warn "No Ollama models installed; skipping local generation check"
  fi
else
  fail "Ollama CLI not found"
fi

LITELLM_MASTER_KEY="$(env_value LITELLM_MASTER_KEY || true)"
if [[ -n "$LITELLM_MASTER_KEY" ]]; then
  pass "LiteLLM master key available from .env"
  if curl -fsS --max-time 20 "${LITELLM_URL}/v1/models" \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" | grep -q "\"${LITELLM_MODEL}\""; then
    pass "LiteLLM model alias listed: ${LITELLM_MODEL}"
  else
    fail "LiteLLM model alias not listed: ${LITELLM_MODEL}"
  fi

  litellm_payload="{\"model\":\"${LITELLM_MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"${PROMPT_LITELLM}\"}],\"stream\":false,\"max_tokens\":10}"
  if curl -fsS --max-time 120 "${LITELLM_URL}/v1/chat/completions" \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
    -H "Content-Type: application/json" \
    -d "$litellm_payload" | grep -q "Merlin gateway online"; then
    pass "LiteLLM routes to local Ollama"
  else
    fail "LiteLLM chat completion failed for ${LITELLM_MODEL}"
  fi
else
  fail "LITELLM_MASTER_KEY missing from .env"
fi

echo ""
echo "Summary: ${PASS} passed, ${WARN} warnings, ${FAIL} failures"

if [[ "$FAIL" -ne 0 ]]; then
  echo ""
  echo "Failed checks:"
  for check in "${FAILED_CHECKS[@]}"; do
    echo "- $check"
  done
  exit 1
fi

exit 0
