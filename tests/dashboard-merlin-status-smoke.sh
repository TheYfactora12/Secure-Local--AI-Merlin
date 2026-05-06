#!/usr/bin/env bash
# Static smoke test for the read-only Merlin dashboard status panel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

grep -q "Merlin Control Status" "$DASHBOARD_FILE"
grep -q "wizard merlin status" "$DASHBOARD_FILE"
grep -q "wizard merlin status-api" "$DASHBOARD_FILE"
grep -q "wizard merlin approvals list" "$DASHBOARD_FILE"
grep -q "wizard merlin dry-run" "$DASHBOARD_FILE"
grep -q "local_only" "$DASHBOARD_FILE"
grep -q "Cloud Allowed" "$DASHBOARD_FILE"
grep -q "Execution Allowed" "$DASHBOARD_FILE"
grep -q "does not execute approvals" "$DASHBOARD_FILE"
grep -q "http://localhost:8765/status" "$DASHBOARD_FILE"
grep -q "loadMerlinStatus" "$DASHBOARD_FILE"
grep -q "updateMerlinServices" "$DASHBOARD_FILE"

if grep -q "approvals approve" "$DASHBOARD_FILE"; then
  echo "Dashboard must not expose approval execution commands yet" >&2
  exit 1
fi

if grep -q "approvals deny" "$DASHBOARD_FILE"; then
  echo "Dashboard must not expose approval denial commands yet" >&2
  exit 1
fi

echo "Dashboard Merlin status smoke test passed"
