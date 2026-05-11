#!/usr/bin/env bash
# Static checks for the Merlin AI installer/downloader brand surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -s "${STACK_DIR}/pkg/resources/merlin-ai-logo.png" ]] \
  || fail "Merlin installer logo resource is missing or empty"

grep -q 'Merlin AI' "${STACK_DIR}/install.sh" \
  || fail "terminal installer header does not show Merlin AI"
grep -q 'Your private AI. On your Mac. Forever.' "${STACK_DIR}/install.sh" \
  || fail "terminal installer header missing Merlin AI tagline"
grep -q 'Local-first AI for owned hardware. Cloud off by default.' "${STACK_DIR}/install.sh" \
  || fail "terminal installer header missing local-first positioning"
grep -q 'MERLIN AI INSTALLED' "${STACK_DIR}/install.sh" \
  || fail "terminal installer final banner does not use Merlin AI installed language"
old_home="Home"
old_product="${old_home} AI ""Elite"
old_upper="HOME AI ""ELITE"
old_wizard="Wizard ""AI"
old_wizard_upper="WIZARD ""AI"
if grep -Eq "${old_product}|${old_upper}|${old_wizard}|${old_wizard_upper}" "${STACK_DIR}/install.sh"; then
  fail "installer still contains stale retired branding"
fi

grep -q 'Merlin AI' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome missing Merlin AI brand"
grep -q 'Your private AI. On your Mac. Forever.' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome missing Merlin AI tagline"
grep -q 'merlin-ai-logo.png' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome does not reference Merlin logo resource"
grep -q 'No cloud' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome does not communicate no-cloud default"

grep -q 'Merlin AI — First Run' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing Merlin AI first-run heading"
grep -q 'Merlin Dashboard' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme does not point users to Merlin Dashboard"
grep -q 'http://localhost:8888' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing Merlin Dashboard URL"
grep -q 'wizard merlin status' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing first readiness command"

if grep -q 'http://localhost:3001' "${STACK_DIR}/pkg/resources/readme.html"; then
  fail "package readme still advertises stale Open WebUI port 3001"
fi
if grep -q 'Perplexica Search.*http://localhost:3000' "${STACK_DIR}/pkg/resources/readme.html"; then
  fail "package readme still advertises stale Perplexica port 3000"
fi

grep -q 'Merlin AI — Installation Complete!' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Merlin AI completion heading"
grep -q 'Your private AI. On your Mac. Forever.' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Merlin AI tagline"
grep -q 'Dashboard   → http://localhost:8888' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Merlin Dashboard service"
grep -q 'HOME_AI_SKIP_MODEL_PULLS=true' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall no longer disables model pulls"
grep -q 'bash install.sh --profile core --skip-model-pulls --non-interactive' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall no longer uses protected core installer path"
grep -q '/tmp/merlin-ai-install.log' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall install log path does not use Merlin AI branding"
grep -q '/tmp/merlin-ai-install.log' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme install log path does not use Merlin AI branding"

[[ -x "${STACK_DIR}/scripts/install-pkg-local.sh" ]] \
  || fail "local package install helper is missing or not executable"
bash -n "${STACK_DIR}/scripts/install-pkg-local.sh" \
  || fail "local package install helper has shell syntax errors"
grep -q 'Merlin AI needs your Mac administrator password' "${STACK_DIR}/scripts/install-pkg-local.sh" \
  || fail "local package install helper does not explain admin password prompt"
grep -q 'Merlin does not store it' "${STACK_DIR}/scripts/install-pkg-local.sh" \
  || fail "local package install helper does not reassure password handling"

echo "PASS: Merlin AI installer branding surface is valid"
