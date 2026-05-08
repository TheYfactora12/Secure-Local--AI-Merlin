#!/usr/bin/env bash
# Static smoke test for Wizard HQ policy-gated Settings contract.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"
STATUS_EXTENSION="${ROOT_DIR}/merlin/status_extension.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DASHBOARD_FILE" ]] || fail "dashboard file missing"
[[ -f "$STATUS_EXTENSION" ]] || fail "status extension missing"

grep -q '@router.get("/settings")' "$STATUS_EXTENSION" \
  || fail "Task API missing read-only settings manifest endpoint"
grep -q "SETTINGS_ACTIONS" "$STATUS_EXTENSION" \
  || fail "settings endpoint must be backed by explicit action manifest"
grep -q '"settings_writes_enabled": False' "$STATUS_EXTENSION" \
  || fail "settings backend must keep writes disabled"
grep -q '"browser_actions_enabled": False' "$STATUS_EXTENSION" \
  || fail "settings backend must keep browser actions disabled"
grep -q '"secrets_displayed": False' "$STATUS_EXTENSION" \
  || fail "settings backend must never display secrets"
grep -q '"cloud_default": False' "$STATUS_EXTENSION" \
  || fail "settings backend must keep cloud default off"
grep -q '"model_downloads": "manual_only"' "$STATUS_EXTENSION" \
  || fail "settings backend must keep model downloads manual-only"

grep -q "/status/settings" "$DASHBOARD_FILE" \
  || fail "dashboard must load settings policy manifest"
grep -q "settings-policy-panel" "$DASHBOARD_FILE" \
  || fail "dashboard missing settings policy panel"
grep -q "function loadSettings" "$DASHBOARD_FILE" \
  || fail "dashboard missing settings loader"
grep -q "Policy-Gated Settings" "$DASHBOARD_FILE" \
  || fail "dashboard missing policy-gated settings copy"
grep -q "Actions remain locked unless a backend policy gate exists" "$DASHBOARD_FILE" \
  || fail "dashboard must explain settings remain locked"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

if grep -qiE '<input|type="password"|configureProvider|saveProvider|writeSettings|enableCloud|downloadModel|pullModel|runShell|writeMemory|approveGate|denyGate|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  fail "settings must not expose unsafe browser controls"
fi

if grep -qiE 'OPENAI_API_KEY|ANTHROPIC_API_KEY|PERPLEXITY_API_KEY|sk-[A-Za-z0-9]{20,}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "settings dashboard must not expose secret-like values or env key names"
fi

echo "PASS: Wizard HQ Settings is backend-manifested and policy-gated"
