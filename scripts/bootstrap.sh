#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Full first-boot initialization
# Runs AFTER docker compose up. Calls all init scripts in order.
# Safe to re-run: all steps are idempotent.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load env if present
[[ -f "${ROOT_DIR}/.env" ]] && set -a && source "${ROOT_DIR}/.env" && set +a

COLOR_CYAN="\033[0;36m"
COLOR_GREEN="\033[0;32m"
COLOR_RESET="\033[0m"

banner() { echo -e "\n${COLOR_CYAN}══════════════════════════════════════${COLOR_RESET}"; \
           echo -e "${COLOR_CYAN}  $* ${COLOR_RESET}"; \
           echo -e "${COLOR_CYAN}══════════════════════════════════════${COLOR_RESET}\n"; }

banner "home-ai-elite bootstrap"

# 1. Qdrant collections
banner "Step 1/2: Qdrant Collection Init"
bash "${SCRIPT_DIR}/init-qdrant.sh"

# 2. n8n workflow import (only runs if N8N_API_KEY is set)
banner "Step 2/2: n8n Workflow Import"
bash "${SCRIPT_DIR}/import-n8n-workflows.sh"

echo -e "${COLOR_GREEN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   home-ai-elite bootstrap complete!      ║"
echo "  ╟──────────────────────────────────────────╢"
echo "  ║  Open WebUI   → http://localhost:3001    ║"
echo "  ║  n8n           → http://localhost:5678   ║"
echo "  ║  Perplexica    → http://localhost:3000   ║"
echo "  ║  Qdrant        → http://localhost:6333   ║"
echo "  ║  SearXNG       → http://localhost:8080   ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"
