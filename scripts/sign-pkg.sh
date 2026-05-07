#!/usr/bin/env bash
# Sign a locally built Home AI Elite .pkg with a local/self-signed identity.
#
# This is for trusted local/test distribution. It does not notarize and it does
# not remove Gatekeeper warnings for broad public distribution.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

IDENTITY="${HOME_AI_LOCAL_SIGNING_IDENTITY:-Home AI Elite Local Signing}"
KEYCHAIN="${HOME_AI_LOCAL_SIGNING_KEYCHAIN:-}"
VERSION=""
INPUT_PKG=""
OUTPUT_PKG=""

usage() {
  cat <<'USAGE'
Usage: bash scripts/sign-pkg.sh [options]

Options:
  --version <version>   Package version, for example 1.0.0 or 0.8.6.
  --input <path>        Unsigned input .pkg. Defaults to home-ai-elite-<version>.pkg.
  --output <path>       Signed output .pkg. Defaults to home-ai-elite-v<version>.pkg.
  --identity <name>     Signing identity name. Defaults to "Home AI Elite Local Signing".
  --keychain <path>     Optional keychain containing the local signing identity.
  -h, --help            Show this help.

Create the local signing identity first:
  Keychain Access -> Certificate Assistant -> Create a Certificate
  Name: Home AI Elite Local Signing
  Identity Type: Self Signed Root
  The identity must be usable by productsign as an installer-signing identity.
  If a command-line identity is used, trust the self-signed certificate in the
  signing keychain before running this script.

Then build and sign:
  bash pkg/build-pkg.sh
  bash scripts/sign-pkg.sh --version 1.0.0

This is local/self-signed packaging. macOS may still require right-click -> Open.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      shift
      [[ -n "${1:-}" ]] || { echo "ERROR: --version requires a value" >&2; exit 2; }
      VERSION="$1"
      ;;
    --input)
      shift
      [[ -n "${1:-}" ]] || { echo "ERROR: --input requires a path" >&2; exit 2; }
      INPUT_PKG="$1"
      ;;
    --output)
      shift
      [[ -n "${1:-}" ]] || { echo "ERROR: --output requires a path" >&2; exit 2; }
      OUTPUT_PKG="$1"
      ;;
    --identity)
      shift
      [[ -n "${1:-}" ]] || { echo "ERROR: --identity requires a value" >&2; exit 2; }
      IDENTITY="$1"
      ;;
    --keychain)
      shift
      [[ -n "${1:-}" ]] || { echo "ERROR: --keychain requires a path" >&2; exit 2; }
      KEYCHAIN="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(git -C "$STACK_DIR" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
fi

if [[ -z "$VERSION" ]]; then
  echo "ERROR: package version could not be detected. Pass --version <version>." >&2
  exit 1
fi

INPUT_PKG="${INPUT_PKG:-${STACK_DIR}/home-ai-elite-${VERSION}.pkg}"
OUTPUT_PKG="${OUTPUT_PKG:-${STACK_DIR}/home-ai-elite-v${VERSION}.pkg}"

for tool in productsign pkgutil security; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: required macOS tool not found: $tool" >&2
    exit 1
  }
done

[[ -f "$INPUT_PKG" ]] || {
  echo "ERROR: input package not found: $INPUT_PKG" >&2
  echo "Build it first: bash pkg/build-pkg.sh" >&2
  exit 1
}

identity_check=(security find-identity -v -p basic)
if [[ -n "$KEYCHAIN" ]]; then
  [[ -f "$KEYCHAIN" ]] || {
    echo "ERROR: signing keychain not found: $KEYCHAIN" >&2
    exit 1
  }
  identity_check+=("$KEYCHAIN")
fi

if ! "${identity_check[@]}" | grep -Fq "$IDENTITY"; then
  echo "ERROR: signing identity not found in keychain: $IDENTITY" >&2
  echo "Create or import a trusted self-signed installer-signing identity first." >&2
  exit 1
fi

rm -f "$OUTPUT_PKG"
sign_args=(--sign "$IDENTITY" --timestamp=none)
if [[ -n "$KEYCHAIN" ]]; then
  sign_args=(--keychain "$KEYCHAIN" "${sign_args[@]}")
fi

productsign "${sign_args[@]}" "$INPUT_PKG" "$OUTPUT_PKG"
pkgutil --check-signature "$OUTPUT_PKG"

echo "Signed package: $OUTPUT_PKG"
