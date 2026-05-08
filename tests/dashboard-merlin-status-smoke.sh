#!/usr/bin/env bash
# Static smoke test for the read-only Merlin dashboard status panel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

grep -q "Wizard HQ" "$DASHBOARD_FILE"
grep -q "Merlin AI" "$DASHBOARD_FILE"
grep -q "Private Intelligence. Locally Owned." "$DASHBOARD_FILE"
grep -q "Merlin AI core face" "$DASHBOARD_FILE"
grep -q ">Ask Merlin<" "$DASHBOARD_FILE"
grep -q "Talk to Merlin first" "$DASHBOARD_FILE"
grep -q "chat-home tab-page active" "$DASHBOARD_FILE"
grep -q "Memory" "$DASHBOARD_FILE"
grep -q "Agents" "$DASHBOARD_FILE"
grep -q "Security" "$DASHBOARD_FILE"
grep -q "System" "$DASHBOARD_FILE"
grep -q "wizard merlin status" "$DASHBOARD_FILE"
grep -q "wizard merlin status-api start" "$DASHBOARD_FILE"
grep -q "bash scripts/merlin-task-api.sh start" "$DASHBOARD_FILE"
grep -q "bash launchd/install-launchd.sh" "$DASHBOARD_FILE"
grep -q "35-40 seconds" "$DASHBOARD_FILE"
grep -q "localhost:3000" "$DASHBOARD_FILE"
grep -q "local_only" "$DASHBOARD_FILE"
grep -q "Cloud Allowed" "$DASHBOARD_FILE"
grep -q "Execution Allowed" "$DASHBOARD_FILE"
grep -q "Chat uses one policy-gated POST" "$DASHBOARD_FILE"
grep -q "http://localhost:8765/status" "$DASHBOARD_FILE"
grep -q "http://localhost:8766/status/routes" "$DASHBOARD_FILE"
grep -q "http://localhost:8766/status/approvals" "$DASHBOARD_FILE"
grep -q "http://localhost:8766/status/memory" "$DASHBOARD_FILE"
grep -q "http://localhost:8766/status/traces" "$DASHBOARD_FILE"
grep -q "loadMerlinStatus" "$DASHBOARD_FILE"
grep -q "loadApprovals" "$DASHBOARD_FILE"
grep -q "loadRoutes" "$DASHBOARD_FILE"
grep -q "loadMemory" "$DASHBOARD_FILE"
grep -q "loadTraces" "$DASHBOARD_FILE"
grep -q "Ask Merlin" "$DASHBOARD_FILE"
grep -q "submitMerlinChat" "$DASHBOARD_FILE"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
if [[ "$POST_COUNT" != "1" ]]; then
  echo "Dashboard must have exactly one POST: Merlin Task API /task" >&2
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
