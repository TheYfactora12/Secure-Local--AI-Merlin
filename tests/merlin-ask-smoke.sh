#!/usr/bin/env bash
# Smoke-test wizard merlin ask without live Merlin/LiteLLM/Ollama services.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_output() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  echo "$output" | grep -Eq -- "$pattern" || fail "$label"
}

[[ -x "${STACK_DIR}/scripts/merlin-ask.sh" ]] || fail "merlin-ask.sh must be executable"

HELP_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-ask.sh" --help)"
require_output "$HELP_OUTPUT" 'local Merlin task endpoint' "help should describe local endpoint"
require_output "$HELP_OUTPUT" 'does not start services' "help should state no service start"

cat > "${TMP}/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

OUT=""
WRITE_FORMAT=""
MODE="${MERLIN_ASK_FAKE_MODE:-ok}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      OUT="$2"
      shift 2
      ;;
    -w)
      WRITE_FORMAT="$2"
      shift 2
      ;;
    --max-time|-X|-H|-d)
      shift 2
      ;;
    -sS)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

case "$MODE" in
  ok)
    cat > "$OUT" <<'JSON'
{"response":"Local answer from Merlin.","route":{"route_id":"general","staff_mode":"operator","selected_agent":"planner","selected_model_alias":"qwen7b","requires_approval":false,"approval_gates":[]},"approved":true,"session_id":"session-test","memory_written":false,"degraded":false}
JSON
    printf '%s' "${WRITE_FORMAT//\%\{http_code\}/200}"
    ;;
  approval)
    cat > "$OUT" <<'JSON'
{"detail":{"message":"Approval required before Merlin can continue this route.","route_id":"code","approval_gates":["service_start","file_read","file_write","shell_command","git_operation","openhands_task"]}}
JSON
    printf '%s' "${WRITE_FORMAT//\%\{http_code\}/403}"
    ;;
  down)
    exit 7
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod +x "${TMP}/curl"

OK_OUTPUT="$(PATH="${TMP}:$PATH" MERLIN_ASK_FAKE_MODE=ok bash "${STACK_DIR}/cli/wizard" merlin ask "explain RAG with token sk-test")"
require_output "$OK_OUTPUT" '^Merlin$' "ok output should have heading"
require_output "$OK_OUTPUT" '^status: ok$' "ok output should report ok"
require_output "$OK_OUTPUT" '^local_only: true$' "ok output should report local only"
require_output "$OK_OUTPUT" '^route_id: general$' "ok output should include route"
require_output "$OK_OUTPUT" '^model_alias: qwen7b$' "ok output should include model alias"
require_output "$OK_OUTPUT" '^memory_written: false$' "ok output should not write memory"
require_output "$OK_OUTPUT" '^cloud_used: false$' "ok output should not use cloud"
require_output "$OK_OUTPUT" '^tool_execution: none$' "ok output should not execute tools"
require_output "$OK_OUTPUT" 'Local answer from Merlin' "ok output should show response"
if echo "$OK_OUTPUT" | grep -Eq -- 'sk-test|explain RAG'; then
  fail "ok output should not echo raw user input"
fi

APPROVAL_OUTPUT="$(PATH="${TMP}:$PATH" MERLIN_ASK_FAKE_MODE=approval bash "${STACK_DIR}/cli/wizard" merlin ask "write code in this repo")"
require_output "$APPROVAL_OUTPUT" '^status: approval_required$' "approval output should report approval_required"
require_output "$APPROVAL_OUTPUT" '^route_id: code$' "approval output should include route"
require_output "$APPROVAL_OUTPUT" '^approval_required: true$' "approval output should require approval"
require_output "$APPROVAL_OUTPUT" 'shell_command' "approval output should include shell gate"
require_output "$APPROVAL_OUTPUT" 'openhands_task' "approval output should include OpenHands gate"
require_output "$APPROVAL_OUTPUT" '^memory_written: false$' "approval output should not write memory"
require_output "$APPROVAL_OUTPUT" '^service_starts: none$' "approval output should not start services"

DOWN_OUTPUT="$(PATH="${TMP}:$PATH" MERLIN_ASK_FAKE_MODE=down bash "${STACK_DIR}/cli/wizard" merlin ask "hello")"
require_output "$DOWN_OUTPUT" '^status: degraded$' "down output should degrade"
require_output "$DOWN_OUTPUT" 'Merlin task API is not reachable' "down output should explain startup"
require_output "$DOWN_OUTPUT" '^memory_written: false$' "down output should not write memory"
require_output "$DOWN_OUTPUT" '^cloud_used: false$' "down output should not use cloud"

WIZARD_HELP="$(bash "${STACK_DIR}/cli/wizard" help)"
require_output "$WIZARD_HELP" 'wizard merlin ask "question"' "wizard help should list merlin ask"

echo "PASS: wizard merlin ask is local-only, approval-aware, and degraded-safe"
