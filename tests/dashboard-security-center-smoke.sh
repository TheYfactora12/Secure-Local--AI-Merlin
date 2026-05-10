#!/usr/bin/env bash
# Static smoke test for the read-only dashboard security/approvals panel.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

grep -q ">Security<" "$DASHBOARD_FILE"
grep -q "Sovereignty is visible" "$DASHBOARD_FILE"
grep -q "Approval Gates" "$DASHBOARD_FILE"
grep -q "Approval is temporary by default" "$DASHBOARD_FILE"
grep -q "allow once" "$DASHBOARD_FILE"
grep -q "Permanent allow" "$DASHBOARD_FILE"
grep -q "off / future settings" "$DASHBOARD_FILE"
grep -q "Permanent Approvals" "$DASHBOARD_FILE"
grep -q "Don't ask again for this action type" "$DASHBOARD_FILE"
grep -q "Permanent approvals are off" "$DASHBOARD_FILE"
grep -q "explainPermanentApprovalsLocked" "$DASHBOARD_FILE"
grep -q "15" "$DASHBOARD_FILE"
grep -q "cloud_disabled" "$DASHBOARD_FILE"
grep -q "local_only" "$DASHBOARD_FILE"
grep -q "Approve buttons" "$DASHBOARD_FILE"
grep -q "not present here" "$DASHBOARD_FILE"
grep -q "webhook_execution" "$ROOT_DIR/configs/merlin/policy.yaml"
grep -q "http://localhost:8766/status/approvals" "$DASHBOARD_FILE"

if grep -qiE '(api[_-]?key|token|password|secret)[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  echo "Dashboard must not contain secret-display fields or key-like values" >&2
  exit 1
fi

if grep -qiE '<button[^>]*>[^<]*(approve|deny)|approvals approve|approvals deny|approveGate|denyGate|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  echo "Dashboard security center must not expose approve buttons in v1" >&2
  exit 1
fi

echo "PASS: dashboard security center is read-only and approval-gate aware"
