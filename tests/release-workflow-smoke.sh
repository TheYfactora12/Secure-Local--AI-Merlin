#!/usr/bin/env bash
# Static checks for the GitHub release workflow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOW="${STACK_DIR}/.github/workflows/release.yml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$WORKFLOW" ]] || fail "Missing release workflow"

grep -q 'tags:' "$WORKFLOW" \
  || fail "release workflow is not tag-gated"
grep -q 'workflow_dispatch:' "$WORKFLOW" \
  || fail "release workflow is not manually dispatchable"
if grep -q 'branches: \[ main \]' "$WORKFLOW"; then
  fail "release workflow still auto-releases every main push"
fi

grep -q 'runs-on: macos-latest' "$WORKFLOW" \
  || fail "release workflow does not build package on macOS"
grep -q 'bash tests/pkg-readiness-smoke.sh' "$WORKFLOW" \
  || fail "release workflow does not run package readiness checks"
grep -q 'bash pkg/release-preflight.sh' "$WORKFLOW" \
  || fail "release workflow does not run package release preflight"
grep -q 'bash pkg/build-pkg.sh' "$WORKFLOW" \
  || fail "release workflow does not build the package"
grep -q 'pkgutil --payload-files' "$WORKFLOW" \
  || fail "release workflow does not inspect package payload"
grep -q 'shasum -a 256' "$WORKFLOW" \
  || fail "release workflow does not generate checksums"
grep -q 'actions/upload-artifact@v4' "$WORKFLOW" \
  || fail "release workflow does not upload package artifacts"
grep -q 'softprops/action-gh-release@v2' "$WORKFLOW" \
  || fail "release workflow does not create GitHub releases"
grep -q 'Package is currently unsigned in CI' "$WORKFLOW" \
  || fail "release workflow does not disclose unsigned CI package status"
grep -q 'prerelease: true' "$WORKFLOW" \
  || fail "release workflow should mark unsigned package releases as prerelease"

echo "PASS: release workflow is artifact-based and gated"
