#!/usr/bin/env bash
# Static smoke for the optional Wizard HQ browser QA harness.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QA_SCRIPT="${ROOT_DIR}/scripts/dashboard-browser-qa.py"
SETUP_SCRIPT="${ROOT_DIR}/scripts/setup-browser-qa.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$QA_SCRIPT" ]] || fail "dashboard browser QA script missing"
[[ -f "$SETUP_SCRIPT" ]] || fail "dashboard browser QA setup script missing"

python3 -m py_compile "$QA_SCRIPT" || fail "dashboard browser QA script must compile"
bash -n "$SETUP_SCRIPT" || fail "browser QA setup script must pass bash syntax"
python3 "$QA_SCRIPT" --help >/dev/null || fail "dashboard browser QA script must expose help without Playwright installed"

grep -q "playwright.sync_api" "$QA_SCRIPT" \
  || fail "browser QA must use Python Playwright"
grep -q "desktop-1280" "$QA_SCRIPT" \
  || fail "browser QA must capture desktop viewport"
grep -q "mobile-375" "$QA_SCRIPT" \
  || fail "browser QA must capture mobile viewport"
grep -q "docs/release/evidence/assets" "$QA_SCRIPT" \
  || fail "browser QA must write evidence screenshots under release assets"
grep -q "Ask Merlin button should be active after typing" "$QA_SCRIPT" \
  || fail "browser QA must validate composer send state"
grep -q "Search chip did not toggle on" "$QA_SCRIPT" \
  || fail "browser QA must validate interactive chip state"
grep -q "Room Review Table" "$QA_SCRIPT" \
  || fail "browser QA must validate Rooms review table"
grep -q "Room archive/delete remains locked" "$QA_SCRIPT" \
  || fail "browser QA must validate whole-Room archive/delete lock"
grep -q "rooms.png" "$QA_SCRIPT" \
  || fail "browser QA must capture Rooms viewport screenshots"
grep -q "cloud_calls_expected.*False" "$QA_SCRIPT" \
  || fail "browser QA summary must preserve no-cloud expectation"
grep -q "browser_shell_execution.*False" "$QA_SCRIPT" \
  || fail "browser QA summary must preserve no browser shell execution expectation"
grep -q "playwright install chromium" "$SETUP_SCRIPT" \
  || fail "setup script must install Chromium browser dependency"

if grep -qiE 'runShell|subprocess|downloadModel|pullModel|api[_-]?key|secret[[:space:]]*[:=]|token[[:space:]]*[:=]' "$QA_SCRIPT" "$SETUP_SCRIPT"; then
  fail "browser QA scripts must not expose unsafe execution/model/secret behavior"
fi

if grep -Fq 'exec(' "$QA_SCRIPT" "$SETUP_SCRIPT"; then
  fail "browser QA scripts must not expose unsafe execution/model/secret behavior"
fi

echo "PASS: Wizard HQ browser QA harness is present and safe"
