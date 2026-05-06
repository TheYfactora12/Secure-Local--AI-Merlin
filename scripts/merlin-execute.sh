#!/usr/bin/env bash
# Policy-gated Merlin execution boundary.
#
# v0 intentionally supports only one harmless read-only action: merlin_status.
# Risky actions are refused even when an approval record exists. This gives
# Merlin a testable execute path without enabling shell, file, network, service,
# memory, model-download, or OpenHands behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"
EXECUTION_LOG="${MERLIN_EXECUTION_LOG:-${STACK_DIR}/logs/merlin-executions.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-execute.sh plan --action <action> [options]
  scripts/merlin-execute.sh execute --action <action> [options]

Options:
  --action <action>          Action to evaluate or execute
  --approval-id <id>         Optional approval id to validate
  --approval-log <path>      Approval JSONL log path
  --execution-log <path>     Execution audit JSONL log path

Supported v0 action:
  merlin_status              Run read-only Merlin status summary

Refused v0 actions:
  shell_command, file_read, file_write, file_delete, git_operation,
  external_network, cloud_model_call, api_key_use, memory_write,
  service_start, service_stop, model_download, openhands_task

Plan mode is read-only and writes nothing. Execute mode writes a redacted local
execution audit record. v0 execute does not call models, write memory, download
models, start services, use API keys, access external network, run shell tools,
or operate OpenHands.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

MODE="${1:-}"
case "$MODE" in
  plan|execute)
    shift
    ;;
  --help|-h|"")
    usage
    exit 0
    ;;
  *)
    fail "expected mode: plan or execute"
    ;;
esac

ACTION=""
APPROVAL_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)
      ACTION="${2:-}"
      [[ -n "$ACTION" ]] || fail "--action requires a value"
      shift 2
      ;;
    --approval-id)
      APPROVAL_ID="${2:-}"
      [[ -n "$APPROVAL_ID" ]] || fail "--approval-id requires a value"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --execution-log)
      EXECUTION_LOG="${2:-}"
      [[ -n "$EXECUTION_LOG" ]] || fail "--execution-log requires a path"
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

[[ -n "$ACTION" ]] || fail "--action is required"

ACTION_RISK="critical"
APPROVAL_REQUIRED=true
APPROVAL_GATES="$ACTION"
POLICY_DECISION="deny"
DECISION_REASON="Action is not supported by the v0 Merlin execution boundary."
EXECUTION_ALLOWED=false
SIDE_EFFECTS="none"
EXIT_CODE=2

case "$ACTION" in
  merlin_status)
    ACTION_RISK="low"
    APPROVAL_REQUIRED=false
    APPROVAL_GATES="none"
    POLICY_DECISION="allow"
    DECISION_REASON="Read-only Merlin status is the only v0 executable action."
    EXECUTION_ALLOWED=true
    SIDE_EFFECTS="audit_log_only"
    EXIT_CODE=0
    ;;
  shell_command|file_read|file_write|file_delete|git_operation|external_network|cloud_model_call|api_key_use|memory_write|service_start|service_stop|model_download|openhands_task)
    DECISION_REASON="Risky action '${ACTION}' requires a future scoped adapter and remains blocked in v0."
    ;;
  *)
    APPROVAL_GATES="unknown_action"
    DECISION_REASON="Unknown action '${ACTION}' is not in the Merlin v0 allowlist."
    ;;
esac

latest_approval_status() {
  [[ -n "$APPROVAL_ID" ]] || { echo "not_provided"; return 0; }
  [[ -f "$APPROVAL_LOG" ]] || { echo "missing_log"; return 0; }

  APPROVAL_LOG="$APPROVAL_LOG" APPROVAL_ID="$APPROVAL_ID" python3 - <<'PY'
import json
import os
from pathlib import Path

approval_log = Path(os.environ["APPROVAL_LOG"])
approval_id = os.environ["APPROVAL_ID"]
status = "not_found"

for line in approval_log.read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        continue
    if record.get("approval_request_id") == approval_id:
        status = record.get("status", "unknown")

print(status)
PY
}

APPROVAL_STATUS="$(latest_approval_status)"

if [[ -n "$APPROVAL_ID" && "$APPROVAL_STATUS" != "approved" ]]; then
  POLICY_DECISION="deny"
  DECISION_REASON="Approval id '${APPROVAL_ID}' is not approved; latest status is '${APPROVAL_STATUS}'."
  EXECUTION_ALLOWED=false
  SIDE_EFFECTS="none"
  EXIT_CODE=2
fi

append_execution_record() {
  local result_status="$1"
  mkdir -p "$(dirname "$EXECUTION_LOG")"
  MODE="$MODE" ACTION="$ACTION" ACTION_RISK="$ACTION_RISK" APPROVAL_REQUIRED="$APPROVAL_REQUIRED" \
    APPROVAL_ID="$APPROVAL_ID" APPROVAL_STATUS="$APPROVAL_STATUS" APPROVAL_GATES="$APPROVAL_GATES" \
    POLICY_DECISION="$POLICY_DECISION" DECISION_REASON="$DECISION_REASON" \
    EXECUTION_ALLOWED="$EXECUTION_ALLOWED" SIDE_EFFECTS="$SIDE_EFFECTS" \
    RESULT_STATUS="$result_status" EXECUTION_LOG="$EXECUTION_LOG" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

def as_bool(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}

record = {
    "execution_id": f"exec_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}",
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": os.environ["MODE"],
    "action": os.environ["ACTION"],
    "action_risk": os.environ["ACTION_RISK"],
    "approval_required": as_bool(os.environ["APPROVAL_REQUIRED"]),
    "approval_request_id": os.environ["APPROVAL_ID"] or "none",
    "approval_status": os.environ["APPROVAL_STATUS"],
    "approval_gates": [] if os.environ["APPROVAL_GATES"] == "none" else os.environ["APPROVAL_GATES"].split(","),
    "policy_decision": os.environ["POLICY_DECISION"],
    "decision_reason": os.environ["DECISION_REASON"],
    "execution_allowed": as_bool(os.environ["EXECUTION_ALLOWED"]),
    "result_status": os.environ["RESULT_STATUS"],
    "redaction_applied": True,
    "side_effects": os.environ["SIDE_EFFECTS"],
    "model_calls": "none",
    "memory_writes": "none",
    "service_starts": "none",
    "tool_execution": "none",
    "cloud_calls": "none",
    "external_network": "none",
    "secrets_exposed": False,
}

with Path(os.environ["EXECUTION_LOG"]).open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, separators=(",", ":")) + "\n")
PY
}

print_decision() {
  local execution_performed="$1"
  local result_status="$2"
  cat <<EOF
Merlin execution boundary
mode: ${MODE}
action: ${ACTION}
action_risk: ${ACTION_RISK}
approval_required: ${APPROVAL_REQUIRED}
approval_request_id: ${APPROVAL_ID:-none}
approval_status: ${APPROVAL_STATUS}
approval_gates: ${APPROVAL_GATES}
policy_decision: ${POLICY_DECISION}
execution_allowed: ${EXECUTION_ALLOWED}
execution_performed: ${execution_performed}
result_status: ${result_status}
side_effects: ${SIDE_EFFECTS}
model_calls: none
memory_writes: none
service_starts: none
tool_execution: none
cloud_calls: none
external_network: none
execution_log: ${EXECUTION_LOG}
decision_reason: ${DECISION_REASON}
EOF
}

if [[ "$MODE" == "plan" ]]; then
  print_decision "false" "planned"
  exit "$EXIT_CODE"
fi

if [[ "$EXECUTION_ALLOWED" != "true" ]]; then
  append_execution_record "denied"
  print_decision "false" "denied"
  exit "$EXIT_CODE"
fi

append_execution_record "completed"
print_decision "true" "completed"
echo ""
bash "${STACK_DIR}/scripts/merlin-status.sh" --approval-log "$APPROVAL_LOG"
