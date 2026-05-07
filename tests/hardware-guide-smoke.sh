#!/usr/bin/env bash
# Static smoke test for v1.2 hardware guide and free stack map.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARDWARE="${ROOT_DIR}/docs/hardware-guide.md"
STACK_MAP="${ROOT_DIR}/docs/free-stack-map.md"
INGESTION="${ROOT_DIR}/docs/DOCUMENT_INGESTION_PLAN.md"
TIERS="${ROOT_DIR}/configs/merlin/hardware-tiers.yaml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$HARDWARE" ]] || fail "missing docs/hardware-guide.md"
[[ -f "$STACK_MAP" ]] || fail "missing docs/free-stack-map.md"
[[ -f "$INGESTION" ]] || fail "missing docs/DOCUMENT_INGESTION_PLAN.md"

grep -q "8GB RAM" "$HARDWARE" \
  || fail "hardware guide must preserve 8GB entry point"
grep -q "low/core mode" "$HARDWARE" \
  || fail "hardware guide must name low/core behavior"
grep -q "full stack" "$HARDWARE" && grep -q "8GB" "$HARDWARE" \
  || fail "hardware guide must warn against full stack on 8GB"
grep -q "qwen2.5:7b" "$HARDWARE" \
  || fail "hardware guide must include low-tier model"
grep -q "nomic-embed-text" "$HARDWARE" \
  || fail "hardware guide must include local embedding model"
grep -q "No automatic large model downloads" "$HARDWARE" \
  || fail "hardware guide must keep model pulls explicit"
grep -q "Cloud providers remain off by default" "$HARDWARE" \
  || fail "hardware guide must keep cloud off by default"

for component in "Open WebUI" Ollama LiteLLM Qdrant "Wizard HQ" SearXNG Perplexica n8n OpenHands "Merlin Core"; do
  grep -q "$component" "$STACK_MAP" || fail "free stack map missing $component"
done

grep -q "Not in v1.2 runtime scope" "$STACK_MAP" \
  || fail "free stack map must defer voice/image runtime work"
grep -q "Planning only in v1.2" "$STACK_MAP" \
  || fail "free stack map must mark document ingestion as planning only"

grep -q "No ingestion runtime" "$INGESTION" \
  || fail "document ingestion plan must avoid runtime changes"
grep -q "No cloud parsing or cloud embedding" "$INGESTION" \
  || fail "document ingestion plan must keep cloud off"
grep -q "Memory writes require approval" "$INGESTION" \
  || fail "document ingestion plan must require memory approval"
grep -q "Dimension mismatch raises before any write" "$INGESTION" \
  || fail "document ingestion plan must require dimension safety"
grep -q "ram_gb_min: 8" "$TIERS" \
  || fail "hardware tier config must retain low tier min"
grep -q "ram_gb_max: 15" "$TIERS" \
  || fail "hardware tier config must retain low tier max"

if grep -qi "16GB RAM.*entry point" "$HARDWARE"; then
  fail "hardware guide must not regress to 16GB entry point"
fi

echo "PASS: v1.2 hardware guide and stack map preserve 8GB-first planning"
