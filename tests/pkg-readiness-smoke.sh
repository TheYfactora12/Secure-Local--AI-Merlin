#!/usr/bin/env bash
# Static package-readiness checks for the macOS .pkg path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for file in \
  "${STACK_DIR}/pkg/build-pkg.sh" \
  "${STACK_DIR}/pkg/scripts/preinstall" \
  "${STACK_DIR}/pkg/scripts/postinstall" \
  "${STACK_DIR}/pkg/scripts/uninstall.sh"; do
  [[ -f "$file" ]] || fail "Missing package file: $file"
  bash -n "$file" || fail "Shell syntax failed: $file"
done

head -n 1 "${STACK_DIR}/pkg/scripts/preinstall" | grep -q '^#!/usr/bin/env bash$' \
  || fail "preinstall shebang is not on the first line"
head -n 1 "${STACK_DIR}/pkg/scripts/postinstall" | grep -q '^#!/usr/bin/env bash$' \
  || fail "postinstall shebang is not on the first line"

grep -q 'HOME_AI_SKIP_MODEL_PULLS=true' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not disable model pulls"
grep -q 'bash install.sh --profile core --skip-model-pulls --non-interactive' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not run the core installer path"
grep -q 'Install log writable by' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not hand log ownership to the installing user"
grep -q 'run_as_user' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not use a dedicated user command runner"
grep -q 'rsync -a' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall must use filtered rsync copy, not raw cp -R"
grep -q -- "--exclude='.wizard-bootstrapped'" "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall user copy does not exclude bootstrap marker"
grep -q -- "--exclude='logs/'" "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall user copy does not exclude logs"
if grep -q 'su -' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall still uses login su for user commands"
fi
if grep -q 'cp -R "$INSTALL_DIR" "$USER_INSTALL_DIR"' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall still uses raw cp -R for user install copy"
fi
if grep -q 'DOCKER_CONFIG=' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall should not override Docker Desktop config"
fi
grep -q 'tests/core-live-smoke.sh' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps do not point to core live smoke"

if grep -q 'Perplexica  → http://localhost:3002' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall still advertises optional search as default service"
fi
if grep -q 'OpenHands   → http://localhost:3003' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall still advertises optional coding as default service"
fi
if grep -q 'n8n         → http://localhost:5678' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall still advertises optional automation as default service"
fi

grep -q -- "--exclude='.env'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude .env"
grep -q -- "--exclude='.venv-test/'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude local test virtualenv"
grep -q -- "--exclude='.pytest_cache/'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude pytest cache"
grep -q -- "--exclude='.wizard-bootstrapped'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude bootstrap marker"
grep -q -- "--exclude='.DS_Store'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude macOS Finder metadata"
grep -q -- "--exclude='certs/'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude generated certs"
grep -q -- "--exclude='logs/'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude runtime logs"
grep -q -- "--exclude='docs/release/evidence/assets/'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude generated evidence screenshots"
grep -Fq -- "--exclude='*.pkg'" "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not exclude pkg artifacts"
grep -q 'APPLE_APP_PASSWORD must be set for notarization' "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder does not guard notarization credentials"
grep -q 'PKG_ID="com.merlin.ai"' "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder must use Merlin AI package identifier"
grep -q 'if \[\[ "$SIGN" == true \]\]; then' "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder must guard signed and unsigned pkgbuild paths separately"
awk '
  /build_component_pkg\(\)/ { in_component=1 }
  /^}/ && in_component { in_component=0 }
  in_component && /^[[:space:]]*else$/ { in_unsigned=1 }
  in_unsigned && /\$\{sign_args\[@\]\}/ { bad=1 }
  in_unsigned && /"\$\{component_pkg\}"/ { found=1 }
  in_unsigned && /^[[:space:]]*fi$/ { in_unsigned=0 }
  END {
    if (bad || !found) exit 1
  }
' "${STACK_DIR}/pkg/build-pkg.sh" \
  || fail "package builder unsigned component path must not expand sign_args under set -u"
if grep -q 'PKG_ID="com.homeai.elite"' "${STACK_DIR}/pkg/build-pkg.sh"; then
  fail "package builder still uses retired Home AI package identifier"
fi
grep -q -- '--dry-run' "${STACK_DIR}/pkg/scripts/uninstall.sh" \
  || fail "package uninstaller does not support dry-run"
grep -q -- '--remove-data' "${STACK_DIR}/pkg/scripts/uninstall.sh" \
  || fail "package uninstaller does not require explicit data removal"
grep -q 'PKG_ID="com.merlin.ai"' "${STACK_DIR}/pkg/scripts/uninstall.sh" \
  || fail "package uninstaller must forget the Merlin AI package identifier"
grep -q 'com.homeai.elite' "${STACK_DIR}/pkg/scripts/uninstall.sh" \
  || fail "package uninstaller must still clean legacy Home AI package receipts"

echo "PASS: package readiness checks are valid"
