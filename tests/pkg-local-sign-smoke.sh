#!/usr/bin/env bash
# Static checks for local/self-signed package signing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIGNER="${STACK_DIR}/scripts/sign-pkg.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$SIGNER" ]] || fail "missing local signing script"
bash -n "$SIGNER"

HELP="$(bash "$SIGNER" --help)"
echo "$HELP" | grep -q 'Merlin AI Local Signing' \
  || fail "sign-pkg help does not document default local signing identity"
echo "$HELP" | grep -q -- '--keychain <path>' \
  || fail "sign-pkg help does not document keychain override"
echo "$HELP" | grep -q 'right-click -> Open' \
  || fail "sign-pkg help does not document self-signed Gatekeeper behavior"
echo "$HELP" | grep -q 'installer-signing identity' \
  || fail "sign-pkg help does not document installer-signing identity requirement"

set +e
UNKNOWN_OUTPUT="$(bash "$SIGNER" --definitely-not-real 2>&1)"
UNKNOWN_STATUS=$?
set -e
[[ "$UNKNOWN_STATUS" -ne 0 ]] || fail "sign-pkg accepted an unknown option"
echo "$UNKNOWN_OUTPUT" | grep -q 'Unknown option' \
  || fail "sign-pkg unknown option error is not actionable"

grep -q 'productsign "${sign_args\[@\]}" "$INPUT_PKG" "$OUTPUT_PKG"' "$SIGNER" \
  || fail "sign-pkg does not call productsign with the selected identity"
grep -q -- '--timestamp=none' "$SIGNER" \
  || fail "sign-pkg does not disable timestamping for local self-signed signing"
grep -q -- '--keychain "$KEYCHAIN"' "$SIGNER" \
  || fail "sign-pkg does not pass explicit keychain to productsign"
grep -q 'pkgutil --check-signature "$OUTPUT_PKG"' "$SIGNER" \
  || fail "sign-pkg does not verify the signed package"
grep -q 'security find-identity -v -p basic' "$SIGNER" \
  || fail "sign-pkg does not verify the local keychain identity"
grep -q 'Build it first: bash pkg/build-pkg.sh' "$SIGNER" \
  || fail "sign-pkg does not give a build hint when input package is missing"

echo "PASS: local package signing wrapper is guarded"
