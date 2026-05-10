#!/usr/bin/env bash
# Static smoke test for Wizard HQ Chat home product clarity.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q 'class="chat-home tab-page active"' "$DASHBOARD_FILE" \
  || fail "Chat tab must be the primary product home"
grep -q "Merlin AI core face" "$DASHBOARD_FILE" \
  || fail "Chat home missing centered Merlin face"
grep -q 'assets/merlin-orb.png' "$DASHBOARD_FILE" \
  || fail "Chat home missing local Merlin orb asset"
[[ -f "${ROOT_DIR}/dashboard/assets/merlin-orb.png" ]] \
  || fail "local Merlin orb asset file missing"
grep -q 'rel="icon" type="image/png" href="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "Chat home missing Merlin M browser favicon"
grep -q 'rel="apple-touch-icon" href="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "Chat home missing Merlin M Apple touch icon"
grep -q 'src="assets/merlin-m-sigil.png"' "$DASHBOARD_FILE" \
  || fail "Chat home missing Merlin M corner logo"
[[ -f "${ROOT_DIR}/dashboard/assets/merlin-m-sigil.png" ]] \
  || fail "local Merlin M sigil asset file missing"
grep -q "merlin-front-shell" "$DASHBOARD_FILE" \
  || fail "Chat home missing premium Merlin front shell"
grep -q "merlin-orb-stage" "$DASHBOARD_FILE" \
  || fail "Chat home missing living Merlin orb stage"
grep -q "merlinOrbBreathe" "$DASHBOARD_FILE" \
  || fail "Chat home missing subtle Merlin orb motion"
grep -q "pageFadeIn" "$DASHBOARD_FILE" \
  || fail "dashboard pages need smooth tab transitions"
grep -q "prefers-reduced-motion" "$DASHBOARD_FILE" \
  || fail "dashboard motion must respect reduced-motion preference"
grep -q "focus-visible" "$DASHBOARD_FILE" \
  || fail "dashboard interactive controls need visible keyboard focus"
grep -q "prefers-reduced-motion: reduce" "$DASHBOARD_FILE" \
  || fail "Chat home orb motion must respect reduced-motion preference"
grep -q "composer-tools" "$DASHBOARD_FILE" \
  || fail "Chat home missing clean composer tool rail"
grep -q "composer-mode-selector" "$DASHBOARD_FILE" \
  || fail "Chat home missing mode selector in composer"
grep -q "Smart mode. Merlin routes to the best available model." "$DASHBOARD_FILE" \
  || fail "Chat home missing confident mode-to-router copy"
grep -q "New conversation" "$DASHBOARD_FILE" \
  || fail "Chat home missing local chat workspace affordance"
grep -q "Merlin AI" "$DASHBOARD_FILE" \
  || fail "Chat home missing Merlin AI center brand"
grep -q "Future talk mode: this is the Merlin presence you speak with" "$DASHBOARD_FILE" \
  || fail "Chat home missing future Merlin talk-mode presence note"
grep -q "voice capture, consent, and local audio privacy checks" "$DASHBOARD_FILE" \
  || fail "future talk-mode note must stay privacy/consent gated"
grep -q "placeholder=\"Ask Merlin...\"" "$DASHBOARD_FILE" \
  || fail "Chat home missing clean Ask Merlin input"
if grep -q "Talk to Merlin first" "$DASHBOARD_FILE"; then
  fail "Chat home must not show the removed Merlin-first intro block"
fi
grep -q "toggleChatSidebar" "$DASHBOARD_FILE" \
  || fail "Chat home missing collapsible side panel behavior"
grep -q "sidebar-collapsed" "$DASHBOARD_FILE" \
  || fail "Chat home missing desktop side panel collapsed state"
grep -q "sidebar-open" "$DASHBOARD_FILE" \
  || fail "Chat home missing mobile side panel expanded state"
grep -q 'id="sovereignty-indicator"' "$DASHBOARD_FILE" \
  || fail "dashboard missing persistent Sovereignty Indicator"
grep -q "System State" "$DASHBOARD_FILE" \
  || fail "dashboard must move status chips into the chat side panel"
grep -q "Shows whether Merlin is using local-only mode" "$DASHBOARD_FILE" \
  || fail "status chips must explain their purpose on hover"
grep -q "Chat with Merlin through the local policy-gated route" "$DASHBOARD_FILE" \
  || fail "top product tabs must include user-facing hover explanations"
grep -q "Local project spaces for saved transcripts" "$DASHBOARD_FILE" \
  || fail "Rooms tab must explain its purpose on hover"
grep -q ".topbar {" "$DASHBOARD_FILE" \
  || fail "dashboard missing sticky top bar styles"
grep -q "position: sticky" "$DASHBOARD_FILE" \
  || fail "top bar must stay locked while scrolling"
grep -q '<nav class="tabbar" aria-label="Wizard HQ product tabs">' "$DASHBOARD_FILE" \
  || fail "product tabs must live in the locked top bar"
grep -q "Sovereignty Indicator: Local Mode" "$DASHBOARD_FILE" \
  || fail "Sovereignty Indicator must default to Local Mode"
grep -q "Cloud Bridge Active" "$DASHBOARD_FILE" \
  || fail "Sovereignty Indicator must have explicit cloud bridge state"
grep -q "Offline / Warming" "$DASHBOARD_FILE" \
  || fail "Sovereignty Indicator must have explicit offline/warming state"
grep -q "Qwen is a current local model engine" "$DASHBOARD_FILE" \
  || fail "Brains tab does not explain Qwen as a model engine"
grep -q "Merlin can grow toward its own tuned local model later" "$DASHBOARD_FILE" \
  || fail "Brains tab missing honest future Merlin model language"
grep -q "External provider setup is deferred" "$DASHBOARD_FILE" \
  || fail "Settings tab missing safe setup default language"
grep -q "bash launchd/install-launchd.sh" "$DASHBOARD_FILE" \
  || fail "dashboard missing persistent launchd command"
grep -q "bash scripts/merlin-task-api.sh start" "$DASHBOARD_FILE" \
  || fail "dashboard missing manual task API command"
grep -q "35-40 seconds" "$DASHBOARD_FILE" \
  || fail "dashboard missing launchd warmup language"

if grep -qiE '<input|type="password"|api[_-]?key|token[[:space:]]*[:=]|password[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not expose secret-like fields"
fi

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "3" ]] || fail "dashboard must use only Task API /task POSTs and shared policy-gated POST helper"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "dashboard chat POST must route through Merlin Task API /task"
grep -q 'function postJson' "$DASHBOARD_FILE" \
  || fail "dashboard missing shared policy-gated POST helper"
grep -q '/approvals/room-transcript' "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript approval request path"
grep -q '/rooms/transcripts' "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript save path"
grep -q "saved to the local Room" "$DASHBOARD_FILE" \
  || fail "dashboard missing explicit local Room save copy"

if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not call model backends directly"
fi

if grep -qiE '<button[^>]*>[^<]*(download|pull|approve|run|write|configure)|downloadModel|pullModel|runShell|writeMemory|configureProvider' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not imply unsafe setup actions are available"
fi

echo "PASS: Wizard HQ Chat home product clarity is safe and read-only"
