#!/usr/bin/env bash
# Static smoke test for user-facing release-readiness positioning.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="${ROOT_DIR}/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "Local Trusted Beta" "$README" \
  || fail "README must state Local Trusted Beta positioning"
grep -q "Home AI Elite" "$README" \
  || fail "README must show Home AI Elite as product name"
grep -q "Merlin is the AI assistant inside" "$README" \
  || fail "README must explain Merlin is the assistant inside Home AI Elite"
grep -q "Private AI at home in 30 minutes" "$README" \
  || fail "README must lead with the non-technical private home AI promise"
grep -q "not being claimed as Public Beta ready" "$README" \
  || fail "README must not overclaim Public Beta readiness"
grep -q "TRUSTED_LOCAL_BETA_EVIDENCE.md" "$README" \
  || fail "README must link the beta evidence runbook"
grep -q "tests/installer-branding-smoke.sh" "$README" \
  || fail "README must mention installer branding smoke coverage"
grep -q "Developer ID signing/notarization remains tracked in #64" "$README" \
  || fail "README must keep signing/notarization scoped to #64"

echo "PASS: README release-readiness positioning is conservative"
