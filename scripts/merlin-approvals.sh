#!/usr/bin/env bash
# Read-only Merlin approval audit log viewer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-approvals.sh list [--approval-log <path>] [--status <status>] [--limit <n>]

Options:
  --approval-log <path>  Read approvals from a specific JSONL log
  --status <status>      Filter by status, default: required_pending
  --limit <n>            Maximum records to show, default: 20

This command is read-only. It does not approve, deny, execute, start services,
call models, write memory, or use tools.
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
      fail "unexpected argument: $1"
      ;;
  esac
done

case "$COMMAND" in
  list)
    ;;
  *)
    usage
    exit 1
    ;;
esac

if [[ ! -f "$APPROVAL_LOG" ]]; then
  cat <<EOF
Merlin approvals
approval_log: ${APPROVAL_LOG}
status_filter: ${STATUS_FILTER}
count: 0

No approval requests found.
EOF
  exit 0
fi

APPROVAL_LOG="$APPROVAL_LOG" STATUS_FILTER="$STATUS_FILTER" LIMIT="$LIMIT" python3 - <<'PY'
import json
import os
from pathlib import Path

approval_log = Path(os.environ["APPROVAL_LOG"])
status_filter = os.environ["STATUS_FILTER"]
limit = int(os.environ["LIMIT"])

records = []
for line_number, line in enumerate(approval_log.read_text(encoding="utf-8").splitlines(), 1):
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        print(f"WARNING: skipped invalid JSONL line {line_number}")
        continue
    if status_filter != "all" and record.get("status") != status_filter:
        continue
    records.append(record)

records = records[-limit:]
print("Merlin approvals")
print(f"approval_log: {approval_log}")
print(f"status_filter: {status_filter}")
print(f"count: {len(records)}")
print("")

if not records:
    print("No approval requests found.")
    raise SystemExit(0)

for record in records:
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
