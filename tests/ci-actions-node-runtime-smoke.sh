#!/usr/bin/env bash
# Static smoke test for GitHub Actions runtime-version hardening.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_DIR="${ROOT_DIR}/.github/workflows"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -R "actions/setup-python@v6" "$WORKFLOW_DIR" >/dev/null \
  || fail "CI must use actions/setup-python@v6 for Node runtime hardening"

if grep -R "actions/setup-python@v5" "$WORKFLOW_DIR" >/dev/null; then
  fail "CI must not use actions/setup-python@v5; it emits Node 20 runtime warnings"
fi

if grep -R "node20" "$WORKFLOW_DIR" >/dev/null; then
  fail "Workflow must not pin or document Node 20 runtime usage"
fi

grep -q "merlin-staff-core-pytest" "${WORKFLOW_DIR}/ci.yml" \
  || fail "Python unit-test job must remain present"

grep -q "merlin-staff-core-pytest" "${WORKFLOW_DIR}/ci.yml" \
  && grep -q "ci-success" "${WORKFLOW_DIR}/ci.yml" \
  || fail "CI success gate must remain present"

echo "PASS: GitHub Actions Node runtime hardening smoke test passed"
