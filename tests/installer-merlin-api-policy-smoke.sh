#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT_DIR}/install.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q 'scripts/merlin-status-api.sh" start' "$INSTALLER" \
  || fail "installer should support starting the read-only Merlin status API"
grep -q 'Merlin Status API running' "$INSTALLER" \
  || fail "installer should report Merlin Status API running state in interactive mode"
grep -q 'Merlin status API start skipped in non-interactive mode' "$INSTALLER" \
  || fail "installer should not claim background status API persistence in non-interactive mode"
grep -q 'launchd/install-launchd.sh' "$INSTALLER" \
  || fail "installer should point users to launchd for persistent status API startup"
grep -q 'Status API.*35s' "$INSTALLER" \
  || fail "installer should document status API launchd warmup"
grep -q 'Task API.*40s' "$INSTALLER" \
  || fail "installer should document task API launchd warmup"
grep -q 'sleep 35 && bash scripts/doctor.sh' "$INSTALLER" \
  || fail "installer should print a post-launchd doctor verification command"
grep -q 'Read-only Merlin status is separated from task execution' "$INSTALLER" \
  || fail "installer should explain status/task API separation"
grep -q 'Merlin Task API.*not directly started' "$INSTALLER" \
  || fail "installer must not directly start the execution-aware Merlin Task API"
grep -q 'scripts/merlin-task-api.sh start' "$INSTALLER" \
  || fail "installer should print manual Merlin Task API start command"
grep -q 'command -v wizard' "$INSTALLER" \
  || fail "installer should avoid printing unavailable wizard commands"
grep -q '\${CLI_PATH} status' "$INSTALLER" \
  || fail "installer should print direct CLI path fallback when wizard symlink is unavailable"

echo "PASS: installer Merlin API startup policy is explicit"
