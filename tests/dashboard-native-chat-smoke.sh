#!/usr/bin/env bash
# Static smoke test for native Merlin Chat in Wizard HQ.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "Merlin AI" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin AI chat brand"
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
grep -q "merlin-orb-stage" "$DASHBOARD_FILE" \
  || fail "dashboard missing living Merlin orb stage"
grep -q "@keyframes merlinOrbBreathe" "$DASHBOARD_FILE" \
  || fail "dashboard missing subtle Merlin orb breath animation"
grep -q "@keyframes merlinOrbHalo" "$DASHBOARD_FILE" \
  || fail "dashboard missing subtle Merlin orb halo animation"
grep -q "@media (prefers-reduced-motion: reduce)" "$DASHBOARD_FILE" \
  || fail "dashboard Merlin orb motion must respect reduced-motion preference"
grep -q "front-sidebar" "$DASHBOARD_FILE" \
  || fail "dashboard missing local chat sidebar"
grep -q "toggleChatSidebar" "$DASHBOARD_FILE" \
  || fail "dashboard missing collapsible chat sidebar handler"
grep -q "sidebar-collapsed" "$DASHBOARD_FILE" \
  || fail "dashboard missing desktop collapsed sidebar state"
grep -q "sidebar-open" "$DASHBOARD_FILE" \
  || fail "dashboard missing mobile expanded sidebar state"
grep -q "chat-context-sidebar" "$DASHBOARD_FILE" \
  || fail "dashboard missing accessible chat context sidebar id"
grep -q "front-composer-wrap" "$DASHBOARD_FILE" \
  || fail "dashboard missing premium composer wrapper"
grep -q "composer-tools" "$DASHBOARD_FILE" \
  || fail "dashboard missing chat composer tool rail"
grep -q "composer-mode-selector" "$DASHBOARD_FILE" \
  || fail "dashboard missing composer mode selector"
grep -q "data-chat-mode=\"fast\"" "$DASHBOARD_FILE" \
  || fail "dashboard missing Fast mode option"
grep -q "data-chat-mode=\"smart\"" "$DASHBOARD_FILE" \
  || fail "dashboard missing Smart mode option"
grep -q "data-chat-mode=\"deep\"" "$DASHBOARD_FILE" \
  || fail "dashboard missing Deep mode option"
grep -q "function selectChatMode" "$DASHBOARD_FILE" \
  || fail "dashboard missing mode selector state binding"
grep -q "selectedChatMode" "$DASHBOARD_FILE" \
  || fail "dashboard missing selected chat mode state"
grep -q "\${escapeHtml(modeLabel)} mode" "$DASHBOARD_FILE" \
  || fail "dashboard response metadata must display selected UI mode as a compact tag"
if grep -q 'class="route-meta"' "$DASHBOARD_FILE"; then
  fail "dashboard must not render bulky route metadata cards inside Merlin Chat"
fi
if grep -q "Talk to Merlin first" "$DASHBOARD_FILE"; then
  fail "dashboard must not show the old Merlin-first intro block in the clean chat center"
fi
grep -q "placeholder=\"Ask Merlin...\"" "$DASHBOARD_FILE" \
  || fail "dashboard missing clean Ask Merlin input"
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
grep -q "Approval needed to continue" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must show a clean blocked-route approval card"
grep -q "Review approval" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must give users a clear path to review blocked routes"
grep -q "Keep blocked" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must give users a safe deny/dismiss action for blocked routes"
grep -q "does not yet create a chat approval id" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must not pretend blocked routes have inline approval ids"
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
grep -q 'id="merlin-chat-output" class="chat-output empty"' "$DASHBOARD_FILE" \
  || fail "Merlin Chat should not show a duplicate pre-response status bubble between image and composer"
grep -q ".chat-output.empty" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing hidden empty output state"
grep -q "panel.classList.remove('empty')" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must reveal output only after Merlin renders a response"
grep -q "Save latest chat to Room" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing Room transcript save surface"
grep -q "requestRoomTranscriptApproval" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing Room save approval request flow"
grep -q "allowRoomTranscriptSave" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing explicit local Room save flow"
grep -q 'data-room-save-stage="waiting"' "$DASHBOARD_FILE" \
  || fail "Merlin Chat Room save must hide save buttons until a safe response exists"
grep -q 'data-room-save-stage="response-ready"' "$DASHBOARD_FILE" \
  || fail "Merlin Chat Room save must show a prepare-only stage after Merlin responds"
grep -q 'data-room-save-stage="approval-prepared"' "$DASHBOARD_FILE" \
  || fail "Merlin Chat Room save must show allow/cancel only after backend approval is prepared"
grep -q "/approvals/room-transcript" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing Room transcript approval endpoint"
grep -q "/rooms/transcripts" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing approved Room transcript save endpoint"
grep -q "memory not written" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must show Room save does not write memory"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "2" ]] || fail "dashboard must use only Task POST and shared policy-gated POST helper"

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
