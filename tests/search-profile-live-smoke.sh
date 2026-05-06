#!/usr/bin/env bash
# Guarded live smoke test for Perplexica + SearXNG.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

RUN_LIVE="${HOME_AI_RUN_SEARCH_LIVE:-false}"
FORCE_LOW_MEMORY="${HOME_AI_FORCE_LOW_MEMORY_SEARCH:-false}"

pass() { echo "[PASS] $*"; }
skip() { echo "[SKIP] $*"; exit 0; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ram_gb() {
  if [[ "$(uname -s)" == "Darwin" ]] && have_cmd sysctl; then
    sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1 / 1024 / 1024 / 1024}'
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "%.0f", $2 / 1024 / 1024}' /proc/meminfo
  else
    echo 0
  fi
}

check_http() {
  local url="$1"
  local label="$2"
  curl -fsS --max-time 10 "$url" >/dev/null 2>&1 \
    && pass "$label reachable ($url)" \
    || fail "$label not reachable ($url)"
}

[[ "$RUN_LIVE" == "true" ]] || skip "Set HOME_AI_RUN_SEARCH_LIVE=true to run live search profile validation"

RAM_GB="$(ram_gb)"
if [[ "$RAM_GB" -gt 0 && "$RAM_GB" -lt 16 && "$FORCE_LOW_MEMORY" != "true" ]]; then
  skip "Search live smoke skipped on ${RAM_GB}GB RAM. Set HOME_AI_FORCE_LOW_MEMORY_SEARCH=true to override."
fi

have_cmd docker || fail "Docker CLI not found"
docker info >/dev/null 2>&1 || fail "Docker engine not running"

bash "${STACK_DIR}/scripts/start-search.sh"

running_services="$(cd "$STACK_DIR" && docker compose ps --services --filter status=running 2>/dev/null || true)"
for service in searxng perplexica-backend perplexica-frontend; do
  echo "$running_services" | grep -qx "$service" \
    && pass "Search service running: $service" \
    || fail "Search service not running: $service"
done

check_http "http://localhost:8080" "SearXNG"
check_http "http://localhost:3002" "Perplexica frontend"
check_http "http://localhost:3001" "Perplexica backend"

echo "Summary: search profile live smoke passed"
