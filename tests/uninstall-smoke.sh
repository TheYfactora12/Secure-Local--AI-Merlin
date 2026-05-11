#!/usr/bin/env bash
# Static checks for the Merlin AI uninstaller.
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
grep -q -- '--purge-all' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose full purge mode"
grep -q -- '--purge-models' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose Merlin model purge mode"
grep -q -- '--purge-images' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose Docker image purge mode"
grep -q 'known Merlin-recommended Ollama models' "$PKG_UNINSTALL" \
  || fail "uninstaller does not document Merlin-managed model cleanup"
grep -q 'Docker Desktop, Homebrew, and the Ollama app/binary were not removed' "$PKG_UNINSTALL" \
  || fail "uninstaller does not clearly separate app purge from dependency removal"
grep -q 'com.homeai.backup' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove backup launchd agent"
grep -q 'com.homeai.merlin-status-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove Merlin status API launchd agent"
grep -q 'com.homeai.merlin-task-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove Merlin task API launchd agent"
grep -q 'sudo -n true' "$PKG_UNINSTALL" \
  || fail "uninstaller does not check sudo availability non-interactively"
grep -q 'Skipped .*admin privileges are required' "$PKG_UNINSTALL" \
  || fail "uninstaller does not warn instead of hard-failing on sudo cleanup"
grep -q 'Run manually if needed' "$PKG_UNINSTALL" \
  || fail "uninstaller does not print manual admin cleanup commands"
grep -q 'launchctl print' "$PKG_UNINSTALL" \
  || fail "uninstaller does not detect loaded launchd agents before bootout"
grep -q 'Could not unload launchd agent' "$PKG_UNINSTALL" \
  || fail "uninstaller does not warn when launchd bootout fails"
grep -q 'launchctl bootout gui/' "$PKG_UNINSTALL" \
  || fail "uninstaller does not print manual launchd bootout command"
grep -q 'docker compose -f .* down --volumes --remove-orphans' "$PKG_UNINSTALL" \
  || fail "uninstaller does not print manual Docker volume cleanup command"
grep -q 'docker compose -f .* down --volumes --rmi all --remove-orphans' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove stack images in purge mode"
grep -q 'Run manually if needed after Docker starts' "$PKG_UNINSTALL" \
  || fail "uninstaller does not print manual Docker cleanup hint when engine is down"

purge_dry_run_output="$(bash "$PKG_UNINSTALL" --dry-run --yes --purge-all --keep-files --keep-receipt 2>&1)"
grep -q 'Stopping services and removing Docker volumes and stack images' <<< "$purge_dry_run_output" \
  || fail "purge-all dry-run does not remove Docker volumes and images"
grep -q 'docker compose .* --volumes --rmi all --remove-orphans' <<< "$purge_dry_run_output" \
  || fail "purge-all dry-run does not show full Docker cleanup command"
grep -q 'Removing Merlin-recommended Ollama models' <<< "$purge_dry_run_output" \
  || fail "purge-all dry-run does not remove Merlin-recommended Ollama models"
grep -q 'ollama rm qwen2.5:7b' <<< "$purge_dry_run_output" \
  || fail "purge-all dry-run does not remove low-tier Qwen model"
grep -q 'ollama rm nomic-embed-text' <<< "$purge_dry_run_output" \
  || fail "purge-all dry-run does not remove embedding model"

echo "PASS: uninstaller is guarded and testable"
