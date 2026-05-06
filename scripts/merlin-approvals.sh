#!/usr/bin/env bash
# Merlin approval audit log viewer and decision recorder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-approvals.sh list [--approval-log <path>] [--status <status>] [--limit <n>]
  scripts/merlin-approvals.sh approve <approval_id> [--approval-log <path>]
  scripts/merlin-approvals.sh deny <approval_id> [--approval-log <path>]

Options:
  --approval-log <path>  Read approvals from a specific JSONL log
  --status <status>      Filter by status, default: required_pending
  --limit <n>            Maximum records to show, default: 20

List is read-only. Approve/deny only append a local audit decision. No command
executes actions, starts services, calls models, writes memory, or uses tools.
Even approved records keep execution_allowed=false until a later execution layer
exists.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] || { usage; exit 1; }
shift || true

STATUS_FILTER="required_pending"
LIMIT="20"
APPROVAL_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --status)
      STATUS_FILTER="${2:-}"
      [[ -n "$STATUS_FILTER" ]] || fail "--status requires a value"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      [[ "$LIMIT" =~ ^[0-9]+$ ]] || fail "--limit requires a positive integer"
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
      if [[ "$COMMAND" =~ ^(approve|deny)$ && -z "$APPROVAL_ID" ]]; then
        APPROVAL_ID="$1"
        shift
      else
        fail "unexpected argument: $1"
      fi
      ;;
  esac
done

case "$COMMAND" in
  list|approve|deny)
    ;;
  *)
    usage
    exit 1
    ;;
esac

if [[ "$COMMAND" =~ ^(approve|deny)$ && -z "$APPROVAL_ID" ]]; then
  fail "${COMMAND} requires an approval id"
fi

if [[ ! -f "$APPROVAL_LOG" && "$COMMAND" == "list" ]]; then
  cat <<EOF
Merlin approvals
approval_log: ${APPROVAL_LOG}
status_filter: ${STATUS_FILTER}
count: 0

No approval requests found.
EOF
  exit 0
fi

if [[ ! -f "$APPROVAL_LOG" ]]; then
  fail "approval log not found: $APPROVAL_LOG"
fi

APPROVAL_LOG="$APPROVAL_LOG" STATUS_FILTER="$STATUS_FILTER" LIMIT="$LIMIT" COMMAND="$COMMAND" APPROVAL_ID="$APPROVAL_ID" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

approval_log = Path(os.environ["APPROVAL_LOG"])
status_filter = os.environ["STATUS_FILTER"]
limit = int(os.environ["LIMIT"])
command = os.environ["COMMAND"]
approval_id = os.environ["APPROVAL_ID"]

records = []
for line_number, line in enumerate(approval_log.read_text(encoding="utf-8").splitlines(), 1):
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        print(f"WARNING: skipped invalid JSONL line {line_number}")
        continue
    records.append(record)

latest_by_id = {}
for record in records:
    request_id = record.get("approval_request_id")
    if request_id:
        latest_by_id[request_id] = record

if command in {"approve", "deny"}:
    target = latest_by_id.get(approval_id)
    if not target:
        raise SystemExit(f"ERROR: approval id not found: {approval_id}")
    if target.get("status") != "required_pending":
        print("Merlin approval decision")
        print(f"approval_log: {approval_log}")
        print(f"approval_request_id: {approval_id}")
        print(f"status: {target.get('status', '?')}")
        print("decision_recorded: false")
        print("execution_allowed: false")
        print("reason: approval is not pending")
        raise SystemExit(0)

    status = "approved" if command == "approve" else "denied"
    decision = {
        "approval_request_id": approval_id,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": status,
        "execution_allowed": False,
        "decision_recorded": True,
        "decision_source": "wizard_cli",
        "decision_record_type": "approval_decision",
        "user_goal_hash": target.get("user_goal_hash", ""),
        "route_id": target.get("route_id", ""),
        "task_type": target.get("task_type", ""),
        "selected_agent": target.get("selected_agent", ""),
        "required_profile": target.get("required_profile", ""),
        "active_profile": target.get("active_profile", ""),
        "hardware_tier": target.get("hardware_tier", ""),
        "privacy_mode": target.get("privacy_mode", "local_only"),
        "online_mode": bool(target.get("online_mode", False)),
        "cloud_allowed": bool(target.get("cloud_allowed", False)),
        "selected_model_alias": target.get("selected_model_alias", ""),
        "provider": target.get("provider", "ollama"),
        "approval_gates": target.get("approval_gates", []),
        "policy_decision": target.get("policy_decision", ""),
        "decision_reason": f"user_{status}_approval_request",
        "redaction_applied": True,
        "side_effects": "none",
        "model_calls": "none",
        "memory_writes": "none",
        "service_starts": "none",
        "tool_execution": "none",
    }
    with approval_log.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(decision, separators=(",", ":")) + "\n")

    print("Merlin approval decision")
    print(f"approval_log: {approval_log}")
    print(f"approval_request_id: {approval_id}")
    print(f"status: {status}")
    print("decision_recorded: true")
    print("execution_allowed: false")
    print("side_effects: none")
    raise SystemExit(0)

display_records = list(latest_by_id.values())
if status_filter != "all":
    display_records = [record for record in display_records if record.get("status") == status_filter]

display_records = display_records[-limit:]
print("Merlin approvals")
print(f"approval_log: {approval_log}")
print(f"status_filter: {status_filter}")
print(f"count: {len(display_records)}")
print("")

if not display_records:
    print("No approval requests found.")
    raise SystemExit(0)

for record in display_records:
    gates = ",".join(record.get("approval_gates", [])) or "none"
    print(f"- id: {record.get('approval_request_id', '?')}")
    print(f"  status: {record.get('status', '?')}")
    print(f"  execution_allowed: {str(record.get('execution_allowed', False)).lower()}")
    print(f"  timestamp: {record.get('timestamp', '?')}")
    print(f"  route_id: {record.get('route_id', '?')}")
    print(f"  task_type: {record.get('task_type', '?')}")
    print(f"  policy_decision: {record.get('policy_decision', '?')}")
    print(f"  gates: {gates}")
    print(f"  user_goal_hash: {record.get('user_goal_hash', '?')}")
PY
