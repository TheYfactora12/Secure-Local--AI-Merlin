#!/usr/bin/env bash
# Static smoke test for doctor warmup/historical-log diagnostics.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTOR="${ROOT_DIR}/scripts/doctor.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOCTOR" ]] || fail "Missing scripts/doctor.sh"

grep -q "MERLIN_PORTS_OPEN" "$DOCTOR" \
  || fail "doctor must track current Merlin API port state"
grep -q "closed or warming after launchd registration" "$DOCTOR" \
  || fail "doctor must label launchd-delayed API startup as warming"
grep -q "Historical log scan" "$DOCTOR" \
  || fail "doctor must distinguish historical log warnings from current API health"
grep -q "truncate -s 0 logs/\\*.log" "$DOCTOR" \
  || fail "doctor must provide a safe stale-log remediation hint"

echo "PASS: doctor warmup diagnostics are explicit"
