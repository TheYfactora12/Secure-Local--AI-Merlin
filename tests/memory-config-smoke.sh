#!/usr/bin/env bash
# Smoke-test Merlin memory config and restore dry-run without requiring Docker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${STACK_DIR}/configs/merlin/memory-collections.env"
RESTORE="${STACK_DIR}/backup/restore.sh"
MEMORY_YAML="${STACK_DIR}/configs/merlin/memory.yaml"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_collection() {
  local wanted="$1"
  local spec name
  for spec in "${MERLIN_QDRANT_LEGACY_COLLECTIONS[@]}"; do
    IFS=':' read -r name _ <<< "$spec"
    [[ "$name" == "$wanted" ]] && return 0
  done
  fail "Missing legacy collection in manifest: ${wanted}"
}

require_backup_collection() {
  local wanted="$1"
  case " ${MERLIN_QDRANT_BACKUP_COLLECTIONS} " in
    *" ${wanted} "*) ;;
    *) fail "Missing collection in backup manifest: ${wanted}" ;;
  esac
}

[[ -f "$MANIFEST" ]] || fail "Missing manifest: ${MANIFEST}"
[[ -f "$RESTORE" ]] || fail "Missing restore script: ${RESTORE}"
[[ -f "$MEMORY_YAML" ]] || fail "Missing memory schema: ${MEMORY_YAML}"

# shellcheck disable=SC1090
source "$MANIFEST"

require_collection "home_ai_memory"
require_collection "swarm_memory"
require_collection "documents"
require_collection "openwebui"
require_collection "perplexica"
require_collection "n8n_memory"
require_collection "conversations"
require_backup_collection "merlin_user"
require_backup_collection "merlin_documents"
require_backup_collection "merlin_tools"
require_backup_collection "merlin_audit"

awk '/^  merlin_audit:/,/^legacy:/' "$MEMORY_YAML" | grep -q -- '- route_id' \
  || fail "merlin_audit missing route_id payload index"
awk '/^  merlin_audit:/,/^legacy:/' "$MEMORY_YAML" | grep -q -- '- outcome_status' \
  || fail "merlin_audit missing outcome_status payload index"

BACKUP_ROOT="${TMP}/wizard_backup_test"
mkdir -p "$BACKUP_ROOT"
cat > "${BACKUP_ROOT}/qdrant_swarm_memory.json" <<'JSON'
{
  "result": {
    "points": [
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "payload": {
          "task_id": "smoke",
          "agent": "test"
        }
      }
    ]
  }
}
JSON

(
  cd "$TMP"
  tar -czf memory-smoke.tar.gz wizard_backup_test
)

OUTPUT="$(bash "$RESTORE" --dry-run "${TMP}/memory-smoke.tar.gz")"
echo "$OUTPUT" | grep -q "Would restore 1 point(s) into Qdrant collection: swarm_memory" \
  || fail "Restore dry-run did not report expected swarm_memory restore"

echo "PASS: Merlin memory manifest and restore dry-run are valid"
