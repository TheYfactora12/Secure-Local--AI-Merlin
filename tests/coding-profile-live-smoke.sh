#!/usr/bin/env bash
# Guarded live smoke test for the OpenHands coding profile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

RUN_LIVE="${HOME_AI_RUN_CODING_LIVE:-false}"
FORCE_LOW_MEMORY="${HOME_AI_FORCE_LOW_MEMORY_CODING:-false}"

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
  curl -fsS --max-time 15 "$url" >/dev/null 2>&1 \
    && pass "$label reachable ($url)" \
    || fail "$label not reachable ($url)"
}

[[ "$RUN_LIVE" == "true" ]] || skip "Set HOME_AI_RUN_CODING_LIVE=true to run live coding profile validation"

RAM_GB="$(ram_gb)"
if [[ "$RAM_GB" -gt 0 && "$RAM_GB" -lt 16 && "$FORCE_LOW_MEMORY" != "true" ]]; then
  skip "Coding live smoke skipped on ${RAM_GB}GB RAM. Set HOME_AI_FORCE_LOW_MEMORY_CODING=true to override."
fi

have_cmd docker || fail "Docker CLI not found"
docker info >/dev/null 2>&1 || fail "Docker engine not running"

HOME_AI_ASSUME_YES=true bash "${STACK_DIR}/scripts/start-coding.sh"

running_services="$(cd "$STACK_DIR" && docker compose ps --services --filter status=running 2>/dev/null || true)"
echo "$running_services" | grep -qx "openhands" \
  && pass "Coding service running: openhands" \
  || fail "Coding service not running: openhands"

check_http "http://localhost:3003" "OpenHands"

echo "Summary: coding profile live smoke passed"
