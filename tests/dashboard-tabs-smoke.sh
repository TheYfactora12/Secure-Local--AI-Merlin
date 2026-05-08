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
grep -q "Open Merlin Chat Workspace" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin chat workspace entry"
grep -q "open-chat-workspace" "$DASHBOARD_FILE" \
  || fail "dashboard missing stable chat workspace link id"
grep -q "Open WebUI runs the chat engine today; Merlin owns routing, policy, memory, and status around it" "$DASHBOARD_FILE" \
  || fail "dashboard missing honest chat bridge boundary"
grep -q "Merlin Chat" "$DASHBOARD_FILE" \
  || fail "dashboard missing native Merlin Chat surface"
grep -q "Merlin AI core face" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin product face in hero"
grep -q "submitMerlinChat" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat submit handler"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "Merlin Chat must route through Task API /task"
grep -q "selected_model_alias" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must render selected model metadata"
grep -q "approval required" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must handle approval-required responses"
grep -q "Cloud Providers" "$DASHBOARD_FILE" \
  || fail "dashboard missing cloud provider disabled surface"
grep -q "cloud disabled by default" "$DASHBOARD_FILE" \
  || fail "dashboard missing cloud-disabled default language"
grep -q "/status/providers" "$DASHBOARD_FILE" \
  || fail "dashboard must load provider connector catalog"
grep -q "brains-provider-catalog" "$DASHBOARD_FILE" \
  || fail "dashboard missing provider connector catalog panel"
grep -q "not allowed until the user explicitly configures" "$DASHBOARD_FILE" \
  || fail "dashboard missing explicit allow/not-allow provider language"
grep -q "function loadProviders" "$DASHBOARD_FILE" \
  || fail "dashboard missing provider connector loader"
grep -q "api_family" "$DASHBOARD_FILE" \
  || fail "dashboard provider catalog must render provider API family"
grep -q "toggle-state" "$DASHBOARD_FILE" \
  || fail "dashboard missing provider allow/not-allow toggle state visual"
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

for setting in \
  "Provider Connectors" \
  "Model Library" \
  "Memory Controls" \
  "Privacy & Sovereignty" \
  "Startup & APIs" \
  "Backup & Recovery"; do
  grep -q "${setting}" "$DASHBOARD_FILE" \
    || fail "dashboard missing settings card: ${setting}"
done

for safe_command in \
  "bash scripts/add-model.sh" \
  "bash scripts/backup.sh" \
  "bash scripts/upgrade.sh" \
  "bash pkg/scripts/uninstall.sh" \
  "bash launchd/install-launchd.sh"; do
  grep -q "${safe_command}" "$DASHBOARD_FILE" \
    || fail "dashboard missing safe CLI handoff: ${safe_command}"
done

grep -q "#31 / #32" "$DASHBOARD_FILE" \
  || fail "dashboard settings must point memory review/delete to tracked issues"
grep -q "Cloud escalation" "$DASHBOARD_FILE" \
  || fail "dashboard missing cloud escalation setting"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "dashboard tab shell must not call model backends directly"
fi

if grep -qiE '<input|type="password"|downloadModel|pullModel|runShell|writeMemory|configureProvider|approveGate|denyGate|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  fail "dashboard tab shell must not expose unsafe setup/action controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "dashboard must not contain secret-like values"
fi

echo "PASS: Wizard HQ tab shell is Merlin-native and read-only"
