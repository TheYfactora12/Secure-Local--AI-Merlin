#!/usr/bin/env bash
# Static checks for the Home AI Elite uninstaller.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_UNINSTALL="${ROOT_DIR}/scripts/uninstall.sh"
PKG_UNINSTALL="${ROOT_DIR}/pkg/scripts/uninstall.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for file in "$ROOT_UNINSTALL" "$PKG_UNINSTALL"; do
  [[ -f "$file" ]] || fail "missing uninstaller: $file"
  bash -n "$file" || fail "shell syntax failed: $file"
done

bash "$PKG_UNINSTALL" --help >/dev/null \
  || fail "uninstaller help failed"

if bash "$PKG_UNINSTALL" --unknown >/tmp/home-ai-uninstall-unknown.out 2>&1; then
  fail "uninstaller accepted an unknown option"
fi
grep -q 'unknown option' /tmp/home-ai-uninstall-unknown.out \
  || fail "uninstaller unknown option is not actionable"

dry_run_output="$(bash "$PKG_UNINSTALL" --dry-run --yes --keep-files --keep-receipt 2>&1)"
grep -q 'Stopping services without removing Docker volumes' <<< "$dry_run_output" \
  || fail "dry-run does not stop services without volume deletion by default"
grep -q 'Keeping install directories because --keep-files was set' <<< "$dry_run_output" \
  || fail "dry-run does not honor --keep-files"
grep -q 'Keeping pkgutil receipt because --keep-receipt was set' <<< "$dry_run_output" \
  || fail "dry-run does not honor --keep-receipt"

grep -q -- '--remove-data' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose explicit data removal"
grep -q 'Ollama models were not removed' "$PKG_UNINSTALL" \
  || fail "uninstaller does not document preserving Ollama models"
grep -q 'com.homeai.backup' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove backup launchd agent"
grep -q 'com.homeai.merlin-status-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove Merlin status API launchd agent"

echo "PASS: uninstaller is guarded and testable"
