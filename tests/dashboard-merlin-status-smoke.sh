#!/usr/bin/env bash
# Static smoke test for the read-only Merlin dashboard status panel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

require() {
  grep -q "$1" "$DASHBOARD_FILE" || fail "$2"
}

require "Merlin Dashboard" "dashboard missing Merlin Dashboard title"
require "Your private AI. On your Mac. Forever." "dashboard missing Merlin AI product framing"
require "Your private AI. Local by default." "dashboard missing local-by-default tagline"
require "Merlin AI is running" "dashboard missing first-run onboarding statement"
require "Nothing leaves this Mac" "dashboard missing plain-English privacy promise"
require "Start Chatting" "dashboard missing first-run chat action"
require "Automate" "dashboard missing first-run automation action"
require "Merlin assistant face" "dashboard missing Merlin face asset label"
require "placeholder=\"Ask Merlin...\"" "dashboard missing clean Ask Merlin input"
if grep -q "Talk to Merlin first" "$DASHBOARD_FILE"; then
  fail "dashboard must not show the removed Merlin chat intro block"
fi
require "toggleChatSidebar" "dashboard missing collapsible chat side panel handler"
require "sidebar-collapsed" "dashboard missing desktop chat side panel collapsed state"
require "sidebar-open" "dashboard missing mobile chat side panel expanded state"
require "System State" "dashboard missing side-panel system state"
require "Shows whether Merlin is using local-only mode" "dashboard status chips need hover explanations"
require "Chat with Merlin through the local policy-gated route" "dashboard top tabs need hover explanations"
require "chat-home tab-page active" "dashboard missing active chat home tab"
require "Memory" "dashboard missing Memory tab"
require "Agents" "dashboard missing Agents tab"
require "Security" "dashboard missing Security tab"
require "System" "dashboard missing System tab"
require "wizard merlin status" "dashboard missing Wizard status recovery command"
require "wizard merlin status-api start" "dashboard missing status API start command"
require "bash scripts/merlin-task-api.sh start" "dashboard missing Task API start command"
require "bash launchd/install-launchd.sh" "dashboard missing launchd install command"
require "35-40 seconds" "dashboard missing warmup timing copy"
require "localhost:3000" "dashboard missing local dashboard URL"
require "local_only" "dashboard missing local-only privacy mode"
require "Cloud Allowed" "dashboard missing cloud policy surface"
require "Execution Allowed" "dashboard missing execution policy surface"
require "Chat uses policy-gated Task API POSTs" "dashboard missing policy-gated chat and Room POST boundary"
require "http://localhost:8765/status" "dashboard missing read-only status API fetch"
require "http://localhost:8766/status/routes" "dashboard missing routes status fetch"
require "http://localhost:8766/status/approvals" "dashboard missing approvals status fetch"
require "http://localhost:8766/status/memory" "dashboard missing memory status fetch"
require "http://localhost:8766/status/traces" "dashboard missing trace status fetch"
require "loadMerlinStatus" "dashboard missing Merlin status loader"
require "loadApprovals" "dashboard missing approvals loader"
require "loadRoutes" "dashboard missing routes loader"
require "loadMemory" "dashboard missing memory loader"
require "loadTraces" "dashboard missing traces loader"
require "Ask Merlin" "dashboard missing Merlin chat surface"
require "submitMerlinChat" "dashboard missing Merlin chat submit handler"
require 'fetch(`${TASK_API}/task`' "dashboard missing policy-gated Task API POST"
require '/approvals/room-transcript' "dashboard missing Room transcript approval request"
require '/rooms/transcripts' "dashboard missing approved Room transcript save"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
if [[ "$POST_COUNT" != "3" ]]; then
  echo "Dashboard must use only Task API /task POSTs and shared policy-gated POST helper" >&2
  exit 1
fi

if grep -q "Ask Wizard\\|wizard-task\\|api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  echo "Dashboard must not call model backends directly" >&2
  exit 1
fi

if grep -q "approvals approve" "$DASHBOARD_FILE"; then
  echo "Dashboard must not expose approval execution commands yet" >&2
  exit 1
fi

if grep -q "approvals deny" "$DASHBOARD_FILE"; then
  echo "Dashboard must not expose approval denial commands yet" >&2
  exit 1
fi

echo "Dashboard Merlin status smoke test passed"
