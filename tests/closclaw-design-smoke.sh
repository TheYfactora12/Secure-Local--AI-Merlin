#!/usr/bin/env bash
# Static smoke test for #121 ClosClaw design safety boundaries.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/architecture/CLOSCLAW_WEB_COMPREHENSION.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing ClosClaw design doc"

for required in \
  "Future design for #121" \
  "No runtime implementation exists yet" \
  "External network access is denied by default" \
  "external_network" \
  "Redaction" \
  "Metadata only by default" \
  "No write unless the existing approval-gated memory path approves it" \
  "8765" \
  "8766" \
  "Future-State Architecture" \
  "Wizard HQ Copy Requirements" \
  "Implementation Split"; do
  grep -q "$required" "$DOC" || fail "ClosClaw design missing: $required"
done

grep -q "must not support:" "$DOC" \
  || fail "ClosClaw design must list forbidden behavior"
grep -q "default-enabled external network access" "$DOC" \
  || fail "ClosClaw must forbid default-enabled network"
grep -q "browser automation" "$DOC" \
  || fail "ClosClaw must forbid browser automation"
grep -q "silent memory writes" "$DOC" \
  || fail "ClosClaw must forbid silent memory writes"
grep -q "routing confidence changes" "$DOC" \
  || fail "ClosClaw must forbid routing confidence changes"
grep -q "cloud telemetry" "$DOC" \
  || fail "ClosClaw must forbid cloud telemetry"
grep -q "direct browser-side fetch controls" "$DOC" \
  || fail "ClosClaw must forbid direct browser-side fetch controls"

if grep -qiE 'OPENAI_API_KEY|ANTHROPIC_API_KEY|PERPLEXITY_API_KEY|sk-[A-Za-z0-9]{20,}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DOC"; then
  fail "ClosClaw design must not include secret-like values"
fi

echo "PASS: ClosClaw design is policy-gated and no-default-network"
