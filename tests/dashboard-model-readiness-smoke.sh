#!/usr/bin/env bash
# Static smoke test for Wizard HQ local model readiness UX.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"
STATUS_EXTENSION="${ROOT_DIR}/merlin/status_extension.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DASHBOARD_FILE" ]] || fail "dashboard file missing"
[[ -f "$STATUS_EXTENSION" ]] || fail "status extension missing"

grep -q '@router.get("/models")' "$STATUS_EXTENSION" \
  || fail "Task API missing read-only model readiness endpoint"
grep -q "/status/models" "$DASHBOARD_FILE" \
  || fail "dashboard does not load model readiness through Task API"
grep -q "modelReadinessCopy" "$DASHBOARD_FILE" \
  || fail "dashboard missing user-facing model readiness copy"
grep -q "chat model needed" "$DASHBOARD_FILE" \
  || fail "dashboard missing missing-chat-model state"
grep -q "Only nomic-embed-text is installed" "$DASHBOARD_FILE" \
  || fail "dashboard must explain embedding-only is not chat"
grep -q "Embedding models support memory, but they cannot answer chat" "$DASHBOARD_FILE" \
  || fail "Brains tab must distinguish embedding models from chat models"
grep -q "bash scripts/add-model.sh qwen2.5:7b" "$DASHBOARD_FILE" \
  || fail "dashboard missing safe explicit model install guidance"
grep -q "brains-safe-install" "$DASHBOARD_FILE" \
  || fail "dashboard missing safe install guidance slot"
grep -q "Local Model Library" "$DASHBOARD_FILE" \
  || fail "dashboard missing local model library view"
grep -q "brains-model-library" "$DASHBOARD_FILE" \
  || fail "dashboard missing Brains model library render target"
grep -q "settings-model-library" "$DASHBOARD_FILE" \
  || fail "dashboard missing Settings model library render target"
grep -q "renderModelLibrary" "$DASHBOARD_FILE" \
  || fail "dashboard missing model library renderer"
grep -q "Review warning to show manual command" "$DASHBOARD_FILE" \
  || fail "dashboard must require warning review before showing manual command"
grep -q "manual_confirmation_required" "$DASHBOARD_FILE" \
  || fail "dashboard must render manual confirmation state"
grep -q "low_memory_warning" "$DASHBOARD_FILE" \
  || fail "dashboard must render low-memory warning from backend"
grep -q "Merlin will not download models from the browser" "$DASHBOARD_FILE" \
  || fail "dashboard missing no browser model download guarantee"
grep -q "downloads.*manual_only\\|manual_only" "$STATUS_EXTENSION" \
  || fail "model readiness endpoint must report manual-only downloads"
grep -q "manual_confirmation_required" "$STATUS_EXTENSION" \
  || fail "model readiness endpoint must report manual confirmation requirement"
grep -q "LOW_MEMORY_MODEL_WARNING" "$STATUS_EXTENSION" \
  || fail "model readiness endpoint must expose low-memory warning"

if grep -qiE 'downloadModel|pullModel|ollama[[:space:]]+pull|/api/pull|addModel|installModel' "$DASHBOARD_FILE"; then
  fail "dashboard must not expose browser model pull/download controls"
fi

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

echo "PASS: Wizard HQ model readiness UX is explicit and no-download"
