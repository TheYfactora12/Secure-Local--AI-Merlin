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
grep -q "wizard merlin status-api start|status|stop" "$PROMPT_FILE"
grep -q "wizard merlin config validate" "$PROMPT_FILE"
grep -q "wizard merlin execute plan|execute --action merlin_status" "$PROMPT_FILE"
grep -q "wizard merlin magic plan" "$PROMPT_FILE"
grep -q "wizard merlin memory plan|simulate|write" "$PROMPT_FILE"
grep -q "wizard merlin memory search" "$PROMPT_FILE"
grep -q "execution_allowed.*false" "$PROMPT_FILE"
grep -q "Before final response" "$PROMPT_FILE"

grep -q "Last verified: 2026-05-06" "$CONTEXT_FILE"
grep -q "Merlin status API" "$CONTEXT_FILE"
grep -q "http://localhost:8765/status" "$CONTEXT_FILE"
grep -q "tests/merlin-memory-write-smoke.sh" "$CONTEXT_FILE"
grep -q "tests/merlin-memory-read-smoke.sh" "$CONTEXT_FILE"
grep -q "tests/merlin-config-validate-smoke.sh" "$CONTEXT_FILE"
grep -q "local Qdrant" "$CONTEXT_FILE"

echo "PASS: Codex master prompt and context are current"
