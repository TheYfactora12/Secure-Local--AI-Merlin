#!/usr/bin/env bash
# Smoke-test gitleaks configuration without committing a secret fixture.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "${STACK_DIR}/.gitleaks.toml" ]] || fail ".gitleaks.toml missing"
grep -q "useDefault = true" "${STACK_DIR}/.gitleaks.toml" \
  || fail ".gitleaks.toml must extend default gitleaks rules"
grep -q "gitleaks-scan:" "${STACK_DIR}/.github/workflows/ci.yml" \
  || fail "CI gitleaks-scan job missing"
grep -q "zricethezav/gitleaks:v8.24.3" "${STACK_DIR}/.github/workflows/ci.yml" \
  || fail "CI gitleaks image pin missing"

cat > "${TMP_DIR}/leak.txt" <<'LEAK'
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
LEAK

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "SKIP: gitleaks CLI not installed locally; CI gitleaks gate is configured"
  exit 0
fi

set +e
gitleaks detect \
  --no-git \
  --source "$TMP_DIR" \
  --config "${STACK_DIR}/.gitleaks.toml" \
  --no-banner \
  --redact \
  --exit-code 9 >/dev/null 2>&1
STATUS=$?
set -e

[[ "$STATUS" -eq 9 ]] || fail "gitleaks did not detect fake AWS key fixture"

echo "PASS: gitleaks detects fake secrets and CI gate is configured"
