#!/usr/bin/env bash
# Static smoke test for the read-only Merlin dashboard status panel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

grep -q "Wizard HQ" "$DASHBOARD_FILE"
grep -q "Merlin AI" "$DASHBOARD_FILE"
grep -q "Private Intelligence. Locally Owned." "$DASHBOARD_FILE"
grep -q "First Run" "$DASHBOARD_FILE"
grep -q "Open Merlin Local Chat" "$DASHBOARD_FILE"
grep -q "Brain Status" "$DASHBOARD_FILE"
grep -q "Memory Vault" "$DASHBOARD_FILE"
grep -q "Agent Control" "$DASHBOARD_FILE"
grep -q "Sovereignty Status" "$DASHBOARD_FILE"
grep -q "Knowledge Graph" "$DASHBOARD_FILE"
grep -q "System Doctor" "$DASHBOARD_FILE"
grep -q "wizard merlin status" "$DASHBOARD_FILE"
grep -q "wizard merlin status-api start" "$DASHBOARD_FILE"
grep -q "Start status API" "$DASHBOARD_FILE"
grep -q "localhost:3000" "$DASHBOARD_FILE"
grep -q "wizard merlin approvals list" "$DASHBOARD_FILE"
grep -q "wizard merlin dry-run" "$DASHBOARD_FILE"
grep -q "local_only" "$DASHBOARD_FILE"
grep -q "Cloud Allowed" "$DASHBOARD_FILE"
grep -q "Execution Allowed" "$DASHBOARD_FILE"
grep -q "does not approve gates" "$DASHBOARD_FILE"
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

if grep -q "method:'POST'\\|method: 'POST'\\|method: \"POST\"\\|fetch(.*POST" "$DASHBOARD_FILE"; then
  echo "Dashboard v1 must not POST or execute actions" >&2
  exit 1
fi

if grep -q "Ask Wizard\\|wizard-task\\|api/generate" "$DASHBOARD_FILE"; then
  echo "Dashboard v1 must not expose chat execution controls" >&2
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
