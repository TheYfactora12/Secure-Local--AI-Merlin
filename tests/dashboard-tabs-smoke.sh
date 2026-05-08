#!/usr/bin/env bash
# Static smoke test for the Merlin-native Wizard HQ tab shell.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DASHBOARD_FILE" ]] || fail "dashboard file missing"

grep -q 'aria-label="Wizard HQ product tabs"' "$DASHBOARD_FILE" \
  || fail "dashboard missing product tab navigation"
grep -q 'function selectTab' "$DASHBOARD_FILE" \
  || fail "dashboard tabs are not wired"

for tab in chat brains memory agents security system settings; do
  grep -q "data-tab-target=\"${tab}\"" "$DASHBOARD_FILE" \
    || fail "dashboard missing tab button: ${tab}"
  grep -q "data-tab-page=\"${tab}\"" "$DASHBOARD_FILE" \
    || fail "dashboard missing tab page: ${tab}"
done

for label in \
  "Chat" \
  "Brains" \
  "Memory" \
  "Agents" \
  "Security" \
  "System" \
  "Settings"; do
  grep -q ">${label}<" "$DASHBOARD_FILE" \
    || fail "dashboard missing visible tab label: ${label}"
done

grep -q "Merlin owns the experience" "$DASHBOARD_FILE" \
  || fail "dashboard does not present Merlin as the product owner"
grep -q "replaceable brain connectors" "$DASHBOARD_FILE" \
  || fail "dashboard does not describe models/providers as connectors"
grep -q "Open WebUI Bridge" "$DASHBOARD_FILE" \
  || fail "dashboard missing Open WebUI bridge framing"
grep -q "not the Merlin product identity" "$DASHBOARD_FILE" \
  || fail "dashboard does not demote Open WebUI from product identity"
grep -q "Cloud Providers" "$DASHBOARD_FILE" \
  || fail "dashboard missing cloud provider disabled surface"
grep -q "cloud disabled by default" "$DASHBOARD_FILE" \
  || fail "dashboard missing cloud-disabled default language"
grep -q "manual only" "$DASHBOARD_FILE" \
  || fail "dashboard missing no-surprise-download language"
grep -q "8GB/core systems" "$DASHBOARD_FILE" \
  || fail "dashboard missing low-memory/core warning language"
grep -q "approved memory only" "$DASHBOARD_FILE" \
  || fail "dashboard missing approval-gated learning language"
grep -q "API key fields" "$DASHBOARD_FILE" \
  || fail "dashboard settings must explicitly keep API key fields unavailable"
grep -q "not available" "$DASHBOARD_FILE" \
  || fail "dashboard missing locked setting language"

if grep -q "method:'POST'\\|method: 'POST'\\|method: \"POST\"\\|fetch(.*POST" "$DASHBOARD_FILE"; then
  fail "dashboard tab shell must not add POST or execution calls"
fi

if grep -qiE '<input|<textarea|type="password"|downloadModel|pullModel|runShell|writeMemory|configureProvider|approveGate|denyGate|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  fail "dashboard tab shell must not expose unsafe setup/action controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "dashboard must not contain secret-like values"
fi

echo "PASS: Wizard HQ tab shell is Merlin-native and read-only"
