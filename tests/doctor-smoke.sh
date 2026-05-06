#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0
ok()   { echo "  [PASS] $*"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }

[[ -x "$STACK_DIR/scripts/doctor.sh" ]]    && ok "doctor.sh executable"    || fail "doctor.sh not executable"
bash "$STACK_DIR/scripts/doctor.sh" --help >/dev/null 2>&1 \
  && ok "doctor.sh --help exits 0"          || fail "doctor.sh --help failed"
[[ -x "$STACK_DIR/scripts/report-bug.sh" ]] && ok "report-bug.sh executable" || fail "report-bug.sh not executable"
[[ -x "$STACK_DIR/scripts/redact.sh" ]]    && ok "redact.sh executable"    || fail "redact.sh not executable"

RESULT=$(bash -c 'source "$1"; printf "%s" "AKIAIOSFODNN7EXAMPLE" | redact_string' \
  _ "$STACK_DIR/scripts/redact.sh")
echo "$RESULT" | grep -q "AKIAIOSFODNN7EXAMPLE" \
  && fail "AWS key not redacted" || ok "AWS key redacted"
echo "$RESULT" | grep -q "\[REDACTED" \
  && ok "AWS key replaced with [REDACTED marker" || fail "No [REDACTED marker"

RESULT2=$(bash -c 'source "$1"; printf "%s" "password=supersecret123" | redact_string' \
  _ "$STACK_DIR/scripts/redact.sh")
echo "$RESULT2" | grep -q "supersecret123" \
  && fail "password not redacted" || ok "password value redacted"

OUTPUT=$(bash "$STACK_DIR/scripts/report-bug.sh" "test-command" "1" 2>/dev/null | tail -1)
CLEAN_PATH=$(echo "$OUTPUT" | sed 's/.*✓[[:space:]]*//')
echo "$CLEAN_PATH" | grep -q "\[REDACTED-PATH\]" \
  && ok "report-bug.sh prints redacted report path" || fail "report-bug.sh path not redacted"
ACTUAL_PATH=$(find "$STACK_DIR/logs" -maxdepth 1 -name "merlin-bug-report-*.md" -type f -print 2>/dev/null | sort | tail -1)
[[ -f "$ACTUAL_PATH" ]] && ok "report-bug.sh generated report file" \
  || fail "report-bug.sh did not generate a file"

if [[ -f "$ACTUAL_PATH" ]]; then
  grep -qE "AKIA[0-9A-Z]{16}" "$ACTUAL_PATH" \
    && fail "Report contains raw AWS key" || ok "Report clean of AWS keys"
  grep -qE "password=[^ ]" "$ACTUAL_PATH" \
    && fail "Report contains raw password" || ok "Report clean of raw passwords"
fi

grep -q "doctor"     "$STACK_DIR/cli/wizard" && ok "wizard doctor wired"     || fail "wizard doctor not in wizard"
grep -q "report-bug" "$STACK_DIR/cli/wizard" && ok "wizard report-bug wired" || fail "wizard report-bug not in wizard"

echo ""
echo "doctor-smoke: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
