#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

before_count="$(find "${STACK_DIR}/logs" -maxdepth 1 -name 'merlin-bug-report-*.md' 2>/dev/null | wc -l | tr -d ' ')"
OUTPUT="$(bash "${STACK_DIR}/scripts/report-bug.sh" "wizard doctor" "1")"
after_count="$(find "${STACK_DIR}/logs" -maxdepth 1 -name 'merlin-bug-report-*.md' 2>/dev/null | wc -l | tr -d ' ')"

[[ "$after_count" -gt "$before_count" ]] || fail "report-bug did not create report"
echo "$OUTPUT" | grep -q '\[REDACTED-PATH\]' || fail "redacted report path output missing"

REPORT="$(find "${STACK_DIR}/logs" -maxdepth 1 -name 'merlin-bug-report-*.md' -print | sort | tail -1)"
grep -q '# Merlin Bug Report' "$REPORT" || fail "report heading missing"
grep -q '## .env Key Presence' "$REPORT" || fail "env section missing"
grep -q 'wizard doctor' "$REPORT" || fail "failing command missing"

if grep -Eq 'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}' "$REPORT"; then
  fail "report contains unredacted sensitive pattern"
fi

echo "PASS: report-bug creates sanitized report"
