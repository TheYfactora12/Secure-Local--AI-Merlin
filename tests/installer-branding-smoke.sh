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
grep -q 'Private Intelligence. Locally Owned.' "${STACK_DIR}/install.sh" \
  || fail "terminal installer header missing Merlin tagline"
grep -q 'Sovereign local-first AI command center' "${STACK_DIR}/install.sh" \
  || fail "terminal installer header missing local-first positioning"

grep -q 'Merlin AI' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome missing Merlin AI brand"
grep -q 'Private Intelligence. Locally Owned.' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome missing Merlin tagline"
grep -q 'merlin-ai-logo.png' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome does not reference Merlin logo resource"
grep -q 'No cloud' "${STACK_DIR}/pkg/resources/welcome.html" \
  || fail "package welcome does not communicate no-cloud default"

grep -q 'Merlin AI — First Run' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing Merlin first-run heading"
grep -q 'Wizard HQ' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme does not point users to Wizard HQ"
grep -q 'http://localhost:8888' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing Wizard HQ URL"
grep -q 'wizard merlin status' "${STACK_DIR}/pkg/resources/readme.html" \
  || fail "package readme missing first readiness command"

if grep -q 'http://localhost:3001' "${STACK_DIR}/pkg/resources/readme.html"; then
  fail "package readme still advertises stale Open WebUI port 3001"
fi
if grep -q 'Perplexica Search.*http://localhost:3000' "${STACK_DIR}/pkg/resources/readme.html"; then
  fail "package readme still advertises stale Perplexica port 3000"
fi

grep -q 'Merlin AI — Installation Complete!' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Merlin completion heading"
grep -q 'Private Intelligence. Locally Owned.' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Merlin tagline"
grep -q 'Wizard HQ   → http://localhost:8888' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall next steps missing Wizard HQ service"
grep -q 'HOME_AI_SKIP_MODEL_PULLS=true' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall no longer disables model pulls"
grep -q 'bash install.sh --profile core --skip-model-pulls --non-interactive' "${STACK_DIR}/pkg/scripts/postinstall" \
  || fail "postinstall no longer uses protected core installer path"

echo "PASS: Merlin installer branding surface is valid"
