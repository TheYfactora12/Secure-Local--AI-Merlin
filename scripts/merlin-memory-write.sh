#!/usr/bin/env bash
# Approved memory-write simulator.
#
# This is the consent/audit boundary before real Qdrant writes. It validates an
# approved memory_write approval record, writes a redacted local simulation record,
# and deliberately does not write vectors, call embedding models, or contact Qdrant.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"
MEMORY_LOG="${MERLIN_MEMORY_WRITE_LOG:-${STACK_DIR}/logs/merlin-memory-writes.jsonl}"
MEMORY_COLLECTIONS_FILE="${MERLIN_MEMORY_COLLECTIONS_FILE:-${STACK_DIR}/config/merlin/memory-collections.env}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-memory-write.sh plan --memory-type <type> --text <text>
  scripts/merlin-memory-write.sh simulate --memory-type <type> --text <text> --approval-id <id>

Options:
  --memory-type <type>      fact, preference, document_note, tool_result, system_note
  --text <text>             Proposed memory text. Stored as hash/preview only in simulator.
  --approval-id <id>        Required for simulate mode
  --approval-log <path>     Approval JSONL log path
  --memory-log <path>       Simulated memory write JSONL log path

Plan mode is read-only and writes nothing. Simulate mode requires an approved
approval id whose latest approval record includes the memory_write gate. The
simulator writes a redacted local JSONL audit record only. It does not write to
Qdrant, call embeddings, call models, use cloud, start services, or store raw
memory text.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

MODE="${1:-}"
case "$MODE" in
  plan|simulate)
    shift
    ;;
  --help|-h|"")
    usage
    exit 0
    ;;
  *)
    fail "expected mode: plan or simulate"
    ;;
esac

MEMORY_TYPE=""
MEMORY_TEXT=""
APPROVAL_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --memory-type)
      MEMORY_TYPE="${2:-}"
      [[ -n "$MEMORY_TYPE" ]] || fail "--memory-type requires a value"
      shift 2
      ;;
    --text)
      MEMORY_TEXT="${2:-}"
      [[ -n "$MEMORY_TEXT" ]] || fail "--text requires a value"
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
    --memory-log)
      MEMORY_LOG="${2:-}"
      [[ -n "$MEMORY_LOG" ]] || fail "--memory-log requires a path"
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

[[ -n "$MEMORY_TYPE" ]] || fail "--memory-type is required"
[[ -n "$MEMORY_TEXT" ]] || fail "--text is required"

case "$MEMORY_TYPE" in
  fact|preference|document_note|tool_result|system_note)
    ;;
  *)
    fail "unsupported memory type: $MEMORY_TYPE"
    ;;
esac

if [[ "$MODE" == "simulate" && -z "$APPROVAL_ID" ]]; then
  fail "simulate requires --approval-id"
fi

if [[ -f "$MEMORY_COLLECTIONS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$MEMORY_COLLECTIONS_FILE"
fi

TARGET_COLLECTION="merlin_user"
case "$MEMORY_TYPE" in
  document_note) TARGET_COLLECTION="merlin_documents" ;;
  tool_result) TARGET_COLLECTION="merlin_tools" ;;
  system_note) TARGET_COLLECTION="merlin_audit" ;;
esac

MEMORY_HASH="$(
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$MEMORY_TEXT" | shasum -a 256 | awk '{print "sha256:" $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$MEMORY_TEXT" | sha256sum | awk '{print "sha256:" $1}'
  else
    printf 'sha256:unavailable'
  fi
)"

PREVIEW="redacted:${MEMORY_HASH#sha256:}"
PREVIEW="${PREVIEW:0:26}"

approval_json() {
  [[ -n "$APPROVAL_ID" ]] || {
    printf '{"status":"not_provided","has_memory_write_gate":false,"route_id":"","task_type":""}\n'
    return 0
  }
  [[ -f "$APPROVAL_LOG" ]] || {
    printf '{"status":"missing_log","has_memory_write_gate":false,"route_id":"","task_type":""}\n'
    return 0
  }

  APPROVAL_LOG="$APPROVAL_LOG" APPROVAL_ID="$APPROVAL_ID" python3 - <<'PY'
import json
import os
from pathlib import Path

approval_log = Path(os.environ["APPROVAL_LOG"])
approval_id = os.environ["APPROVAL_ID"]
latest = None
for line in approval_log.read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        continue
    if record.get("approval_request_id") == approval_id:
        latest = record

if latest is None:
    print(json.dumps({"status": "not_found", "has_memory_write_gate": False, "route_id": "", "task_type": ""}))
else:
    gates = latest.get("approval_gates", [])
    print(json.dumps({
        "status": latest.get("status", "unknown"),
        "has_memory_write_gate": "memory_write" in gates,
        "route_id": latest.get("route_id", ""),
        "task_type": latest.get("task_type", ""),
        "policy_decision": latest.get("policy_decision", ""),
    }))
PY
}

APPROVAL_JSON="$(approval_json)"
APPROVAL_STATUS="$(printf '%s' "$APPROVAL_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status","unknown"))')"
HAS_MEMORY_WRITE_GATE="$(printf '%s' "$APPROVAL_JSON" | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("has_memory_write_gate", False)).lower())')"
APPROVAL_ROUTE="$(printf '%s' "$APPROVAL_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("route_id",""))')"

POLICY_DECISION="require_approval"
SIMULATION_ALLOWED=false
RESULT_STATUS="planned"
DECISION_REASON="Memory writes require an approved approval id with the memory_write gate."

if [[ "$MODE" == "simulate" ]]; then
  RESULT_STATUS="denied"
  if [[ "$APPROVAL_STATUS" == "approved" && "$HAS_MEMORY_WRITE_GATE" == "true" ]]; then
    POLICY_DECISION="allow_simulation"
    SIMULATION_ALLOWED=true
    RESULT_STATUS="simulated"
    DECISION_REASON="Approved memory_write gate allows local simulation only; real Qdrant write remains disabled."
  else
    POLICY_DECISION="deny"
    DECISION_REASON="Approval '${APPROVAL_ID}' status is '${APPROVAL_STATUS}' and memory_write gate is '${HAS_MEMORY_WRITE_GATE}'."
  fi
fi

write_memory_record() {
  mkdir -p "$(dirname "$MEMORY_LOG")"
  MODE="$MODE" MEMORY_TYPE="$MEMORY_TYPE" MEMORY_HASH="$MEMORY_HASH" PREVIEW="$PREVIEW" \
    APPROVAL_ID="$APPROVAL_ID" APPROVAL_STATUS="$APPROVAL_STATUS" APPROVAL_ROUTE="$APPROVAL_ROUTE" \
    TARGET_COLLECTION="$TARGET_COLLECTION" POLICY_DECISION="$POLICY_DECISION" RESULT_STATUS="$RESULT_STATUS" \
    DECISION_REASON="$DECISION_REASON" MEMORY_LOG="$MEMORY_LOG" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

record = {
    "memory_write_id": f"memsim_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}",
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": os.environ["MODE"],
    "memory_type": os.environ["MEMORY_TYPE"],
    "memory_text_hash": os.environ["MEMORY_HASH"],
    "memory_preview": os.environ["PREVIEW"],
    "raw_memory_stored": False,
    "approval_request_id": os.environ["APPROVAL_ID"],
    "approval_status": os.environ["APPROVAL_STATUS"],
    "approval_route_id": os.environ["APPROVAL_ROUTE"],
    "target_collection": os.environ["TARGET_COLLECTION"],
    "adapter": "jsonl_simulator",
    "policy_decision": os.environ["POLICY_DECISION"],
    "result_status": os.environ["RESULT_STATUS"],
    "decision_reason": os.environ["DECISION_REASON"],
    "redaction_applied": True,
    "qdrant_write": "none",
    "embedding_calls": "none",
    "model_calls": "none",
    "service_starts": "none",
    "tool_execution": "none",
    "cloud_calls": "none",
    "external_network": "none",
    "memory_writes": "simulated_jsonl_only",
    "execution_allowed": False,
}

with Path(os.environ["MEMORY_LOG"]).open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, separators=(",", ":")) + "\n")
PY
}

if [[ "$MODE" == "simulate" && "$SIMULATION_ALLOWED" == true ]]; then
  write_memory_record
fi

cat <<EOF
Merlin memory write boundary
mode: ${MODE}
memory_type: ${MEMORY_TYPE}
memory_text_hash: ${MEMORY_HASH}
memory_preview: ${PREVIEW}
raw_memory_stored: false
approval_required: true
approval_request_id: ${APPROVAL_ID:-none}
approval_status: ${APPROVAL_STATUS}
approval_has_memory_write_gate: ${HAS_MEMORY_WRITE_GATE}
approval_route_id: ${APPROVAL_ROUTE:-none}
target_collection: ${TARGET_COLLECTION}
adapter: jsonl_simulator
policy_decision: ${POLICY_DECISION}
simulation_allowed: ${SIMULATION_ALLOWED}
result_status: ${RESULT_STATUS}
memory_log: ${MEMORY_LOG}
qdrant_write: none
embedding_calls: none
model_calls: none
memory_writes: $([[ "$SIMULATION_ALLOWED" == true ]] && echo "simulated_jsonl_only" || echo "none")
service_starts: none
tool_execution: none
cloud_calls: none
external_network: none
execution_allowed: false
decision_reason: ${DECISION_REASON}
EOF

if [[ "$MODE" == "simulate" && "$SIMULATION_ALLOWED" != true ]]; then
  exit 2
fi
