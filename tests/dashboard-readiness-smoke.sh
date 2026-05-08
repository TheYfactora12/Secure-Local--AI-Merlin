#!/usr/bin/env bash
# Static smoke test for Wizard HQ startup/readiness UX.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "Startup Readiness" "$DASHBOARD_FILE" \
  || fail "dashboard missing startup readiness panel"

for stage in \
  "Preparing Merlin Core" \
  "Checking local hardware" \
  "Starting local AI brain" \
  "Starting memory vault" \
  "Starting model router" \
  "Starting dashboard" \
  "Verifying privacy mode" \
  "Running system doctor" \
  "Ready / Degraded"; do
  grep -q "$stage" "$DASHBOARD_FILE" || fail "dashboard missing readiness stage: $stage"
done

grep -q "renderReadiness" "$DASHBOARD_FILE" \
  || fail "dashboard does not compute readiness state"
grep -q "readinessState.services" "$DASHBOARD_FILE" \
  || fail "dashboard readiness is not tied to service probes"
grep -q "status.cloud_allowed === false" "$DASHBOARD_FILE" \
  || fail "dashboard readiness does not verify cloud-disabled state"
grep -q "status.online_mode === false" "$DASHBOARD_FILE" \
  || fail "dashboard readiness does not verify local/offline policy"
grep -q "readiness: warming" "$DASHBOARD_FILE" \
  || fail "dashboard missing warming readiness state"
grep -q "SERVICE_PROBE_TIMEOUT_MS = 5000" "$DASHBOARD_FILE" \
  || fail "dashboard service probe timeout is too short for 8GB warmup"
grep -q "STATUS_PANEL_TIMEOUT_MS = 7000" "$DASHBOARD_FILE" \
  || fail "dashboard status panel timeout is too short for 8GB warmup"
grep -q "35-40 seconds after launchd registration" "$DASHBOARD_FILE" \
  || fail "dashboard missing launchd warmup guidance"
grep -q "fix needed" "$DASHBOARD_FILE" \
  || fail "dashboard missing fix-needed wording"
grep -q "warming" "$DASHBOARD_FILE" \
  || fail "dashboard missing warming state"

if grep -q "Local Model</span><strong>Active" "$DASHBOARD_FILE"; then
  fail "dashboard still hardcodes Local Model as Active"
fi
if grep -q "All systems ready\\|Merlin is ready\\|System ready" "$DASHBOARD_FILE"; then
  fail "dashboard contains fake/static readiness language"
fi
if grep -q "method:'POST'\\|method: 'POST'\\|method: \"POST\"\\|fetch(.*POST" "$DASHBOARD_FILE"; then
  fail "dashboard readiness must not introduce POST or execution calls"
fi
if grep -q "approveGate\\|denyGate\\|data-action=\"approve\"\\|data-action=\"deny\"" "$DASHBOARD_FILE"; then
  fail "dashboard readiness must not introduce approval controls"
fi

echo "PASS: Wizard HQ readiness surface is honest and read-only"
