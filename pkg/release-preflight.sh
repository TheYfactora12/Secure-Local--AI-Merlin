#!/usr/bin/env bash
# Preflight checks for signed/notarized macOS package releases.
set -euo pipefail

REQUIRE_SIGNING=false

usage() {
  cat <<'USAGE'
Usage: bash pkg/release-preflight.sh [--require-signing]

Checks local package build tools, signing identity availability, and notarization
environment variables without printing secret values.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-signing)
      REQUIRE_SIGNING=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

pass() { echo "[PASS] $*"; }
warn() { echo "[WARN] $*" >&2; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 && pass "$1 available" || fail "$1 missing"
}

require_xcrun_tool() {
  xcrun -f "$1" >/dev/null 2>&1 && pass "$1 available" || fail "$1 missing"
}

require_cmd pkgbuild
require_cmd productbuild
require_cmd security
require_xcrun_tool notarytool
require_xcrun_tool stapler

IDENTITY_COUNT="$(security find-identity -v -p basic 2>/dev/null | awk '/Developer ID Installer/ {count++} END {print count+0}')"
if [[ "$IDENTITY_COUNT" -gt 0 ]]; then
  pass "Developer ID Installer identity available"
else
  warn "No Developer ID Installer identity found in keychain"
fi

missing_env=0
for key in DEVELOPER_ID_INSTALLER APPLE_ID APPLE_TEAM_ID APPLE_APP_PASSWORD; do
  if [[ -n "${!key:-}" ]]; then
    pass "$key set"
  else
    warn "$key not set"
    missing_env=$((missing_env + 1))
  fi
done

if [[ "$REQUIRE_SIGNING" == true ]]; then
  [[ "$IDENTITY_COUNT" -gt 0 ]] || fail "Signing identity is required"
  [[ "$missing_env" -eq 0 ]] || fail "Signing/notarization environment is incomplete"
fi

if [[ "$IDENTITY_COUNT" -gt 0 && "$missing_env" -eq 0 ]]; then
  pass "Release signing/notarization preflight complete"
else
  warn "Unsigned package builds are available; signed/notarized release is not ready on this machine"
fi
