#!/usr/bin/env bash
# Smoke-test the read-only Merlin status API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP="$(mktemp -d)"

cleanup() {
  if [[ -n "${API_PID:-}" ]]; then
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

TRACE_LOG="${TMP}/trace.jsonl"
APPROVAL_LOG="${TMP}/approvals.jsonl"
PORT_FILE="${TMP}/port"

HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "debug token sk-test installer" >/dev/null

python3 "${STACK_DIR}/scripts/merlin-status-api.py" \
  --host 127.0.0.1 \
  --port 0 \
  --port-file "$PORT_FILE" \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" >"${TMP}/api.log" 2>&1 &
API_PID="$!"

for _ in {1..30}; do
  [[ -s "$PORT_FILE" ]] && break
  sleep 0.1
done

[[ -s "$PORT_FILE" ]] || fail "status API did not write bound port"
PORT="$(cat "$PORT_FILE")"

HEALTH="$(curl -fsS --max-time 3 "http://127.0.0.1:${PORT}/healthz")"
STATUS="$(curl -fsS --max-time 3 -H "Origin: http://localhost:8888" "http://127.0.0.1:${PORT}/status")"
POST_CODE="$(curl -sS --max-time 3 -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:${PORT}/status")"

[[ "$POST_CODE" == "405" ]] || fail "status API should reject POST"

HEALTH="$HEALTH" STATUS="$STATUS" python3 - <<'PY'
import json
import os

health = json.loads(os.environ["HEALTH"])
status = json.loads(os.environ["STATUS"])

assert health["status"] == "ok"
assert health["execution_allowed"] is False
assert status["status"] == "ok"
assert status["active_profile"] == "core"
assert status["privacy_mode"] == "local_only"
assert status["online_mode"] is False
assert status["cloud_allowed"] is False
assert status["trace_count"] == 1
assert status["approvals"]["pending"] == 1
assert status["approvals"]["total"] == 1
assert status["side_effects"] == "none"
assert status["execution_allowed"] is False
assert "services" in status
assert "dashboard" in status["services"]
PY

if echo "$STATUS" | grep -Eq -- 'sk-test|debug token'; then
  fail "status API must not expose raw goal or secret-like text"
fi

MERLIN_HELP="$(bash "${STACK_DIR}/cli/wizard" merlin status-api --help)"
echo "$MERLIN_HELP" | grep -q "Read-only Merlin status API" \
  || fail "wizard merlin status-api should route to the status API script"

echo "PASS: Merlin status API is read-only and redacted"
