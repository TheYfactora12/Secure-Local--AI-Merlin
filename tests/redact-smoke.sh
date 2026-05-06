#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${STACK_DIR}/scripts/redact.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

INPUT=$'AWS=AKIA1234567890ABCDEF\njwt eyJabcdefghijklmnopqrstuvwx\nPASSWORD=hunter2\npath=/Users/example/project\nopenai sk-abcdefghijklmnopqrstuvwxyz'
OUTPUT="$(printf '%s' "$INPUT" | redact_string)"

echo "$OUTPUT" | grep -q '\[REDACTED-AWS-KEY\]' || fail "AWS key not redacted"
echo "$OUTPUT" | grep -q '\[REDACTED-JWT\]' || fail "JWT not redacted"
echo "$OUTPUT" | grep -q 'PASSWORD=\[REDACTED\]' || fail "secret value not redacted"
echo "$OUTPUT" | grep -q '\[REDACTED-PATH\]' || fail "path not redacted"
echo "$OUTPUT" | grep -q '\[REDACTED-API-KEY\]' || fail "API key not redacted"

echo "PASS: redaction helper redacts sensitive patterns"
