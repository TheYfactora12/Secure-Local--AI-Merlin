#!/usr/bin/env bash
# Initialize the local Merlin brain folder layout.
#
# This script creates user-owned filesystem folders only. It does not index
# content, write approved memory, start services, pull models, or enable cloud.
set -euo pipefail

BRAIN_ROOT="${MERLIN_BRAIN_ROOT:-${HOME}/Merlin/brain}"
ROOMS_ROOT="${MERLIN_ROOMS_ROOT:-${BRAIN_ROOT}/rooms}"
DEFAULT_ROOM_ID="${MERLIN_DEFAULT_ROOM_ID:-merlin-build}"
DEFAULT_ROOM_NAME="${MERLIN_DEFAULT_ROOM_NAME:-Merlin Build}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

case "$DEFAULT_ROOM_ID" in
  ''|*[!A-Za-z0-9._-]*)
    fail "MERLIN_DEFAULT_ROOM_ID must be a safe slug: letters, numbers, dot, underscore, or dash"
    ;;
esac

if [[ "${#DEFAULT_ROOM_ID}" -gt 80 ]]; then
  fail "MERLIN_DEFAULT_ROOM_ID must be 80 characters or fewer"
fi

DEFAULT_ROOM_DIR="${ROOMS_ROOT}/${DEFAULT_ROOM_ID}"
DEFAULT_ROOM_META="${DEFAULT_ROOM_DIR}/room.md"

mkdir -p \
  "$BRAIN_ROOT" \
  "$BRAIN_ROOT/memories" \
  "$ROOMS_ROOT" \
  "$DEFAULT_ROOM_DIR/transcripts" \
  "$DEFAULT_ROOM_DIR/summaries" \
  "$DEFAULT_ROOM_DIR/master-prompts" \
  "$DEFAULT_ROOM_DIR/agents" \
  "$DEFAULT_ROOM_DIR/index"

if [[ ! -f "$DEFAULT_ROOM_META" ]]; then
  cat > "$DEFAULT_ROOM_META" <<EOF
name: ${DEFAULT_ROOM_NAME}
room_id: ${DEFAULT_ROOM_ID}
reference_policy: no_room_context
memory_extraction: requires_approval
created_by: merlin_local_brain_init
local_only: true

EOF
fi

echo "brain_root: ${BRAIN_ROOT}"
echo "rooms_root: ${ROOMS_ROOT}"
echo "default_room: ${DEFAULT_ROOM_ID}"
echo "status: initialized"
