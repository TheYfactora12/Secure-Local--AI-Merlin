#!/usr/bin/env bash
# Home AI Elite — Service Health Dashboard
# Usage: bash scripts/status.sh

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

check "Open WebUI  (Chat UI)       " "http://localhost:3000"           3000
check "Perplexica  (Search AI)     " "http://localhost:3002"           3002
check "OpenHands   (Codex Agent)   " "http://localhost:3003"           3003
check "SearXNG     (Web Search)    " "http://localhost:8080"           8080
check "LiteLLM     (Model Router)  " "http://localhost:4000/health"    4000
check "n8n         (Automation)    " "http://localhost:5678"           5678
check "Qdrant      (Vector Memory) " "http://localhost:6333/healthz"   6333
check "Ollama      (AI Brain)      " "http://localhost:11434"          11434

echo ""
echo -e "${BOLD}Docker Containers:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps
echo ""
echo -e "${BOLD}Ollama Models Loaded:${NC}"
ollama list 2>/dev/null || echo "  Ollama not running locally"
echo ""
