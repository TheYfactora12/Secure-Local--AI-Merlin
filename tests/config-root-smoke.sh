#!/usr/bin/env bash
# Enforce one canonical root configuration tree.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -d "${STACK_DIR}/configs" ]] || fail "canonical configs/ directory is missing"
[[ ! -e "${STACK_DIR}/config" ]] || fail "legacy root config/ directory must not exist"
[[ -f "${STACK_DIR}/configs/merlin/policy.yaml" ]] || fail "Merlin policy config missing from configs/merlin"
[[ -f "${STACK_DIR}/configs/merlin/routes.yaml" ]] || fail "Merlin routes config missing from configs/merlin"
[[ -f "${STACK_DIR}/configs/merlin/memory-collections.env" ]] || fail "Merlin memory manifest missing from configs/merlin"
[[ -f "${STACK_DIR}/configs/models/models.json" ]] || fail "model manifest missing from configs/models"
[[ -f "${STACK_DIR}/configs/mcp/mcp-claude-desktop.json" ]] || fail "MCP config missing from configs/mcp"

if rg -n 'config/(merlin|models|mcp|security|qdrant)' "$STACK_DIR" \
  --glob '!/.git/**' \
  --glob '!logs/**'; then
  fail "stale root config/ reference found"
fi

echo "PASS: canonical configs root is enforced"
