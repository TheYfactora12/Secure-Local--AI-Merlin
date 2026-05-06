#!/usr/bin/env bash
# Static smoke test for wizard start/stop Merlin status API lifecycle wiring.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIZARD_FILE="${ROOT_DIR}/cli/wizard"
LAUNCHD_STACK_FILE="${ROOT_DIR}/launchd/com.homeai.stack.plist"

grep -q 'start_merlin_status_api()' "$WIZARD_FILE"
grep -q 'stop_merlin_status_api()' "$WIZARD_FILE"
grep -q 'HOME_AI_START_MERLIN_STATUS_API:-true' "$WIZARD_FILE"
grep -q 'scripts/merlin-status-api.sh" start' "$WIZARD_FILE"
grep -q 'scripts/merlin-status-api.sh" stop' "$WIZARD_FILE"
grep -q 'wizard merlin status-api status' "$WIZARD_FILE"

for profile in core search automation coding full; do
  grep -A3 "${profile})" "$WIZARD_FILE" | grep -q 'start_merlin_status_api' \
    || { echo "wizard start ${profile} should start read-only status API" >&2; exit 1; }
done

grep -A5 '^  stop)' "$WIZARD_FILE" | grep -q 'stop_merlin_status_api' \
  || { echo "wizard stop should stop read-only status API" >&2; exit 1; }
grep -A6 '^  restart)' "$WIZARD_FILE" | grep -q 'start_merlin_status_api' \
  || { echo "wizard restart should restart read-only status API" >&2; exit 1; }

if grep -q 'merlin-status-api' "$LAUNCHD_STACK_FILE"; then
  echo "launchd should not auto-start the Merlin status API yet" >&2
  exit 1
fi

echo "PASS: wizard start/stop status API lifecycle wiring is conservative"
