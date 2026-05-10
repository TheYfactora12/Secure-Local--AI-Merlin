#!/usr/bin/env bash
# Static smoke test for Round Table agent governance boundaries.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/architecture/ROUND_TABLE_AGENT_GOVERNANCE.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "Round Table governance doc missing"

for required in \
  "Status: CURRENT governance spec, FUTURE runtime implementation" \
  "Default state is suggest-only" \
  "They are not autonomous workers by default" \
  "No agent execution API should be added in that first slice" \
  "Security Warden" \
  "QA Sentinel" \
  "Product Steward" \
  "Smith" \
  "Market Scout" \
  "Prompt-based Room deletion without an approval card" \
  "Memory writes without approve/edit/deny" \
  "Cloud research or API calls by default" \
  "Room Master Prompt as approved for context reuse" \
  "No role may override the no-go rules"; do
  grep -Fq "$required" "$DOC" || fail "Round Table doc missing: $required"
done

if grep -qiE 'unattended execution is allowed|browser-side execution controls are enabled|cloud research by default|memory writes by default|no approval required' "$DOC"; then
  fail "Round Table doc must not allow autonomous/cloud/memory behavior by default"
fi

echo "PASS: Round Table agent governance stays suggest-only and approval-gated"
