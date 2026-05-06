#!/usr/bin/env bash
# Smoke test the local-only Merlin memory-read boundary.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

READ_LOG="${TMP}/merlin-memory-reads.jsonl"
QUERY_TEXT="local model preference"
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
  *"/collections/merlin_user/points/search"*)
    if [[ "$payload_file" == "@-" ]]; then
      cat > "${MERLIN_FAKE_QDRANT_SEARCH:?}"
    fi
    cat <<JSON
{"result":[{"id":"640cc4bb-5dc9-3c68-8a44-5d2560a15ab5","score":0.91,"payload":{"memory_text":"${MERLIN_FAKE_MEMORY_TEXT:?}","memory_type":"preference","memory_text_hash":"sha256:640cc4bb5dc93c688a445d2560a15ab584bcb79b23c744759a13a865c6a665ed","source":"merlin_memory_write","privacy_level":"local_only"}}],"status":"ok"}
JSON
    ;;
  *"/collections/merlin_user"*)
    printf '{"result":{"status":"green","config":{"params":{"vectors":{"size":%s,"distance":"Cosine"}}}}}\n' "${MERLIN_FAKE_VECTOR_SIZE:-4}"
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

install_fake_curl
SEARCH_OUTPUT="$(MERLIN_FAKE_CURL_LOG="$CURL_LOG" \
  MERLIN_FAKE_EMBEDDING_REQUEST="${TMP}/embedding-request.json" \
  MERLIN_FAKE_QDRANT_SEARCH="${TMP}/qdrant-search.json" \
  MERLIN_FAKE_MEMORY_TEXT="$MEMORY_TEXT" \
  PATH="${TMP}/bin:$PATH" \
  bash "${STACK_DIR}/scripts/merlin-memory-read.sh" search \
    --query "$QUERY_TEXT" \
    --memory-type preference \
    --limit 3 \
    --memory-read-log "$READ_LOG")"

require_output "$SEARCH_OUTPUT" '^Merlin memory read boundary$' "memory read heading missing"
require_output "$SEARCH_OUTPUT" '^mode: search$' "search mode missing"
require_output "$SEARCH_OUTPUT" '^memory_type: preference$' "memory type missing"
require_output "$SEARCH_OUTPUT" '^policy_decision: allow_local_qdrant_read$' "search should use local read policy"
require_output "$SEARCH_OUTPUT" '^action_allowed: true$' "search should be allowed"
require_output "$SEARCH_OUTPUT" '^result_status: searched$' "search should report searched"
require_output "$SEARCH_OUTPUT" '^result_count: 1$' "search should return one result"
require_output "$SEARCH_OUTPUT" '^qdrant_read: search$' "search should read Qdrant"
require_output "$SEARCH_OUTPUT" '^embedding_calls: local_ollama$' "search should call local embeddings"
require_output "$SEARCH_OUTPUT" '^vector_dimension_guard: passed$' "search should verify vector dimensions"
require_output "$SEARCH_OUTPUT" '^memory_writes: none$' "search must not write memory"
require_output "$SEARCH_OUTPUT" '^cloud_calls: none$' "search must not call cloud"
require_output "$SEARCH_OUTPUT" '^external_network: none$' "search must not call external network"
require_output "$SEARCH_OUTPUT" "memory_text: ${MEMORY_TEXT}" "search should print retrieved memory text"

grep -q '/collections/merlin_user' "$CURL_LOG" || fail "search should check merlin_user collection"
grep -q '/api/embeddings' "$CURL_LOG" || fail "search should call local embeddings"
grep -q '/collections/merlin_user/points/search' "$CURL_LOG" || fail "search should call Qdrant search"
grep -q '"model": "nomic-embed-text"' "${TMP}/embedding-request.json" || fail "embedding request should use default local model"
grep -q "$QUERY_TEXT" "${TMP}/embedding-request.json" || fail "embedding request should include raw query for local embedding"
grep -q '"limit": 3' "${TMP}/qdrant-search.json" || fail "Qdrant search should honor limit"
grep -q '"with_vector": false' "${TMP}/qdrant-search.json" || fail "Qdrant search should not request vectors"

[[ -f "$READ_LOG" ]] || fail "search should write redacted read audit log"
grep -q '"adapter":"qdrant_local"' "$READ_LOG" || fail "read log should record Qdrant adapter"
grep -q '"qdrant_read":"search"' "$READ_LOG" || fail "read log should record Qdrant search"
grep -q '"embedding_calls":"local_ollama"' "$READ_LOG" || fail "read log should record local embedding call"
grep -q '"vector_dimension_guard":"passed"' "$READ_LOG" || fail "read log should record vector dimension guard"
grep -q '"result_count":1' "$READ_LOG" || fail "read log should record result count"
grep -q '"memory_writes":"none"' "$READ_LOG" || fail "read log should record no memory writes"
if grep -q "$QUERY_TEXT" "$READ_LOG"; then
  fail "read log must not store raw query text"
fi
if grep -q "$MEMORY_TEXT" "$READ_LOG"; then
  fail "read log must not store raw memory text"
fi

WIZARD_OUTPUT="$(MERLIN_FAKE_CURL_LOG="$CURL_LOG" \
  MERLIN_FAKE_EMBEDDING_REQUEST="${TMP}/wizard-embedding-request.json" \
  MERLIN_FAKE_QDRANT_SEARCH="${TMP}/wizard-qdrant-search.json" \
  MERLIN_FAKE_MEMORY_TEXT="$MEMORY_TEXT" \
  PATH="${TMP}/bin:$PATH" \
  bash "${STACK_DIR}/cli/wizard" merlin memory search \
    --query "$QUERY_TEXT" \
    --memory-type preference \
    --memory-read-log "$READ_LOG")"
require_output "$WIZARD_OUTPUT" '^Merlin memory read boundary$' "wizard should route memory search"

MISMATCH_LOG="${TMP}/mismatch-curl-calls.log"
if MERLIN_FAKE_CURL_LOG="$MISMATCH_LOG" \
  MERLIN_FAKE_EMBEDDING_REQUEST="${TMP}/mismatch-embedding-request.json" \
  MERLIN_FAKE_QDRANT_SEARCH="${TMP}/mismatch-qdrant-search.json" \
  MERLIN_FAKE_MEMORY_TEXT="$MEMORY_TEXT" \
  MERLIN_FAKE_VECTOR_SIZE=3 \
  PATH="${TMP}/bin:$PATH" \
  bash "${STACK_DIR}/scripts/merlin-memory-read.sh" search \
    --query "$QUERY_TEXT" \
    --memory-type preference \
    --memory-read-log "$READ_LOG" >"${TMP}/mismatch.out" 2>&1; then
  fail "dimension mismatch should fail closed"
fi
MISMATCH_OUTPUT="$(cat "${TMP}/mismatch.out")"
require_output "$MISMATCH_OUTPUT" '^policy_decision: deny$' "dimension mismatch should deny"
require_output "$MISMATCH_OUTPUT" '^vector_dimension_guard: failed$' "dimension mismatch guard should fail"
require_output "$MISMATCH_OUTPUT" 'DimensionMismatchError' "dimension mismatch should name the guard error"
if grep -q '/collections/merlin_user/points/search' "$MISMATCH_LOG"; then
  fail "dimension mismatch must not call Qdrant search"
fi

echo "PASS: Merlin memory-read boundary is local-only and redacted"
