#!/usr/bin/env bash
# Ask Merlin through the local FastAPI task endpoint.
#
# This wrapper is intentionally thin:
# - does not start services
# - does not call cloud providers directly
# - does not write memory
# - does not execute tools
# - does not log raw user input
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_API_URL="${MERLIN_TASK_API_URL:-http://127.0.0.1:8766}"
TIMEOUT_SECONDS="${MERLIN_ASK_TIMEOUT_SECONDS:-95}"
SESSION_ID=""

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-ask.sh "question"
  scripts/merlin-ask.sh --session-id <id> "question"

Options:
  --session-id <id>  Pass an existing Merlin session id
  -h, --help         Show this help

This command calls the local Merlin task endpoint on 127.0.0.1:8766.
It does not start services, write memory, call cloud providers, execute tools,
run shell commands, modify files, trigger n8n, or trigger OpenHands.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)
      SESSION_ID="${2:-}"
      [[ -n "$SESSION_ID" ]] || fail "--session-id requires a value"
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
      break
      ;;
  esac
done

USER_INPUT="${*:-}"
[[ -n "${USER_INPUT//[[:space:]]/}" ]] || { usage; exit 1; }

API_BASE="${TASK_API_URL%/}"
TMP_RESPONSE="$(mktemp)"
TMP_ERROR="$(mktemp)"

cleanup() {
  rm -f "$TMP_RESPONSE" "$TMP_ERROR"
}
trap cleanup EXIT

PAYLOAD="$(
  USER_INPUT="$USER_INPUT" SESSION_ID="$SESSION_ID" python3 - <<'PY'
import json
import os

payload = {"input": os.environ["USER_INPUT"]}
session_id = os.environ.get("SESSION_ID", "")
if session_id:
    payload["session_id"] = session_id
print(json.dumps(payload, separators=(",", ":")))
PY
)"

HTTP_CODE="$(
  curl -sS \
    --max-time "$TIMEOUT_SECONDS" \
    -o "$TMP_RESPONSE" \
    -w "%{http_code}" \
    -X POST "${API_BASE}/task" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    2>"$TMP_ERROR" || true
)"

if [[ -z "$HTTP_CODE" || "$HTTP_CODE" == "000" ]]; then
  cat <<EOF
Merlin
status: degraded
local_only: true
endpoint: ${API_BASE}
response: Merlin task API is not reachable. Start the local Merlin task API on port 8766, then try again.
route_id: unavailable
approval_required: false
memory_written: false
cloud_used: false
tool_execution: none
service_starts: none
EOF
  exit 0
fi

RESPONSE_BODY="$(cat "$TMP_RESPONSE")"

HTTP_CODE="$HTTP_CODE" RESPONSE_BODY="$RESPONSE_BODY" API_BASE="$API_BASE" python3 - <<'PY'
import json
import os
import sys

status_code = os.environ["HTTP_CODE"]
body = os.environ.get("RESPONSE_BODY", "")
api_base = os.environ["API_BASE"]

try:
    data = json.loads(body) if body else {}
except json.JSONDecodeError:
    print("Merlin")
    print("status: degraded")
    print("local_only: true")
    print(f"endpoint: {api_base}")
    print("response: Merlin returned an unreadable response. Try again after the local task API is healthy.")
    print("route_id: unavailable")
    print("approval_required: false")
    print("memory_written: false")
    print("cloud_used: false")
    print("tool_execution: none")
    print("service_starts: none")
    sys.exit(0)

def detail_value(key, default=""):
    detail = data.get("detail", {})
    if isinstance(detail, dict):
        return detail.get(key, default)
    return default

if status_code == "403":
    gates = detail_value("approval_gates", [])
    if not isinstance(gates, list):
        gates = []
    print("Merlin")
    print("status: approval_required")
    print("local_only: true")
    print(f"endpoint: {api_base}")
    print(f"response: {detail_value('message', 'Approval required before Merlin can continue this route.')}")
    print(f"route_id: {detail_value('route_id', 'unknown')}")
    print("approval_required: true")
    print(f"approval_gates: {','.join(gates) if gates else 'none'}")
    print("memory_written: false")
    print("cloud_used: false")
    print("tool_execution: none")
    print("service_starts: none")
    sys.exit(0)

if not status_code.startswith("2"):
    print("Merlin")
    print("status: degraded")
    print("local_only: true")
    print(f"endpoint: {api_base}")
    print(f"response: Merlin task API returned HTTP {status_code}. Try again after the local stack is healthy.")
    print("route_id: unavailable")
    print("approval_required: false")
    print("memory_written: false")
    print("cloud_used: false")
    print("tool_execution: none")
    print("service_starts: none")
    sys.exit(0)

route = data.get("route", {})
if not isinstance(route, dict):
    route = {}
approval_gates = route.get("approval_gates", [])
if not isinstance(approval_gates, list):
    approval_gates = []

print("Merlin")
print(f"status: {'degraded' if data.get('degraded') else 'ok'}")
print("local_only: true")
print(f"endpoint: {api_base}")
print(f"session_id: {data.get('session_id', 'unknown')}")
print(f"route_id: {route.get('route_id', 'unavailable')}")
print(f"staff_mode: {route.get('staff_mode', 'unavailable')}")
print(f"selected_agent: {route.get('selected_agent', 'unavailable')}")
print(f"model_alias: {route.get('selected_model_alias', 'unavailable')}")
print(f"approval_required: {str(bool(route.get('requires_approval', False))).lower()}")
print(f"approval_gates: {','.join(approval_gates) if approval_gates else 'none'}")
print(f"approved: {str(bool(data.get('approved', False))).lower()}")
print(f"memory_written: {str(bool(data.get('memory_written', False))).lower()}")
print("cloud_used: false")
print("tool_execution: none")
print("service_starts: none")
print("")
print("Response:")
print(data.get("response", "Merlin returned no response text."))
PY
