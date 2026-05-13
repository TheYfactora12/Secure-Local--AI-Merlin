#!/usr/bin/env bash
# Static smoke test for Merlin Dashboard local model readiness UX.
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
grep -q "Memory embeddings are installed, but chat still needs a local chat model" "$DASHBOARD_FILE" \
  || fail "dashboard must explain embedding-only is not chat without making terminal the primary action"
grep -q "Open Brains to review the safe manual setup path" "$DASHBOARD_FILE" \
  || fail "dashboard must guide users to Brains before manual model setup"
grep -q "No browser download will run" "$DASHBOARD_FILE" \
  || fail "dashboard must reassure users that the Brains path does not trigger browser downloads"
grep -q "Embedding models support memory, but they cannot answer chat" "$DASHBOARD_FILE" \
  || fail "Brains tab must distinguish embedding models from chat models"
grep -q "bash scripts/add-model.sh qwen2.5:7b" "$DASHBOARD_FILE" \
  || fail "dashboard missing safe explicit model install guidance"
grep -q "brains-safe-install" "$DASHBOARD_FILE" \
  || fail "dashboard missing safe install guidance slot"
grep -q "Local Model Library" "$DASHBOARD_FILE" \
  || fail "dashboard missing local model library view"
grep -q "Offline model selection preview" "$DASHBOARD_FILE" \
  || fail "dashboard missing Fast/Smart model selector preview"
grep -q "Default local path for 8GB/core systems" "$DASHBOARD_FILE" \
  || fail "Fast mode must be framed as the safe 8GB/core default"
grep -q "Better reasoning when hardware and installed local models support it" "$DASHBOARD_FILE" \
  || fail "Smart mode must stay hardware-aware"
grep -q "Cloud Bridge" "$DASHBOARD_FILE" \
  || fail "dashboard missing explicit cloud bridge state"
grep -q "off until allowed" "$DASHBOARD_FILE" \
  || fail "cloud bridge must remain off until explicitly allowed"
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
[[ "$POST_COUNT" == "3" ]] || fail "dashboard must use only Task API /task POSTs and shared policy-gated POST helper"
grep -q "/approvals/room-transcript" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript approval path"
grep -q "/rooms/transcripts" "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript save path"

echo "PASS: Merlin Dashboard model readiness UX is explicit and no-download"
