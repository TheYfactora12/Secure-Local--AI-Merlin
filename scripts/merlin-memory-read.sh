#!/usr/bin/env bash
# Local-only Merlin memory retrieval boundary.
#
# search: embeds a local query, searches one canonical Qdrant collection, prints
# approved local memory payloads, and writes only redacted retrieval audit records.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MEMORY_COLLECTIONS_FILE="${MERLIN_MEMORY_COLLECTIONS_FILE:-${STACK_DIR}/configs/merlin/memory-collections.env}"
MEMORY_READ_LOG="${MERLIN_MEMORY_READ_LOG:-${STACK_DIR}/logs/merlin-memory-reads.jsonl}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
EMBEDDING_MODEL="${MERLIN_EMBEDDING_MODEL:-nomic-embed-text}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-memory-read.sh search --query <query> [--memory-type <type>] [--limit <n>]

Options:
  --query <query>          Search query
  --memory-type <type>     fact, preference, document_note, tool_result, system_note
  --collection <name>      Explicit canonical collection override
  --limit <n>              Result limit, default 5, max 10
  --memory-read-log <path> Redacted memory read audit JSONL path
  --qdrant-url <url>       Qdrant URL, default http://localhost:6333
  --ollama-url <url>       Ollama URL, default http://localhost:11434
  --embedding-model <name> Local Ollama embedding model, default nomic-embed-text

Best-practice boundary:
  - search is local-only
  - search requires the target canonical Qdrant collection to already exist
  - search uses local Ollama embeddings only
  - audit logs never store raw query text or raw memory text
  - no cloud, external network, service start, shell adapter, model download, or memory write
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

MODE="${1:-}"
case "$MODE" in
  search)
    shift
    ;;
  --help|-h|"")
    usage
    exit 0
    ;;
  *)
    fail "expected mode: search"
    ;;
esac

QUERY=""
MEMORY_TYPE="preference"
TARGET_COLLECTION=""
LIMIT=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      QUERY="${2:-}"
      [[ -n "$QUERY" ]] || fail "--query requires a value"
      shift 2
      ;;
    --memory-type)
      MEMORY_TYPE="${2:-}"
      [[ -n "$MEMORY_TYPE" ]] || fail "--memory-type requires a value"
      shift 2
      ;;
    --collection)
      TARGET_COLLECTION="${2:-}"
      [[ -n "$TARGET_COLLECTION" ]] || fail "--collection requires a value"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      [[ "$LIMIT" =~ ^[0-9]+$ ]] || fail "--limit requires a positive integer"
      shift 2
      ;;
    --memory-read-log)
      MEMORY_READ_LOG="${2:-}"
      [[ -n "$MEMORY_READ_LOG" ]] || fail "--memory-read-log requires a path"
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

[[ -n "$QUERY" ]] || fail "--query is required"
if [[ "$LIMIT" -lt 1 ]]; then
  fail "--limit must be at least 1"
fi
if [[ "$LIMIT" -gt 10 ]]; then
  LIMIT=10
fi

case "$MEMORY_TYPE" in
  fact|preference|document_note|tool_result|system_note) ;;
  *) fail "unsupported memory type: $MEMORY_TYPE" ;;
esac

if [[ -f "$MEMORY_COLLECTIONS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$MEMORY_COLLECTIONS_FILE"
fi

if [[ -z "$TARGET_COLLECTION" ]]; then
  TARGET_COLLECTION="merlin_user"
  case "$MEMORY_TYPE" in
    document_note) TARGET_COLLECTION="merlin_documents" ;;
    tool_result) TARGET_COLLECTION="merlin_tools" ;;
    system_note) TARGET_COLLECTION="merlin_audit" ;;
  esac
fi

QUERY_HASH="$(
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$QUERY" | shasum -a 256 | awk '{print "sha256:" $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$QUERY" | sha256sum | awk '{print "sha256:" $1}'
  else
    printf 'sha256:unavailable'
  fi
)"
QUERY_PREVIEW="redacted:${QUERY_HASH#sha256:}"
QUERY_PREVIEW="${QUERY_PREVIEW:0:26}"

POLICY_DECISION="allow_local_qdrant_read"
RESULT_STATUS="ready_to_search"
ACTION_ALLOWED=true
ADAPTER="qdrant_local"
EMBEDDING_CALLS="none"
QDRANT_READ="none"
MEMORY_WRITES="none"
CLOUD_CALLS="none"
EXTERNAL_NETWORK="none"
VECTOR_DIMENSION_GUARD="not_checked"
RESULT_COUNT=0
RESULT_HASHES=""
DECISION_REASON="Local-only memory search is allowed for explicit CLI retrieval."

collection_info_json() {
  curl -fsS --max-time 5 "${QDRANT_URL}/collections/${TARGET_COLLECTION}"
}

embedding_json() {
  QUERY="$QUERY" EMBEDDING_MODEL="$EMBEDDING_MODEL" python3 - <<'PY' | \
    curl -fsS --max-time 30 -X POST "${OLLAMA_URL}/api/embeddings" -H "Content-Type: application/json" --data-binary @-
import json
import os
print(json.dumps({"model": os.environ["EMBEDDING_MODEL"], "prompt": os.environ["QUERY"]}))
PY
}

search_qdrant() {
  local embedding_response="$1"
  LIMIT="$LIMIT" EMBEDDING_RESPONSE="$embedding_response" python3 - <<'PY' | \
    curl -fsS --max-time 30 -X POST "${QDRANT_URL}/collections/${TARGET_COLLECTION}/points/search" -H "Content-Type: application/json" --data-binary @-
import json
import os

response = json.loads(os.environ["EMBEDDING_RESPONSE"])
vector = response.get("embedding")
if not isinstance(vector, list) or not vector:
    raise SystemExit("embedding response did not include a vector")

print(json.dumps({
    "vector": vector,
    "limit": int(os.environ["LIMIT"]),
    "with_payload": True,
    "with_vector": False,
}))
PY
}

collection_vector_size() {
  local collection_response="$1"
  COLLECTION_RESPONSE="$collection_response" python3 - <<'PY'
import json
import os

response = json.loads(os.environ["COLLECTION_RESPONSE"])
vectors = (
    response.get("result", {})
    .get("config", {})
    .get("params", {})
    .get("vectors", {})
)
size = None
if isinstance(vectors, dict):
    if isinstance(vectors.get("size"), int):
        size = vectors["size"]
    elif isinstance(vectors.get("default"), dict) and isinstance(vectors["default"].get("size"), int):
        size = vectors["default"]["size"]
print(size or "")
PY
}

embedding_vector_size() {
  local embedding_response="$1"
  EMBEDDING_RESPONSE="$embedding_response" python3 - <<'PY'
import json
import os

response = json.loads(os.environ["EMBEDDING_RESPONSE"])
vector = response.get("embedding")
print(len(vector) if isinstance(vector, list) else "")
PY
}

write_audit_record() {
  mkdir -p "$(dirname "$MEMORY_READ_LOG")"
  MODE="$MODE" MEMORY_TYPE="$MEMORY_TYPE" QUERY_HASH="$QUERY_HASH" QUERY_PREVIEW="$QUERY_PREVIEW" \
    TARGET_COLLECTION="$TARGET_COLLECTION" ADAPTER="$ADAPTER" POLICY_DECISION="$POLICY_DECISION" \
    RESULT_STATUS="$RESULT_STATUS" DECISION_REASON="$DECISION_REASON" MEMORY_READ_LOG="$MEMORY_READ_LOG" \
    QDRANT_READ="$QDRANT_READ" EMBEDDING_CALLS="$EMBEDDING_CALLS" MEMORY_WRITES="$MEMORY_WRITES" \
    EMBEDDING_MODEL="$EMBEDDING_MODEL" RESULT_COUNT="$RESULT_COUNT" RESULT_HASHES="$RESULT_HASHES" \
    CLOUD_CALLS="$CLOUD_CALLS" EXTERNAL_NETWORK="$EXTERNAL_NETWORK" \
    VECTOR_DIMENSION_GUARD="$VECTOR_DIMENSION_GUARD" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

hashes = [item for item in os.environ["RESULT_HASHES"].split(",") if item]
record = {
    "memory_read_id": f"mread_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}",
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": os.environ["MODE"],
    "memory_type": os.environ["MEMORY_TYPE"],
    "query_hash": os.environ["QUERY_HASH"],
    "query_preview": os.environ["QUERY_PREVIEW"],
    "target_collection": os.environ["TARGET_COLLECTION"],
    "adapter": os.environ["ADAPTER"],
    "embedding_model": os.environ["EMBEDDING_MODEL"],
    "policy_decision": os.environ["POLICY_DECISION"],
    "result_status": os.environ["RESULT_STATUS"],
    "decision_reason": os.environ["DECISION_REASON"],
    "result_count": int(os.environ["RESULT_COUNT"]),
    "result_hashes": hashes,
    "redaction_applied": True,
    "qdrant_read": os.environ["QDRANT_READ"],
    "embedding_calls": os.environ["EMBEDDING_CALLS"],
    "vector_dimension_guard": os.environ["VECTOR_DIMENSION_GUARD"],
    "model_calls": "none",
    "service_starts": "none",
    "tool_execution": "none",
    "cloud_calls": os.environ["CLOUD_CALLS"],
    "external_network": os.environ["EXTERNAL_NETWORK"],
    "memory_writes": os.environ["MEMORY_WRITES"],
    "execution_allowed": False,
}

with Path(os.environ["MEMORY_READ_LOG"]).open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, separators=(",", ":")) + "\n")
PY
}

render_results() {
  local search_response="$1"
  SEARCH_RESPONSE="$search_response" python3 - <<'PY'
import hashlib
import json
import os

response = json.loads(os.environ["SEARCH_RESPONSE"])
items = response.get("result", [])
if isinstance(items, dict):
    items = items.get("points", [])

print("results:")
if not items:
    print("  none")
    raise SystemExit(0)

for index, item in enumerate(items, start=1):
    payload = item.get("payload") or {}
    text = str(payload.get("memory_text") or payload.get("text") or "")
    text_hash = payload.get("memory_text_hash")
    if not text_hash and text:
        text_hash = "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()
    print(f"  - rank: {index}")
    print(f"    score: {item.get('score', '')}")
    print(f"    point_id: {item.get('id', '')}")
    print(f"    memory_type: {payload.get('memory_type', '')}")
    print(f"    memory_text_hash: {text_hash or ''}")
    print(f"    memory_text: {text}")
PY
}

result_hashes() {
  local search_response="$1"
  SEARCH_RESPONSE="$search_response" python3 - <<'PY'
import hashlib
import json
import os

response = json.loads(os.environ["SEARCH_RESPONSE"])
items = response.get("result", [])
if isinstance(items, dict):
    items = items.get("points", [])

hashes = []
for item in items:
    payload = item.get("payload") or {}
    text = str(payload.get("memory_text") or payload.get("text") or "")
    text_hash = payload.get("memory_text_hash")
    if not text_hash and text:
        text_hash = "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()
    if text_hash:
        hashes.append(text_hash)
print(",".join(hashes))
PY
}

result_count() {
  local search_response="$1"
  SEARCH_RESPONSE="$search_response" python3 - <<'PY'
import json
import os

response = json.loads(os.environ["SEARCH_RESPONSE"])
items = response.get("result", [])
if isinstance(items, dict):
    items = items.get("points", [])
print(len(items))
PY
}

if ! COLLECTION_INFO="$(collection_info_json)"; then
  ACTION_ALLOWED=false
  POLICY_DECISION="deny"
  RESULT_STATUS="denied"
  DECISION_REASON="Target Qdrant collection '${TARGET_COLLECTION}' does not exist. Run canonical collection initialization before reads."
else
  EMBEDDING_RESPONSE="$(embedding_json)" || {
    ACTION_ALLOWED=false
    POLICY_DECISION="deny"
    RESULT_STATUS="denied"
    DECISION_REASON="Local Ollama embedding call failed for '${EMBEDDING_MODEL}'. Pull the model explicitly before enabling memory reads."
  }
  if [[ "$ACTION_ALLOWED" == true ]]; then
    EMBEDDING_CALLS="local_ollama"
    COLLECTION_VECTOR_SIZE="$(collection_vector_size "$COLLECTION_INFO")"
    EMBEDDING_VECTOR_SIZE="$(embedding_vector_size "$EMBEDDING_RESPONSE")"
    if [[ -z "$COLLECTION_VECTOR_SIZE" || -z "$EMBEDDING_VECTOR_SIZE" ]]; then
      ACTION_ALLOWED=false
      POLICY_DECISION="deny"
      RESULT_STATUS="denied"
      VECTOR_DIMENSION_GUARD="failed"
      DECISION_REASON="DimensionMismatchError: could not verify vector dimensions for collection '${TARGET_COLLECTION}' and embedding model '${EMBEDDING_MODEL}'."
    elif [[ "$COLLECTION_VECTOR_SIZE" != "$EMBEDDING_VECTOR_SIZE" ]]; then
      ACTION_ALLOWED=false
      POLICY_DECISION="deny"
      RESULT_STATUS="denied"
      VECTOR_DIMENSION_GUARD="failed"
      DECISION_REASON="DimensionMismatchError: collection '${TARGET_COLLECTION}' expects ${COLLECTION_VECTOR_SIZE} dimensions but embedding model '${EMBEDDING_MODEL}' returned ${EMBEDDING_VECTOR_SIZE}."
    elif SEARCH_RESPONSE="$(search_qdrant "$EMBEDDING_RESPONSE")"; then
      RESULT_STATUS="searched"
      QDRANT_READ="search"
      VECTOR_DIMENSION_GUARD="passed"
      RESULT_COUNT="$(result_count "$SEARCH_RESPONSE")"
      RESULT_HASHES="$(result_hashes "$SEARCH_RESPONSE")"
    else
      ACTION_ALLOWED=false
      POLICY_DECISION="deny"
      RESULT_STATUS="denied"
      DECISION_REASON="Qdrant search failed for collection '${TARGET_COLLECTION}'."
    fi
  fi
fi

write_audit_record

cat <<EOF
Merlin memory read boundary
mode: ${MODE}
memory_type: ${MEMORY_TYPE}
query_hash: ${QUERY_HASH}
query_preview: ${QUERY_PREVIEW}
target_collection: ${TARGET_COLLECTION}
adapter: ${ADAPTER}
embedding_model: ${EMBEDDING_MODEL}
policy_decision: ${POLICY_DECISION}
action_allowed: ${ACTION_ALLOWED}
result_status: ${RESULT_STATUS}
result_count: ${RESULT_COUNT}
memory_read_log: ${MEMORY_READ_LOG}
qdrant_read: ${QDRANT_READ}
embedding_calls: ${EMBEDDING_CALLS}
vector_dimension_guard: ${VECTOR_DIMENSION_GUARD}
model_calls: none
memory_writes: ${MEMORY_WRITES}
service_starts: none
tool_execution: none
cloud_calls: ${CLOUD_CALLS}
external_network: ${EXTERNAL_NETWORK}
execution_allowed: false
decision_reason: ${DECISION_REASON}
EOF

if [[ "$ACTION_ALLOWED" == true ]]; then
  render_results "$SEARCH_RESPONSE"
else
  exit 2
fi
