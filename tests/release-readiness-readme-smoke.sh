#!/usr/bin/env bash
# Static smoke test for user-facing release-readiness positioning.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="${ROOT_DIR}/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "# Merlin AI — Your Private AI Stack for macOS" "$README" \
  || fail "README must use the Merlin AI product heading"
grep -q "Merlin AI" "$README" \
  || fail "README must show Merlin AI as product name"
grep -q "Your private AI. On your Mac. Forever." "$README" \
  || fail "README must lead with the Merlin AI tagline"
grep -q "Mac with Apple Silicon" "$README" \
  || fail "README must explain Apple Silicon requirement"
grep -q "Nothing leaves this Mac" "$README" \
  || fail "README must state local privacy in plain English"
grep -q "First 5 Minutes" "$README" \
  || fail "README must explain the first-run user path"
grep -q "Wait for the warming card" "$README" \
  || fail "README must match dashboard warming onboarding"
grep -q "See Details" "$README" \
  || fail "README must explain the System recovery path"
grep -q "tail -n 120 /tmp/merlin-ai-install.log" "$README" \
  || fail "README must include plain-English install log recovery evidence"
grep -q "not public beta" "$README" \
  || fail "README must not overclaim Public Beta readiness"
grep -q "TRUSTED_LOCAL_BETA_EVIDENCE.md" "$README" \
  || fail "README must link the beta evidence runbook"
grep -q "bash pkg/scripts/uninstall.sh --purge-all" "$README" \
  || fail "README must document full purge uninstall"

echo "PASS: README release-readiness positioning is conservative"
