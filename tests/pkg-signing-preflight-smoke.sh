#!/usr/bin/env bash
# Static checks for package signing and notarization preflight behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILDER="${STACK_DIR}/pkg/build-pkg.sh"
PREFLIGHT="${STACK_DIR}/pkg/release-preflight.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

bash -n "$BUILDER" "$PREFLIGHT"

HELP="$(bash "$BUILDER" --help)"
echo "$HELP" | grep -q 'Usage: bash pkg/build-pkg.sh' \
  || fail "build-pkg help missing usage"
echo "$HELP" | grep -q 'DEVELOPER_ID_INSTALLER=' \
  || fail "build-pkg help does not document signing identity env"
echo "$HELP" | grep -q 'PACKAGE_SIGNING_KEYCHAIN=' \
  || fail "build-pkg help does not document signing keychain env"
echo "$HELP" | grep -q 'PACKAGE_SIGNING_TIMESTAMP=' \
  || fail "build-pkg help does not document signing timestamp env"

set +e
UNKNOWN_OUTPUT="$(bash "$BUILDER" --definitely-not-real 2>&1)"
UNKNOWN_STATUS=$?
set -e
[[ "$UNKNOWN_STATUS" -ne 0 ]] || fail "build-pkg accepted an unknown option"
echo "$UNKNOWN_OUTPUT" | grep -q 'Unknown option' \
  || fail "build-pkg unknown option error is not actionable"

grep -q 'DEVELOPER_ID_INSTALLER is still the placeholder value' "$BUILDER" \
  || fail "build-pkg does not reject placeholder signing identity"
grep -q 'Developer ID Installer identity not found' "$BUILDER" \
  || fail "build-pkg does not verify keychain signing identity"
grep -q 'PACKAGE_SIGNING_KEYCHAIN not found' "$BUILDER" \
  || fail "build-pkg does not validate explicit signing keychain path"
grep -q 'PACKAGE_SIGNING_TIMESTAMP must be' "$BUILDER" \
  || fail "build-pkg does not validate signing timestamp mode"
grep -q 'Signing component with' "$BUILDER" \
  || fail "build-pkg does not sign the component package"
grep -q 'APPLE_APP_PASSWORD must be set for notarization' "$BUILDER" \
  || fail "build-pkg does not guard notarization password"

PREFLIGHT_HELP="$(bash "$PREFLIGHT" --help)"
echo "$PREFLIGHT_HELP" | grep -q -- '--require-signing' \
  || fail "release preflight help does not document --require-signing"
grep -q 'without printing secret values' "$PREFLIGHT" \
  || fail "release preflight intent does not mention secret-safe checks"
grep -q 'security find-identity' "$PREFLIGHT" \
  || fail "release preflight does not check signing identities"
grep -q 'xcrun -f "$1"' "$PREFLIGHT" \
  || fail "release preflight does not check xcrun tools"

echo "PASS: package signing preflight is guarded"
