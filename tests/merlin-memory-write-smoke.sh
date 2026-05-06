#!/usr/bin/env bash
# Smoke test the approved Merlin memory-write boundary.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"
MEMORY_LOG="${TMP}/merlin-memory-writes.jsonl"
MEMORY_TEXT="I prefer local-only models for private work"
CURL_LOG="${TMP}/curl-calls.log"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_output() {
  local output="$1"
  local pattern="$2"
  local message="$3"
  echo "$output" | grep -qE "$pattern" || fail "$message"
}

install_fake_curl() {
  mkdir -p "${TMP}/bin"
  cat > "${TMP}/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOG="${MERLIN_FAKE_CURL_LOG:?MERLIN_FAKE_CURL_LOG is required}"
echo "$*" >> "$LOG"

payload_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --data-binary)
      payload_file="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

args="$(tail -n 1 "$LOG")"
case "$args" in
  *"/collections/merlin_user/points"*)
    if [[ "$payload_file" == "@-" ]]; then
      cat > "${MERLIN_FAKE_QDRANT_UPSERT:?}"
    fi
    printf '{"result":{"operation_id":1,"status":"completed"}}\n'
    ;;
  *"/collections/merlin_user"*)
    printf '{"result":{"status":"green"}}\n'
    ;;
  *"/api/embeddings"*)
    if [[ "$payload_file" == "@-" ]]; then
      cat > "${MERLIN_FAKE_EMBEDDING_REQUEST:?}"
    fi
    printf '{"embedding":[0.1,0.2,0.3,0.4]}\n'
    ;;
  *)
    echo "unexpected fake curl call: $args" >&2
    exit 91
    ;;
esac
EOF
  chmod +x "${TMP}/bin/curl"
}

PLAN_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-memory-write.sh" plan \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"

require_output "$PLAN_OUTPUT" '^Merlin memory write boundary$' "memory boundary heading missing"
require_output "$PLAN_OUTPUT" '^mode: plan$' "plan mode missing"
require_output "$PLAN_OUTPUT" '^memory_type: preference$' "memory type missing"
require_output "$PLAN_OUTPUT" '^approval_required: true$' "memory writes should require approval"
require_output "$PLAN_OUTPUT" '^raw_memory_stored: false$' "raw memory should not be stored in plan"
require_output "$PLAN_OUTPUT" '^qdrant_write: none$' "plan must not write Qdrant"
require_output "$PLAN_OUTPUT" '^embedding_calls: none$' "plan must not call embeddings"
require_output "$PLAN_OUTPUT" '^memory_writes: none$' "plan must not write memory"
[[ ! -f "$MEMORY_LOG" ]] || fail "plan mode must not write memory log"

if bash "${STACK_DIR}/scripts/merlin-memory-write.sh" simulate \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-id missing \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG" >"${TMP}/denied.out" 2>&1; then
  fail "simulate without approved approval should fail"
fi
DENIED_OUTPUT="$(cat "${TMP}/denied.out")"
require_output "$DENIED_OUTPUT" '^policy_decision: deny$' "missing approval should deny"
require_output "$DENIED_OUTPUT" '^action_allowed: false$' "missing approval should not simulate"
[[ ! -f "$MEMORY_LOG" ]] || fail "denied simulation must not write memory log"

if bash "${STACK_DIR}/scripts/merlin-memory-write.sh" write \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-id missing \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG" >"${TMP}/denied-write.out" 2>&1; then
  fail "write without approved approval should fail"
fi
DENIED_WRITE_OUTPUT="$(cat "${TMP}/denied-write.out")"
require_output "$DENIED_WRITE_OUTPUT" '^policy_decision: deny$' "missing approval should deny write"
require_output "$DENIED_WRITE_OUTPUT" '^action_allowed: false$' "missing approval should not write"
require_output "$DENIED_WRITE_OUTPUT" '^qdrant_write: none$' "denied write must not touch Qdrant"
[[ ! -f "$CURL_LOG" ]] || fail "denied write must not call curl"

bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --task-type memory \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "remember my local-only model preference" >/dev/null

APPROVAL_ID="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$APPROVAL_ID" ]] || fail "memory dry-run should create approval id"
bash "${STACK_DIR}/scripts/merlin-approvals.sh" approve "$APPROVAL_ID" --approval-log "$APPROVAL_LOG" >/dev/null

SIM_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-memory-write.sh" simulate \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-id "$APPROVAL_ID" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"

require_output "$SIM_OUTPUT" '^mode: simulate$' "simulate mode missing"
require_output "$SIM_OUTPUT" '^approval_status: approved$' "approved status should be detected"
require_output "$SIM_OUTPUT" '^approval_has_memory_write_gate: true$' "memory_write gate should be required"
require_output "$SIM_OUTPUT" '^policy_decision: allow_simulation$' "approved memory write should allow simulation"
require_output "$SIM_OUTPUT" '^action_allowed: true$' "simulation should be allowed"
require_output "$SIM_OUTPUT" '^memory_writes: simulated_jsonl_only$' "simulation should only write JSONL"
require_output "$SIM_OUTPUT" '^qdrant_write: none$' "simulation must not write Qdrant"
[[ -f "$MEMORY_LOG" ]] || fail "approved simulation should write memory audit log"
grep -q '"adapter":"jsonl_simulator"' "$MEMORY_LOG" || fail "memory log should use simulator adapter"
grep -q '"target_collection":"merlin_user"' "$MEMORY_LOG" || fail "preference should target merlin_user"
grep -q '"raw_memory_stored":false' "$MEMORY_LOG" || fail "memory log should not store raw text flag"
grep -q '"qdrant_write":"none"' "$MEMORY_LOG" || fail "memory log must not claim Qdrant write"
if grep -q "$MEMORY_TEXT" "$MEMORY_LOG"; then
  fail "memory log must not store raw memory text"
fi
[[ ! -f "$CURL_LOG" ]] || fail "simulation must not call curl"

install_fake_curl
WRITE_OUTPUT="$(MERLIN_FAKE_CURL_LOG="$CURL_LOG" \
  MERLIN_FAKE_EMBEDDING_REQUEST="${TMP}/embedding-request.json" \
  MERLIN_FAKE_QDRANT_UPSERT="${TMP}/qdrant-upsert.json" \
  PATH="${TMP}/bin:$PATH" \
  bash "${STACK_DIR}/scripts/merlin-memory-write.sh" write \
    --memory-type preference \
    --text "$MEMORY_TEXT" \
    --approval-id "$APPROVAL_ID" \
    --approval-log "$APPROVAL_LOG" \
    --memory-log "$MEMORY_LOG")"

require_output "$WRITE_OUTPUT" '^mode: write$' "write mode missing"
require_output "$WRITE_OUTPUT" '^approval_status: approved$' "approved write status should be detected"
require_output "$WRITE_OUTPUT" '^policy_decision: allow_local_qdrant_write$' "approved write should use local Qdrant policy"
require_output "$WRITE_OUTPUT" '^action_allowed: true$' "approved write should be allowed"
require_output "$WRITE_OUTPUT" '^result_status: written$' "approved write should report written"
require_output "$WRITE_OUTPUT" '^adapter: qdrant_local$' "write should use Qdrant adapter"
require_output "$WRITE_OUTPUT" '^qdrant_write: upsert$' "write should upsert Qdrant"
require_output "$WRITE_OUTPUT" '^embedding_calls: local_ollama$' "write should call local Ollama embeddings"
require_output "$WRITE_OUTPUT" '^memory_writes: qdrant$' "write should report Qdrant memory write"
require_output "$WRITE_OUTPUT" '^raw_memory_stored: true$' "approved write stores raw memory in local Qdrant payload"

grep -q '/collections/merlin_user' "$CURL_LOG" || fail "write should check merlin_user collection"
grep -q '/api/embeddings' "$CURL_LOG" || fail "write should call local embeddings"
grep -q '/collections/merlin_user/points' "$CURL_LOG" || fail "write should upsert local Qdrant point"
grep -q '"model": "nomic-embed-text"' "${TMP}/embedding-request.json" || fail "embedding request should use default local model"
grep -q "$MEMORY_TEXT" "${TMP}/qdrant-upsert.json" || fail "Qdrant payload should include approved raw memory text"
grep -q '"adapter":"qdrant_local"' "$MEMORY_LOG" || fail "memory log should record Qdrant adapter"
grep -q '"qdrant_write":"upsert"' "$MEMORY_LOG" || fail "memory log should record Qdrant upsert"
grep -q '"embedding_calls":"local_ollama"' "$MEMORY_LOG" || fail "memory log should record local embedding call"
grep -q '"raw_memory_stored":true' "$MEMORY_LOG" || fail "memory log should flag raw local Qdrant storage"
if grep -q "$MEMORY_TEXT" "$MEMORY_LOG"; then
  fail "memory log must still not store raw memory text after write"
fi

WIZARD_OUTPUT="$(bash "${STACK_DIR}/cli/wizard" merlin memory plan \
  --memory-type tool_result \
  --text "Tool found local-only result" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"
require_output "$WIZARD_OUTPUT" '^target_collection: merlin_tools$' "tool_result should target merlin_tools"

echo "PASS: Merlin memory-write boundary is approval-gated"
