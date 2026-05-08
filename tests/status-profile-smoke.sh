#!/usr/bin/env bash
# Smoke-test that the service status dashboard is profile-aware for low/core.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="${ROOT_DIR}/scripts/status.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$STATUS" ]] || fail "Missing scripts/status.sh"

grep -q 'profile_capabilities_for' "$STATUS" \
  || fail "status.sh must resolve active profile capabilities"
grep -q 'DISABLED' "$STATUS" \
  || fail "status.sh must distinguish disabled optional profiles from down services"
grep -q 'has_capability automation' "$STATUS" \
  || fail "status.sh must gate n8n display on the automation profile"
grep -q 'has_capability search' "$STATUS" \
  || fail "status.sh must gate search services on the search profile"
grep -q 'has_capability coding' "$STATUS" \
  || fail "status.sh must gate OpenHands on the coding profile"

echo "PASS: status dashboard is profile-aware"
