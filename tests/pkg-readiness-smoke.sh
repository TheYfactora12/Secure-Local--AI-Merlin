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
  "${STACK_DIR}/scripts/install-pkg-local.sh" \
  "${STACK_DIR}/scripts/run-pkg-install-verification.sh" \
  "${STACK_DIR}/scripts/verify-pkg-install.sh" \
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
grep -q 'eval_type_backport' "${STACK_DIR}/requirements-merlin.txt" \
  || fail "Merlin runtime requirements must support Pydantic typing on Python 3.9"
grep -q 'typing_extensions' "${STACK_DIR}/requirements-merlin.txt" \
  || fail "Merlin runtime requirements must support ParamSpec on Python 3.9"
grep -q 'from typing_extensions import ParamSpec' "${STACK_DIR}/merlin/policy_engine.py" \
  || fail "policy engine must import ParamSpec from typing_extensions for Python 3.9"
grep -q 'eval_type_backport' "${STACK_DIR}/install.sh" \
  || fail "installer dependency check must detect missing Python 3.9 typing backport"
grep -q 'bash install.sh --profile core --skip-model-pulls --non-interactive' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not run the core installer path"
grep -q 'Install log writable by' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not hand log ownership to the installing user"
grep -q 'run_as_user' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not use a dedicated user command runner"
grep -q 'run_as_user_gui' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not use a GUI-session user command runner"
grep -q 'launchctl asuser' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall must use GUI-session runner for GUI operations"
grep -q 'install_launchd_for_user' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not use explicit target-user launchd setup"
grep -q 'launchctl asuser "$INSTALLING_UID"' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall launchd setup must enter the installing user's GUI session"
grep -q 'MERLIN_LAUNCHD_UID' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall launchd setup must pass the installing user's uid"
grep -q 'Installing launchd auto-start agents into user GUI domain' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall does not document target-user launchd setup"
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
if grep -q 'skipping copy' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall must sync package code on reinstall, not skip existing runtime"
fi
if grep -q 'DOCKER_CONFIG=' "${STACK_DIR}/pkg/scripts/postinstall"; then
  fail "postinstall should not override Docker Desktop config"
fi
grep -q 'tests/core-live-smoke.sh' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps do not point to core live smoke"
grep -q '/tmp/merlin-ai-install.log' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall install log path is not Merlin-branded"
grep -q 'sudo -p "Merlin AI admin password: "' "${STACK_DIR}/scripts/install-pkg-local.sh" \
  || fail "local package installer does not use a clear Merlin password prompt"
grep -q 'Cannot ask for a password because this is not an interactive Terminal' "${STACK_DIR}/scripts/install-pkg-local.sh" \
  || fail "local package installer does not explain non-interactive admin prompt failure"
grep -Fq 'package receipt found: $PKG_ID' "${STACK_DIR}/scripts/verify-pkg-install.sh" \
  || fail "package verification script does not check package receipt"
grep -Fq 'launchd agent registered: $label' "${STACK_DIR}/scripts/verify-pkg-install.sh" \
  || fail "package verification script does not check launchd agents"
grep -q 'http://localhost:8765/healthz' "${STACK_DIR}/scripts/verify-pkg-install.sh" \
  || fail "package verification script does not check Merlin status API"
grep -q 'http://localhost:8766/status/routes' "${STACK_DIR}/scripts/verify-pkg-install.sh" \
  || fail "package verification script does not check Merlin task API"
grep -q 'This command only checks local state' "${STACK_DIR}/scripts/verify-pkg-install.sh" \
  || fail "package verification script does not explain non-destructive behavior"
grep -q 'Cannot run package install verification without an interactive Terminal' "${STACK_DIR}/scripts/run-pkg-install-verification.sh" \
  || fail "package install runner does not guard non-interactive password prompts"
grep -q 'scripts/install-pkg-local.sh' "${STACK_DIR}/scripts/run-pkg-install-verification.sh" \
  || fail "package install runner does not call the local package helper"
grep -q 'scripts/verify-pkg-install.sh' "${STACK_DIR}/scripts/run-pkg-install-verification.sh" \
  || fail "package install runner does not call the post-install verifier"
grep -q 'docs/release/evidence/local' "${STACK_DIR}/scripts/run-pkg-install-verification.sh" \
  || fail "package install runner does not write local evidence logs"
grep -q 'run-pkg-install-verification.sh merlin-ai-0.8.6.pkg' "${STACK_DIR}/pkg/README.md" \
  || fail "pkg README does not document guided package verification"

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
if rg -q '^from datetime import UTC' "${STACK_DIR}/merlin"; then
  fail "Merlin runtime modules must not import datetime.UTC; package runtime may use Python 3.9"
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
