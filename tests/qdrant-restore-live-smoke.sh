#!/usr/bin/env bash
# Live backup/restore smoke test against a disposable Qdrant collection.
#
# This test creates, backs up, deletes, recreates, restores, verifies, and
# removes a temporary collection. It does not touch production memory collections.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
TMP="$(mktemp -d)"
COLLECTION="merlin_restore_smoke_$(date +%s)_$$"
TEST_ID="restore-smoke-$(date +%s)-$$"

PASS=0
FAIL=0

pass() {
  echo "[PASS] $*"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $*" >&2
  FAIL=$((FAIL + 1))
}

cleanup() {
  curl -fsS --max-time 10 -X DELETE "${QDRANT_URL}/collections/${COLLECTION}" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[FAIL] Missing required command: $1" >&2
    exit 1
  }
}

create_collection() {
  curl -fsS --max-time 10 \
    -X PUT "${QDRANT_URL}/collections/${COLLECTION}" \
    -H "Content-Type: application/json" \
    -d '{"vectors":{"size":4,"distance":"Cosine"}}' >/dev/null
}

upsert_seed_point() {
  curl -fsS --max-time 10 \
    -X PUT "${QDRANT_URL}/collections/${COLLECTION}/points" \
    -H "Content-Type: application/json" \
    -d "{\"points\":[{\"id\":1,\"vector\":[0.1,0.2,0.3,0.4],\"payload\":{\"test_id\":\"${TEST_ID}\",\"source\":\"qdrant_restore_live_smoke\"}}]}" >/dev/null
}

delete_collection() {
  curl -fsS --max-time 10 -X DELETE "${QDRANT_URL}/collections/${COLLECTION}" >/dev/null
}

verify_restored_point() {
  local result
  result="$(curl -fsS --max-time 10 \
    -X POST "${QDRANT_URL}/collections/${COLLECTION}/points/scroll" \
    -H "Content-Type: application/json" \
    -d "{\"limit\":10,\"with_payload\":true,\"with_vector\":true,\"filter\":{\"must\":[{\"key\":\"test_id\",\"match\":{\"value\":\"${TEST_ID}\"}}]}}")"

  python3 -c 'import json,sys
data=json.load(sys.stdin)
points=data.get("result", {}).get("points", [])
if len(points) != 1:
    raise SystemExit(1)
point=points[0]
payload=point.get("payload", {})
vector=point.get("vector")
if payload.get("source") != "qdrant_restore_live_smoke":
    raise SystemExit(1)
if not vector:
    raise SystemExit(1)
' <<<"$result"
}

echo "Merlin AI live Qdrant restore smoke test"
echo "Collection: ${COLLECTION}"
echo ""

require_cmd curl
require_cmd python3
require_cmd tar

if curl -fsS --max-time 10 "${QDRANT_URL}/collections" >/dev/null; then
  pass "Qdrant reachable"
else
  fail "Qdrant unreachable: ${QDRANT_URL}"
  exit 1
fi

create_collection
pass "Disposable collection created"

upsert_seed_point
pass "Seed point inserted"

HOME_AI_BACKUP_DIR="${TMP}/backups" \
MERLIN_BACKUP_COLLECTIONS="${COLLECTION}" \
QDRANT_URL="${QDRANT_URL}" \
  bash "${STACK_DIR}/backup/backup.sh" >/dev/null

BACKUP_FILE="$(find "${TMP}/backups" -maxdepth 1 -name 'wizard_backup_*.tar.gz' | head -n 1)"
if [[ -f "$BACKUP_FILE" ]]; then
  pass "Disposable backup archive created"
else
  fail "Disposable backup archive missing"
  exit 1
fi

delete_collection
pass "Disposable collection deleted before restore"

create_collection
pass "Disposable collection recreated empty"

HOME_AI_ASSUME_YES=true \
QDRANT_URL="${QDRANT_URL}" \
  bash "${STACK_DIR}/backup/restore.sh" "$BACKUP_FILE" >/dev/null
pass "Restore command completed"

if verify_restored_point; then
  pass "Restored point payload and vector verified"
else
  fail "Restored point was not found or was incomplete"
fi

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failures"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi

exit 0
