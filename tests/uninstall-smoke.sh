#!/usr/bin/env bash
# Static checks for the Merlin AI uninstaller.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_UNINSTALL="${ROOT_DIR}/scripts/uninstall.sh"
PKG_UNINSTALL="${ROOT_DIR}/pkg/scripts/uninstall.sh"
INSTALLER="${ROOT_DIR}/install.sh"
README="${ROOT_DIR}/README.md"
PKG_README="${ROOT_DIR}/pkg/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for file in "$ROOT_UNINSTALL" "$PKG_UNINSTALL"; do
  [[ -f "$file" ]] || fail "missing uninstaller: $file"
  bash -n "$file" || fail "shell syntax failed: $file"
done

grep -q 'MERLIN_INSTALL_MANIFEST=' "$INSTALLER" \
  || fail "installer does not define Merlin install manifest path"
grep -q 'write_install_manifest' "$INSTALLER" \
  || fail "installer does not write dependency manifest"
grep -q 'installed_by_merlin' "$INSTALLER" \
  || fail "installer manifest does not record Merlin-installed dependencies"
grep -q '\.merlin/install-manifest\.json' "$README" \
  || fail "README does not document install manifest"
grep -q -- '--purge-dependencies' "$README" \
  || fail "README does not document dependency purge preview"
grep -q '\.merlin/install-manifest\.json' "$PKG_README" \
  || fail "pkg README does not document install manifest"

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

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/home"
cat > "$tmp_dir/bin/pkgutil" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$tmp_dir/bin/pkgutil"

receipt_dry_run_output="$(
  HOME="$tmp_dir/home" \
  PATH="$tmp_dir/bin:$PATH" \
  bash "$PKG_UNINSTALL" --dry-run --yes --keep-files 2>&1
)"
grep -q 'sudo pkgutil --forget com.merlin.ai' <<< "$receipt_dry_run_output" \
  || fail "dry-run does not forget Merlin AI package receipt"
grep -q 'sudo pkgutil --forget com.homeai.elite' <<< "$receipt_dry_run_output" \
  || fail "dry-run does not forget legacy Home AI package receipt"

grep -q -- '--remove-data' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose explicit data removal"
grep -q -- '--purge-all' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose full purge mode"
grep -q -- '--purge-models' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose Merlin model purge mode"
grep -q -- '--purge-images' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose Docker image purge mode"
grep -q -- '--purge-dependencies' "$PKG_UNINSTALL" \
  || fail "uninstaller does not expose explicit dependency purge mode"
grep -q -- '--i-understand-shared-tools' "$PKG_UNINSTALL" \
  || fail "uninstaller does not require shared-tool confirmation"
grep -q 'known Merlin-recommended Ollama models' "$PKG_UNINSTALL" \
  || fail "uninstaller does not document Merlin-managed model cleanup"
grep -q 'Docker Desktop, Homebrew, and the Ollama app/binary were not removed' "$PKG_UNINSTALL" \
  || fail "uninstaller does not clearly separate app purge from dependency removal"
grep -q 'INSTALL_MANIFEST=' "$PKG_UNINSTALL" \
  || fail "uninstaller does not read Merlin install manifest"
grep -q 'installed_by_merlin' "$PKG_UNINSTALL" \
  || fail "uninstaller dependency purge is not manifest-gated"
grep -q 'refusing to remove shared dependencies' "$PKG_UNINSTALL" \
  || fail "uninstaller does not fail closed when dependency manifest is missing"
grep -q 'com.merlin.backup' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove current backup launchd agent"
grep -q 'com.homeai.backup' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove legacy backup launchd agent"
grep -q 'com.merlin.status-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove current Merlin status API launchd agent"
grep -q 'com.merlin.task-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove current Merlin task API launchd agent"
grep -q 'com.homeai.merlin-status-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove legacy Merlin status API launchd agent"
grep -q 'com.homeai.merlin-task-api' "$PKG_UNINSTALL" \
  || fail "uninstaller does not remove legacy Merlin task API launchd agent"
grep -q 'sudo -n true' "$PKG_UNINSTALL" \
  || fail "uninstaller does not check sudo availability non-interactively"
grep -q 'Skipped .*admin privileges are required' "$PKG_UNINSTALL" \
  || fail "uninstaller does not warn instead of hard-failing on sudo cleanup"
grep -q 'Run manually if needed' "$PKG_UNINSTALL" \
  || fail "uninstaller does not print manual admin cleanup commands"
grep -q 'PKG_ID="com.merlin.ai"' "$PKG_UNINSTALL" \
  || fail "uninstaller must use Merlin AI package receipt as current identifier"
grep -q 'LEGACY_PKG_IDS' "$PKG_UNINSTALL" \
  || fail "uninstaller must keep a legacy package receipt cleanup list"
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

missing_manifest_home="$tmp_dir/missing-manifest-home"
mkdir -p "$missing_manifest_home"
dependency_dry_run_output="$(
  HOME="$missing_manifest_home" \
  bash "$PKG_UNINSTALL" --dry-run --yes --purge-dependencies --keep-files --keep-receipt 2>&1
)"
grep -q 'Evaluating dependency purge' <<< "$dependency_dry_run_output" \
  || fail "dependency purge dry-run does not evaluate manifest"
grep -q 'refusing to remove shared dependencies' <<< "$dependency_dry_run_output" \
  || fail "dependency purge dry-run does not fail closed without manifest"

cat > "$tmp_dir/bin/docker" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  info) exit 0 ;;
  compose) exit 0 ;;
  *) exit 0 ;;
esac
SH
cat > "$tmp_dir/bin/ollama" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  list)
    cat <<'MODELS'
NAME                       ID              SIZE      MODIFIED
qwen2.5:7b                 fake            4.7 GB    now
nomic-embed-text:latest    fake            274 MB    now
MODELS
    ;;
  rm)
    printf '%s\n' "${2:-}" >> "${OLLAMA_RM_LOG:?}"
    ;;
esac
SH
chmod +x "$tmp_dir/bin/docker" "$tmp_dir/bin/ollama"

mkdir -p "$tmp_dir/home/.merlin"
cat > "$tmp_dir/home/.merlin/install-manifest.json" <<'JSON'
{
  "product": "Merlin AI",
  "manifest_version": 1,
  "dependencies": {
    "homebrew": {"installed_by_merlin": false},
    "docker_desktop": {"installed_by_merlin": false},
    "ollama": {"installed_by_merlin": true}
  }
}
JSON

manifest_dependency_output="$(
  HOME="$tmp_dir/home" \
  PATH="$tmp_dir/bin:$PATH" \
  bash "$PKG_UNINSTALL" --dry-run --yes --purge-dependencies --keep-files --keep-receipt 2>&1
)"
grep -q 'brew uninstall ollama' <<< "$manifest_dependency_output" \
  || fail "manifest-gated dependency dry-run does not remove Merlin-installed Ollama"
grep -q 'Keeping Docker Desktop; manifest does not mark it installed by Merlin' <<< "$manifest_dependency_output" \
  || fail "manifest-gated dependency dry-run does not keep pre-existing Docker"
grep -q 'Keeping Homebrew; manifest does not mark it installed by Merlin' <<< "$manifest_dependency_output" \
  || fail "manifest-gated dependency dry-run does not keep pre-existing Homebrew"

OLLAMA_RM_LOG="$tmp_dir/ollama-rm.log" \
HOME="$tmp_dir/home" \
PATH="$tmp_dir/bin:$PATH" \
bash "$PKG_UNINSTALL" --yes --purge-models --keep-files --keep-receipt >/tmp/home-ai-uninstall-fake.out 2>&1 \
  || fail "uninstaller should support fake local purge test"

grep -qx 'qwen2.5:7b' "$tmp_dir/ollama-rm.log" \
  || fail "uninstaller fake purge did not remove tagged qwen model"
grep -qx 'nomic-embed-text' "$tmp_dir/ollama-rm.log" \
  || fail "uninstaller fake purge did not remove untagged embedding model listed as :latest"

echo "PASS: uninstaller is guarded and testable"
