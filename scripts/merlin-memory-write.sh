#!/usr/bin/env bash
# Approved Merlin memory-write boundary.
#
# plan:     read-only preview
# simulate: local redacted JSONL audit only
# write:    approved local Qdrant write using local Ollama embeddings
#
# All modes validate consent boundaries before persistence. The audit log never
# stores raw memory text; the real Qdrant adapter stores raw text only after an
# approved memory_write gate because retrieval memory needs the approved text.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"
MEMORY_LOG="${MERLIN_MEMORY_WRITE_LOG:-${STACK_DIR}/logs/merlin-memory-writes.jsonl}"
MEMORY_COLLECTIONS_FILE="${MERLIN_MEMORY_COLLECTIONS_FILE:-${STACK_DIR}/config/merlin/memory-collections.env}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
EMBEDDING_MODEL="${MERLIN_EMBEDDING_MODEL:-nomic-embed-text}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-memory-write.sh plan --memory-type <type> --text <text>
  scripts/merlin-memory-write.sh simulate --memory-type <type> --text <text> --approval-id <id>
  scripts/merlin-memory-write.sh write --memory-type <type> --text <text> --approval-id <id>

Options:
  --memory-type <type>      fact, preference, document_note, tool_result, system_note
  --text <text>             Proposed memory text
  --approval-id <id>        Required for simulate/write mode
  --approval-log <path>     Approval JSONL log path
  --memory-log <path>       Memory audit JSONL log path
  --qdrant-url <url>        Qdrant URL, default http://localhost:6333
  --ollama-url <url>        Ollama URL, default http://localhost:11434
  --embedding-model <name>  Local Ollama embedding model, default nomic-embed-text

Best-practice boundary:
  - plan writes nothing
  - simulate writes redacted JSONL only
  - write requires an approved memory_write approval id
  - write requires the target canonical Qdrant collection to already exist
  - write uses local Ollama embeddings only
  - audit logs never store raw memory text
  - no cloud, external network, service start, shell adapter, or model download
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

MODE="${1:-}"
case "$MODE" in
  plan|simulate|write)
    shift
    ;;
  --help|-h|"")
    usage
    exit 0
    ;;
  *)
    fail "expected mode: plan, simulate, or write"
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
    --qdrant-url)
      QDRANT_URL="${2:-}"
      [[ -n "$QDRANT_URL" ]] || fail "--qdrant-url requires a URL"
      shift 2
      ;;
    --ollama-url)
      OLLAMA_URL="${2:-}"
      [[ -n "$OLLAMA_URL" ]] || fail "--ollama-url requires a URL"
      shift 2
      ;;
    --embedding-model)
      EMBEDDING_MODEL="${2:-}"
      [[ -n "$EMBEDDING_MODEL" ]] || fail "--embedding-model requires a value"
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
  fact|preference|document_note|tool_result|system_note) ;;
  *) fail "unsupported memory type: $MEMORY_TYPE" ;;
esac

if [[ "$MODE" =~ ^(simulate|write)$ && -z "$APPROVAL_ID" ]]; then
  fail "${MODE} requires --approval-id"
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
MEMORY_PREVIEW="redacted:${MEMORY_HASH#sha256:}"
MEMORY_PREVIEW="${MEMORY_PREVIEW:0:26}"
POINT_ID="$(MEMORY_HASH="$MEMORY_HASH" python3 - <<'PY'
import os
h = os.environ["MEMORY_HASH"].split(":", 1)[-1].ljust(32, "0")[:32]
print(f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}")
PY
)"

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

latest = None
for line in Path(os.environ["APPROVAL_LOG"]).read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        continue
    if record.get("approval_request_id") == os.environ["APPROVAL_ID"]:
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
RESULT_STATUS="planned"
ACTION_ALLOWED=false
ADAPTER="none"
QDRANT_WRITE="none"
EMBEDDING_CALLS="none"
MEMORY_WRITES="none"
RAW_MEMORY_STORED=false
DECISION_REASON="Memory writes require an approved approval id with the memory_write gate."

if [[ "$MODE" =~ ^(simulate|write)$ ]]; then
  RESULT_STATUS="denied"
  POLICY_DECISION="deny"
  DECISION_REASON="Approval '${APPROVAL_ID}' status is '${APPROVAL_STATUS}' and memory_write gate is '${HAS_MEMORY_WRITE_GATE}'."
  if [[ "$APPROVAL_STATUS" == "approved" && "$HAS_MEMORY_WRITE_GATE" == "true" ]]; then
    ACTION_ALLOWED=true
    if [[ "$MODE" == "simulate" ]]; then
      POLICY_DECISION="allow_simulation"
      RESULT_STATUS="simulated"
      ADAPTER="jsonl_simulator"
      MEMORY_WRITES="simulated_jsonl_only"
      DECISION_REASON="Approved memory_write gate allows local simulation only; real Qdrant write remains disabled."
    else
      POLICY_DECISION="allow_local_qdrant_write"
      RESULT_STATUS="ready_to_write"
      ADAPTER="qdrant_local"
      DECISION_REASON="Approved memory_write gate allows local Qdrant write with local Ollama embeddings."
    fi
  fi
fi

collection_exists() {
  curl -fsS --max-time 5 "${QDRANT_URL}/collections/${TARGET_COLLECTION}" >/dev/null 2>&1
}

embedding_json() {
  MEMORY_TEXT="$MEMORY_TEXT" EMBEDDING_MODEL="$EMBEDDING_MODEL" OLLAMA_URL="$OLLAMA_URL" python3 - <<'PY' | \
    curl -fsS --max-time 30 -X POST "${OLLAMA_URL}/api/embeddings" -H "Content-Type: application/json" --data-binary @-
import json
import os
print(json.dumps({"model": os.environ["EMBEDDING_MODEL"], "prompt": os.environ["MEMORY_TEXT"]}))
PY
}

upsert_qdrant_point() {
  local embedding_response="$1"
  MEMORY_TEXT="$MEMORY_TEXT" MEMORY_TYPE="$MEMORY_TYPE" MEMORY_HASH="$MEMORY_HASH" POINT_ID="$POINT_ID" \
    APPROVAL_ID="$APPROVAL_ID" TARGET_COLLECTION="$TARGET_COLLECTION" EMBEDDING_RESPONSE="$embedding_response" python3 - <<'PY' | \
    curl -fsS --max-time 30 -X PUT "${QDRANT_URL}/collections/${TARGET_COLLECTION}/points" -H "Content-Type: application/json" --data-binary @- >/dev/null
import json
import os
from datetime import datetime, timezone

response = json.loads(os.environ["EMBEDDING_RESPONSE"])
vector = response.get("embedding")
if not isinstance(vector, list) or not vector:
    raise SystemExit("embedding response did not include a vector")

payload = {
    "memory_text": os.environ["MEMORY_TEXT"],
    "memory_type": os.environ["MEMORY_TYPE"],
    "memory_text_hash": os.environ["MEMORY_HASH"],
    "approval_id": os.environ["APPROVAL_ID"],
    "source": "merlin_memory_write",
    "privacy_level": "local_only",
    "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "schema_version": 1,
    "target_collection": os.environ["TARGET_COLLECTION"],
}
print(json.dumps({"points": [{"id": os.environ["POINT_ID"], "vector": vector, "payload": payload}]}))
PY
}

write_audit_record() {
  mkdir -p "$(dirname "$MEMORY_LOG")"
  MODE="$MODE" MEMORY_TYPE="$MEMORY_TYPE" MEMORY_HASH="$MEMORY_HASH" MEMORY_PREVIEW="$MEMORY_PREVIEW" \
    APPROVAL_ID="$APPROVAL_ID" APPROVAL_STATUS="$APPROVAL_STATUS" APPROVAL_ROUTE="$APPROVAL_ROUTE" \
    TARGET_COLLECTION="$TARGET_COLLECTION" ADAPTER="$ADAPTER" POLICY_DECISION="$POLICY_DECISION" \
    RESULT_STATUS="$RESULT_STATUS" DECISION_REASON="$DECISION_REASON" MEMORY_LOG="$MEMORY_LOG" \
    RAW_MEMORY_STORED="$RAW_MEMORY_STORED" QDRANT_WRITE="$QDRANT_WRITE" EMBEDDING_CALLS="$EMBEDDING_CALLS" \
    MEMORY_WRITES="$MEMORY_WRITES" POINT_ID="$POINT_ID" EMBEDDING_MODEL="$EMBEDDING_MODEL" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

def as_bool(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}

record = {
    "memory_write_id": f"mem_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}",
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": os.environ["MODE"],
    "memory_type": os.environ["MEMORY_TYPE"],
    "memory_text_hash": os.environ["MEMORY_HASH"],
    "memory_preview": os.environ["MEMORY_PREVIEW"],
    "raw_memory_stored": as_bool(os.environ["RAW_MEMORY_STORED"]),
    "approval_request_id": os.environ["APPROVAL_ID"],
    "approval_status": os.environ["APPROVAL_STATUS"],
    "approval_route_id": os.environ["APPROVAL_ROUTE"],
    "target_collection": os.environ["TARGET_COLLECTION"],
    "point_id": os.environ["POINT_ID"],
    "adapter": os.environ["ADAPTER"],
    "embedding_model": os.environ["EMBEDDING_MODEL"],
    "policy_decision": os.environ["POLICY_DECISION"],
    "result_status": os.environ["RESULT_STATUS"],
    "decision_reason": os.environ["DECISION_REASON"],
    "redaction_applied": True,
    "qdrant_write": os.environ["QDRANT_WRITE"],
    "embedding_calls": os.environ["EMBEDDING_CALLS"],
    "model_calls": "none",
    "service_starts": "none",
    "tool_execution": "none",
    "cloud_calls": "none",
    "external_network": "none",
    "memory_writes": os.environ["MEMORY_WRITES"],
    "execution_allowed": False,
}

with Path(os.environ["MEMORY_LOG"]).open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, separators=(",", ":")) + "\n")
PY
}

if [[ "$MODE" == "simulate" && "$ACTION_ALLOWED" == true ]]; then
  write_audit_record
fi

if [[ "$MODE" == "write" && "$ACTION_ALLOWED" == true ]]; then
  if ! collection_exists; then
    ACTION_ALLOWED=false
    POLICY_DECISION="deny"
    RESULT_STATUS="denied"
    DECISION_REASON="Target Qdrant collection '${TARGET_COLLECTION}' does not exist. Run canonical collection initialization before writes."
  else
    EMBEDDING_RESPONSE="$(embedding_json)" || {
      ACTION_ALLOWED=false
      POLICY_DECISION="deny"
      RESULT_STATUS="denied"
      DECISION_REASON="Local Ollama embedding call failed for '${EMBEDDING_MODEL}'. Pull the model explicitly before enabling memory writes."
    }
    if [[ "$ACTION_ALLOWED" == true ]]; then
      if upsert_qdrant_point "$EMBEDDING_RESPONSE"; then
        RESULT_STATUS="written"
        QDRANT_WRITE="upsert"
        EMBEDDING_CALLS="local_ollama"
        MEMORY_WRITES="qdrant"
        RAW_MEMORY_STORED=true
      else
        ACTION_ALLOWED=false
        POLICY_DECISION="deny"
        RESULT_STATUS="denied"
        DECISION_REASON="Qdrant upsert failed for collection '${TARGET_COLLECTION}'."
      fi
    fi
  fi
  write_audit_record
fi

cat <<EOF
Merlin memory write boundary
mode: ${MODE}
memory_type: ${MEMORY_TYPE}
memory_text_hash: ${MEMORY_HASH}
memory_preview: ${MEMORY_PREVIEW}
raw_memory_stored: ${RAW_MEMORY_STORED}
approval_required: true
approval_request_id: ${APPROVAL_ID:-none}
approval_status: ${APPROVAL_STATUS}
approval_has_memory_write_gate: ${HAS_MEMORY_WRITE_GATE}
approval_route_id: ${APPROVAL_ROUTE:-none}
target_collection: ${TARGET_COLLECTION}
point_id: ${POINT_ID}
adapter: ${ADAPTER}
embedding_model: ${EMBEDDING_MODEL}
policy_decision: ${POLICY_DECISION}
action_allowed: ${ACTION_ALLOWED}
result_status: ${RESULT_STATUS}
memory_log: ${MEMORY_LOG}
qdrant_write: ${QDRANT_WRITE}
embedding_calls: ${EMBEDDING_CALLS}
model_calls: none
memory_writes: ${MEMORY_WRITES}
service_starts: none
tool_execution: none
cloud_calls: none
external_network: none
execution_allowed: false
decision_reason: ${DECISION_REASON}
EOF

if [[ "$MODE" =~ ^(simulate|write)$ && "$ACTION_ALLOWED" != true ]]; then
  exit 2
fi
