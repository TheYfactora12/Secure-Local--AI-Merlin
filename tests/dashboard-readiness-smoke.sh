#!/usr/bin/env bash
# Static smoke test for Merlin Dashboard startup/readiness UX.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

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

grep -q 'class="diagnostic-cache"' "$DASHBOARD_FILE" \
  || fail "dashboard missing hidden readiness/status runtime hooks"

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
grep -q "If Merlin stays warming" "$DASHBOARD_FILE" \
  || fail "dashboard missing plain-English System recovery heading"
grep -q "Do not add API keys or cloud providers to fix startup" "$DASHBOARD_FILE" \
  || fail "dashboard recovery must preserve local-first privacy guidance"
grep -q "tail -n 120 /tmp/merlin-ai-install.log" "$DASHBOARD_FILE" \
  || fail "dashboard recovery missing install log evidence command"
grep -q "What to send us" "$DASHBOARD_FILE" \
  || fail "dashboard missing support evidence guidance"
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
POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "3" ]] || fail "dashboard must use only Task API /task POSTs and shared policy-gated POST helper"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "dashboard chat POST must route through Merlin Task API /task"
grep -q "/approvals/room-transcript" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript approval path"
grep -q "/rooms/transcripts" "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript save path"
grep -q "/approvals/task-route" "$DASHBOARD_FILE" \
  || fail "dashboard missing one-time task route approval path"
grep -q "function allowTaskRouteOnce" "$DASHBOARD_FILE" \
  || fail "dashboard missing one-time route approval handler"
grep -q "one local model response for this same prompt only" "$DASHBOARD_FILE" \
  || fail "dashboard task approval copy must limit the scope"
grep -q "does not enable tools, file reads, shell commands, memory writes, cloud calls, or permanent approval" "$DASHBOARD_FILE" \
  || fail "dashboard task approval copy must preserve protected boundaries"
if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "dashboard readiness must not call model backends directly"
fi
if grep -q "approveGate\\|denyGate\\|data-action=\"approve\"\\|data-action=\"deny\"" "$DASHBOARD_FILE"; then
  fail "dashboard readiness must not introduce approval controls"
fi

echo "PASS: Merlin Dashboard readiness surface is honest and read-only"
