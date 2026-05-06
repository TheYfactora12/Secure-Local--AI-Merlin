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
  if [[ -f "${TMP}/manager.pid" ]]; then
    MANAGER_PID="$(tr -cd '0-9' < "${TMP}/manager.pid")"
    if [[ -n "$MANAGER_PID" ]]; then
      kill "$MANAGER_PID" >/dev/null 2>&1 || true
      wait "$MANAGER_PID" >/dev/null 2>&1 || true
    fi
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

grep -q 'nohup python3' "${STACK_DIR}/scripts/merlin-status-api.sh" \
  || fail "status API lifecycle manager should detach the server with nohup"
grep -q 'disown "\$pid"' "${STACK_DIR}/scripts/merlin-status-api.sh" \
  || fail "status API lifecycle manager should disown the server process when supported"

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

MANAGER_HELP="$(bash "${STACK_DIR}/cli/wizard" merlin status-api --help)"
echo "$MANAGER_HELP" | grep -q "scripts/merlin-status-api.sh start" \
  || fail "wizard merlin status-api should route to the lifecycle manager"

MANAGER_PID_FILE="${TMP}/manager.pid"
MANAGER_PORT_FILE="${TMP}/manager.port"
MANAGER_LOG_FILE="${TMP}/manager.log"

MANAGER_START="$(bash "${STACK_DIR}/cli/wizard" merlin status-api start \
  --port 0 \
  --pid-file "$MANAGER_PID_FILE" \
  --port-file "$MANAGER_PORT_FILE" \
  --log-file "$MANAGER_LOG_FILE" \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG")"
echo "$MANAGER_START" | grep -q '^status: started$' \
  || fail "status-api start should start the lifecycle-managed API"
echo "$MANAGER_START" | grep -q '^execution_allowed: false$' \
  || fail "status-api start must not allow execution"

MANAGER_STATUS="$(bash "${STACK_DIR}/cli/wizard" merlin status-api status \
  --pid-file "$MANAGER_PID_FILE" \
  --port-file "$MANAGER_PORT_FILE" \
  --log-file "$MANAGER_LOG_FILE")"
echo "$MANAGER_STATUS" | grep -q '^status: running$' \
  || fail "status-api status should report running"
echo "$MANAGER_STATUS" | grep -q '^execution_allowed: false$' \
  || fail "status-api status must not allow execution"

MANAGER_STOP="$(bash "${STACK_DIR}/cli/wizard" merlin status-api stop \
  --pid-file "$MANAGER_PID_FILE" \
  --port-file "$MANAGER_PORT_FILE" \
  --log-file "$MANAGER_LOG_FILE")"
echo "$MANAGER_STOP" | grep -q '^status: stopped$' \
  || fail "status-api stop should stop the lifecycle-managed API"
echo "$MANAGER_STOP" | grep -q '^execution_allowed: false$' \
  || fail "status-api stop must not allow execution"

echo "PASS: Merlin status API is read-only and redacted"
