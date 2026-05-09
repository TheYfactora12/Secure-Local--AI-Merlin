#!/usr/bin/env bash
# Static smoke test for native Merlin Chat in Wizard HQ.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "Ask Merlin" "$DASHBOARD_FILE" \
  || fail "dashboard missing Ask Merlin heading"
grep -q "Merlin AI core face" "$DASHBOARD_FILE" \
  || fail "dashboard missing centered Merlin AI core face"
grep -q 'assets/merlin-orb.png' "$DASHBOARD_FILE" \
  || fail "dashboard missing local Merlin orb image asset reference"
[[ -f "${ROOT_DIR}/dashboard/assets/merlin-orb.png" ]] \
  || fail "dashboard missing local Merlin orb image asset"
grep -q 'rel="icon" type="image/png" href="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin M browser favicon"
grep -q 'rel="apple-touch-icon" href="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin M Apple touch icon"
grep -q 'class="mark"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin M corner mark container"
grep -q 'src="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin M corner mark image"
[[ -f "${ROOT_DIR}/dashboard/assets/merlin-m-sigil.png" ]] \
  || fail "dashboard missing local Merlin M sigil asset"
grep -q "merlin-face" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin face visual"
grep -q "merlin-front-shell" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin front-page shell"
grep -q "front-sidebar" "$DASHBOARD_FILE" \
  || fail "dashboard missing local chat sidebar"
grep -q "front-composer-wrap" "$DASHBOARD_FILE" \
  || fail "dashboard missing premium composer wrapper"
grep -q "Talk to Merlin first" "$DASHBOARD_FILE" \
  || fail "dashboard missing clean Merlin-first chat copy"
grep -q 'id="merlin-chat-input"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat input"
grep -q 'id="merlin-chat-submit"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat submit button"
grep -q "function submitMerlinChat" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat submit handler"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "Merlin Chat must call only Merlin Task API /task"
grep -q "method: 'POST'" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing Task API POST"
grep -q "selected_model_alias" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must display selected model alias"
grep -q "staff_mode" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must display staff mode"
grep -q "approval required" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must handle approval-required routes"
grep -q "Task API is classifying the request and checking policy gates" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing policy-gate routing copy"
grep -q "Safe Merlin starter prompts" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing safe starter prompt group"
grep -q "function setMerlinPrompt" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing safe prompt-fill helper"
grep -q "message-thread" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing message thread layout"
grep -q "source-line" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing local/source proof line"
grep -q "Local by default" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing local-by-default proof"
grep -q "Memory writes require approval" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing approval-gated memory copy"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "native chat must not call model backends directly"
fi

if grep -q "fonts.googleapis.com\\|fonts.gstatic.com\\|unpkg.com\\|cdn.jsdelivr.net" "$DASHBOARD_FILE"; then
  fail "native chat must not introduce external UI dependencies"
fi

if grep -qiE 'approveGate|denyGate|data-action="approve"|data-action="deny"|writeMemory|runShell|downloadModel|pullModel' "$DASHBOARD_FILE"; then
  fail "native chat must not expose unsafe browser controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "native chat must not expose secret-like values"
fi

echo "PASS: Wizard HQ native Merlin Chat is policy-gated through Task API"
