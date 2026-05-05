#!/usr/bin/env bash
# Smoke-test that wizard help can load custom memory manifest values.
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

cat > "${TMP}/memory-collections.env" <<'SH'
MERLIN_QDRANT_BACKUP_COLLECTIONS="custom_session custom_documents custom_swarm"
MERLIN_SWARM_MEMORY_COLLECTION="custom_swarm"
MERLIN_DOCUMENT_MEMORY_COLLECTION="custom_documents"
MERLIN_CONVERSATION_MEMORY_COLLECTION="custom_session"
MERLIN_MEMORY_STATS_COLLECTIONS="$MERLIN_QDRANT_BACKUP_COLLECTIONS"
SH

OUTPUT="$(MERLIN_MEMORY_COLLECTIONS_FILE="${TMP}/memory-collections.env" bash "${STACK_DIR}/cli/wizard" help)"

echo "$OUTPUT" | grep -q "configured swarm memory" \
  || fail "wizard help did not load after custom memory manifest"

echo "PASS: wizard memory config loads safely"
