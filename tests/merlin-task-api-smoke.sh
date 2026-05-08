#!/usr/bin/env bash
# Static smoke-test for the Merlin task API lifecycle manager and launchd wiring.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TASK_MANAGER="${STACK_DIR}/scripts/merlin-task-api.sh"
TASK_PLIST="${STACK_DIR}/launchd/com.homeai.merlin-task-api.plist"
WIZARD_FILE="${STACK_DIR}/cli/wizard"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$TASK_MANAGER" ]] || fail "missing scripts/merlin-task-api.sh"
[[ -x "$TASK_MANAGER" ]] || fail "scripts/merlin-task-api.sh must be executable"
[[ -f "$TASK_PLIST" ]] || fail "missing launchd task API plist"

bash -n "$TASK_MANAGER" || fail "task API manager syntax failed"
bash "$TASK_MANAGER" --help | grep -q 'scripts/merlin-task-api.sh start' \
  || fail "task API manager help missing start command"
bash "$TASK_MANAGER" --help | grep -q 'scripts/merlin-task-api.sh restart' \
  || fail "task API manager help missing restart command"

grep -q 'MERLIN_TASK_API_PORT:-8766' "$TASK_MANAGER" \
  || fail "task API manager must default to port 8766"
grep -q '/status/routes' "$TASK_MANAGER" \
  || fail "task API manager must health-check /status/routes"
grep -q 'uvicorn merlin.task_endpoint:app' "$TASK_MANAGER" \
  || fail "task API manager must run merlin.task_endpoint through uvicorn"
grep -q 'PYTHONPATH="$STACK_DIR"' "$TASK_MANAGER" \
  || fail "task API manager must set repo PYTHONPATH"
grep -q 'start|stop|restart|status|run' "$TASK_MANAGER" \
  || fail "task API manager parser must accept restart command"
grep -q 'restart_api()' "$TASK_MANAGER" \
  || fail "task API manager missing restart function"
grep -q 'port_listener_pids()' "$TASK_MANAGER" \
  || fail "task API manager must detect stale port listeners"
grep -q 'stop_port_listeners()' "$TASK_MANAGER" \
  || fail "task API manager must stop stale port listeners during restart"
grep -A12 'restart_api()' "$TASK_MANAGER" | grep -q 'stop_api' \
  || fail "task API restart must stop before starting"
grep -A12 'restart_api()' "$TASK_MANAGER" | grep -q 'stop_port_listeners' \
  || fail "task API restart must handle listeners outside the PID file"
grep -A12 'restart_api()' "$TASK_MANAGER" | grep -q 'start_api' \
  || fail "task API restart must start after stopping"

grep -q 'scripts/merlin-task-api.sh run' "$TASK_PLIST" \
  || fail "launchd plist must run task API manager in foreground"
grep -q '<string>com.homeai.merlin-task-api</string>' "$TASK_PLIST" \
  || fail "launchd plist has wrong label"
grep -q '<key>KeepAlive</key>' "$TASK_PLIST" \
  || fail "launchd task API must be restartable"

grep -q 'task-api)' "$WIZARD_FILE" \
  || fail "wizard merlin task-api command missing"
grep -q 'scripts/merlin-task-api.sh' "$WIZARD_FILE" \
  || fail "wizard merlin task-api must route to lifecycle manager"

if grep -q 'scripts/merlin-status-api.py' "$TASK_MANAGER"; then
  fail "task API manager must not invoke read-only status API implementation"
fi

echo "PASS: Merlin task API lifecycle wiring is separate and localhost-only"
