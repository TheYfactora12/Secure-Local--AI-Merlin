#!/usr/bin/env bash
# Static checks for macOS launchd startup safety.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_PLIST="${ROOT_DIR}/launchd/com.homeai.stack.plist"
INSTALLER="${ROOT_DIR}/launchd/install-launchd.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$STACK_PLIST" ]] || fail "missing stack launchd plist"
[[ -f "$INSTALLER" ]] || fail "missing launchd installer"

bash -n "$INSTALLER" || fail "launchd installer syntax failed"

grep -q 'cli/wizard start core' "$STACK_PLIST" \
  || fail "stack launchd agent does not start the core profile through wizard"
grep -q 'HOME_AI_PROFILE=core' "$STACK_PLIST" \
  || fail "stack launchd agent does not pin HOME_AI_PROFILE=core"
grep -q 'read-only Merlin status API' "$INSTALLER" \
  || fail "launchd installer does not document status API autostart"

if grep -q 'docker compose up -d --remove-orphans' "$STACK_PLIST"; then
  fail "stack launchd agent still starts raw docker compose instead of core profile"
fi

grep -q 'laptop-safe core profile' "$INSTALLER" \
  || fail "launchd installer does not document core-only autostart"

echo "PASS: launchd autostart is core-profile safe"
