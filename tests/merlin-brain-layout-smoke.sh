#!/usr/bin/env bash
# Smoke-test local Merlin brain/Rooms folder initialization.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/init-merlin-brain.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$SCRIPT" ]] || fail "Missing scripts/init-merlin-brain.sh"
bash -n "$SCRIPT" || fail "init-merlin-brain.sh syntax failed"

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

HOME="$TMP_HOME" bash "$SCRIPT" >/tmp/merlin-brain-layout-smoke.out

BRAIN_ROOT="${TMP_HOME}/Merlin/brain"
ROOM_ROOT="${BRAIN_ROOT}/rooms"
DEFAULT_ROOM="${ROOM_ROOT}/merlin-build"

[[ -d "$BRAIN_ROOT" ]] || fail "brain root was not created"
[[ -d "${BRAIN_ROOT}/memories" ]] || fail "memories folder was not created"
[[ -d "$ROOM_ROOT" ]] || fail "Rooms root was not created"
[[ -d "${DEFAULT_ROOM}/transcripts" ]] || fail "default Room transcripts folder was not created"
[[ -d "${DEFAULT_ROOM}/summaries" ]] || fail "default Room summaries folder was not created"
[[ -d "${DEFAULT_ROOM}/master-prompts" ]] || fail "default Room master-prompts folder was not created"
[[ -d "${DEFAULT_ROOM}/agents" ]] || fail "default Room agents folder was not created"
[[ -d "${DEFAULT_ROOM}/index" ]] || fail "default Room index folder was not created"
[[ -f "${DEFAULT_ROOM}/room.md" ]] || fail "default Room metadata was not created"

grep -q "name: Merlin Build" "${DEFAULT_ROOM}/room.md" \
  || fail "default Room metadata missing name"
grep -q "reference_policy: no_room_context" "${DEFAULT_ROOM}/room.md" \
  || fail "default Room metadata must keep no-context policy"
grep -q "memory_extraction: requires_approval" "${DEFAULT_ROOM}/room.md" \
  || fail "default Room metadata must keep memory extraction approval-gated"
grep -q "local_only: true" "${DEFAULT_ROOM}/room.md" \
  || fail "default Room metadata must mark local-only storage"

if find "$TMP_HOME" -type f | grep -qE 'approved_memory|transcript.*\.md$'; then
  fail "brain initializer must not create approved memory or transcript content"
fi

echo "PASS: Merlin brain layout initializes local Rooms without memory writes"
