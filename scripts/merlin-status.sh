#!/usr/bin/env bash
# Read-only Merlin control-plane status summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TRACE_LOG="${MERLIN_TRACE_LOG:-${STACK_DIR}/logs/merlin-route-decisions.jsonl}"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-status.sh [--trace-log <path>] [--approval-log <path>]

Options:
  --trace-log <path>     Read route traces from a specific JSONL log
  --approval-log <path>  Read approvals from a specific JSONL log

This command is read-only. It does not approve, deny, execute, start services,
call models, write memory, download models, or use tools.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --trace-log)
      TRACE_LOG="${2:-}"
      [[ -n "$TRACE_LOG" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      fail "unknown option: $1"
      ;;
    *)
      fail "unexpected argument: $1"
      ;;
  esac
done

detect_ram_gb() {
  local bytes
  bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
  if [[ "$bytes" =~ ^[0-9]+$ ]]; then
    awk -v bytes="$bytes" 'BEGIN { printf "%d", (bytes / 1024 / 1024 / 1024) + 0.5 }'
    return
  fi
  if command -v system_profiler >/dev/null 2>&1; then
    local profiler_ram
    profiler_ram="$(system_profiler SPHardwareDataType 2>/dev/null \
      | awk -F': ' '/Memory:/ { gsub(/ GB/, "", $2); print int($2 + 0.5); exit }'
    )"
    if [[ "$profiler_ram" =~ ^[0-9]+$ && "$profiler_ram" -gt 0 ]]; then
      echo "$profiler_ram"
      return
    fi
  fi
  echo "0"
}

hardware_tier_for_ram() {
  local ram_gb="$1"
  if (( ram_gb >= 48 )); then
    echo "high"
  elif (( ram_gb >= 24 )); then
    echo "mid"
  elif (( ram_gb >= 16 )); then
    echo "base"
  elif (( ram_gb > 0 )); then
    echo "low"
  else
    echo "unknown"
  fi
}

http_status() {
  local url="$1"
  local code
  code="$(curl -sS --max-time 2 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || true)"
  if [[ "$code" =~ ^[0-9][0-9][0-9]$ && "$code" != "000" ]]; then
    echo "running"
  else
    echo "down"
  fi
}

jsonl_line_count() {
  local file="$1"
  if [[ -f "$file" ]]; then
    awk 'NF { count++ } END { print count + 0 }' "$file"
  else
    echo "0"
  fi
}

approval_counts() {
  local approval_log="$1"
  if [[ ! -f "$approval_log" ]]; then
    echo "approval_total: 0"
    echo "approval_pending: 0"
    echo "approval_approved: 0"
    echo "approval_denied: 0"
    return
  fi

  APPROVAL_LOG="$approval_log" python3 - <<'PY'
import json
import os
from pathlib import Path

latest = {}
for line in Path(os.environ["APPROVAL_LOG"]).read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        continue
    request_id = record.get("approval_request_id")
    if request_id:
        latest[request_id] = record

counts = {"required_pending": 0, "approved": 0, "denied": 0}
for record in latest.values():
    status = record.get("status")
    if status in counts:
        counts[status] += 1

print(f"approval_total: {len(latest)}")
print(f"approval_pending: {counts['required_pending']}")
print(f"approval_approved: {counts['approved']}")
print(f"approval_denied: {counts['denied']}")
PY
}

RAM_GB="$(detect_ram_gb)"
HARDWARE_TIER="${MERLIN_HARDWARE_TIER:-$(hardware_tier_for_ram "$RAM_GB")}"
ACTIVE_PROFILE="${HOME_AI_PROFILE:-core}"
PRIVACY_MODE="${MERLIN_PRIVACY_MODE:-local_only}"
ONLINE_MODE="${MERLIN_ONLINE_MODE:-false}"
CLOUD_ALLOWED="${MERLIN_CLOUD_ALLOWED:-false}"
TRACE_COUNT="$(jsonl_line_count "$TRACE_LOG")"

cat <<EOF
Merlin status
active_profile: ${ACTIVE_PROFILE}
hardware_tier: ${HARDWARE_TIER}
ram_gb: ${RAM_GB}
privacy_mode: ${PRIVACY_MODE}
online_mode: ${ONLINE_MODE}
cloud_allowed: ${CLOUD_ALLOWED}
trace_log: ${TRACE_LOG}
trace_count: ${TRACE_COUNT}
approval_log: ${APPROVAL_LOG}
EOF

approval_counts "$APPROVAL_LOG"

cat <<EOF
service_dashboard: $(http_status "http://localhost:8888")
service_open_webui: $(http_status "http://localhost:3000")
service_litellm: $(http_status "http://localhost:4000/health/readiness")
service_qdrant: $(http_status "http://localhost:6333/healthz")
service_ollama: $(http_status "http://localhost:11434")
side_effects: none
execution_allowed: false
EOF
