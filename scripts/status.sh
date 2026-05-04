#!/usr/bin/env bash
# Home AI Elite — Service Health Dashboard
# Usage: bash scripts/status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if ! command -v docker >/dev/null 2>&1; then
  DOCKER_APP_CLI="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${DOCKER_APP_CLI}/docker" ]]; then
    export PATH="${DOCKER_APP_CLI}:$PATH"
  fi
fi

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

check() {
  local name=$1; local url=$2; local port=$3
  if curl -sf "$url" &>/dev/null; then
    echo -e "  ${GREEN}●${NC} ${BOLD}${name}${NC} — ${GREEN}RUNNING${NC}  →  http://localhost:${port}"
  else
    echo -e "  ${RED}●${NC} ${BOLD}${name}${NC} — ${RED}DOWN${NC}"
  fi
}

echo -e "\n${CYAN}${BOLD}HOME AI ELITE — Service Status${NC}"
echo -e "$(date)\n"

check "Dashboard   (Wizard HQ)    " "http://localhost:8888"           8888
check "Open WebUI  (Chat UI)       " "http://localhost:3000"           3000
check "Perplexica  (Search AI)     " "http://localhost:3002"           3002
check "OpenHands   (Codex Agent)   " "http://localhost:3003"           3003
check "SearXNG     (Web Search)    " "http://localhost:8080"           8080
check "LiteLLM     (Model Router)  " "http://localhost:4000"           4000
check "n8n         (Automation)    " "http://localhost:5678"           5678
check "Qdrant      (Vector Memory) " "http://localhost:6333/healthz"   6333
check "Ollama      (AI Brain)      " "http://localhost:11434"          11434

echo ""
echo -e "${BOLD}Docker Containers:${NC}"
cd "$STACK_DIR" || exit 1
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps
echo ""
echo -e "${BOLD}Ollama Models Loaded:${NC}"
if docker compose ps --services --filter status=running 2>/dev/null | grep -q '^ollama$'; then
  docker compose exec -T ollama ollama list 2>/dev/null || echo "  Unable to list Docker Ollama models"
elif command -v ollama >/dev/null 2>&1; then
  ollama list 2>/dev/null || echo "  Native Ollama running, but model list unavailable"
else
  echo "  Ollama CLI not found"
fi
echo ""
