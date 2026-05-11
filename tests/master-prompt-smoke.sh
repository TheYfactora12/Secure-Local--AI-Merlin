#!/usr/bin/env bash
# Static smoke test for Codex master prompt/context drift.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="${ROOT_DIR}/docs/MASTER_PROMPT.md"
CONTEXT_FILE="${ROOT_DIR}/docs/MASTER_CONTEXT.md"

grep -q "Codex Master Prompt" "$PROMPT_FILE"
grep -q "Protect the working installer" "$PROMPT_FILE"
grep -q "Do not enable cloud/API calls by default" "$PROMPT_FILE"
grep -q "Merlin ethos" "$PROMPT_FILE"
grep -q "install everything in one shot" "$PROMPT_FILE"
grep -q "keep everything private" "$PROMPT_FILE"
grep -q "uninstall cleanly" "$PROMPT_FILE"
grep -q "execution_allowed.*false" "$PROMPT_FILE"
grep -q "Before final response" "$PROMPT_FILE"

grep -q "Last verified: 2026-05-10" "$CONTEXT_FILE"
grep -q "Session Operating Rule" "$CONTEXT_FILE"
grep -q "Follow milestones in order" "$CONTEXT_FILE"
grep -q "Defer #64 Developer ID signing/notarization" "$CONTEXT_FILE"
grep -q "Merlin status API" "$CONTEXT_FILE"
grep -q "http://localhost:8765/status" "$CONTEXT_FILE"
grep -q "local Qdrant" "$CONTEXT_FILE"
grep -q "FUTURE_IDEAS.md" "$CONTEXT_FILE"

echo "PASS: Codex master prompt and context are current"
