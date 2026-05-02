#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        HOME AI ELITE — One-Shot Installer v0.3              ║
# ║  Perplexity + Codex + Memory + Automation on your hardware  ║
# ║  https://github.com/TheYfactora12/home-ai-elite             ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
err()    { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()   { echo -e "\n${BLUE}${BOLD}━━━ $1 ━━━${NC}"; }
info()   { echo -e "${CYAN}[i]${NC} $1"; }

header() {
  clear
  echo -e "${CYAN}"
  echo '  ██╗  ██╗ ██████╗ ███╗   ███╗███████╗     █████╗ ██╗'
  echo '  ██║  ██║██╔═══██╗████╗ ████║██╔════╝    ██╔══██╗██║'
  echo '  ███████║██║   ██║██╔████╔██║█████╗      ███████║██║'
  echo '  ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝      ██╔══██║██║'
  echo '  ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗    ██║  ██║██║'
  echo '  ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝'
  echo -e "${NC}"
  echo -e "  ${BOLD}Home AI Elite — Your Own Perplexity + Codex${NC}"
  echo -e "  Version 0.3  |  github.com/TheYfactora12/home-ai-elite\n"
}

header

# ── STEP 1: Preflight Checks ──────────────────────────────────────────
step "Preflight Checks"

OS=$(uname -s)
if [[ "$OS" == "Darwin" ]]; then
  log "macOS detected"
elif [[ "$OS" == "Linux" ]]; then
  log "Linux detected"
else
  err "Unsupported OS: $OS. Requires macOS or Linux."
fi

# RAM detection
if [[ "$OS" == "Darwin" ]]; then
  TOTAL_RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
else
  TOTAL_RAM_GB=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
fi
log "RAM detected: ${TOTAL_RAM_GB} GB"

# Model tier selection based on RAM
if   (( TOTAL_RAM_GB >= 48 )); then MODEL_TIER="high";
elif (( TOTAL_RAM_GB >= 24 )); then MODEL_TIER="mid";
elif (( TOTAL_RAM_GB >= 16 )); then MODEL_TIER="base";
elif (( TOTAL_RAM_GB >=  8 )); then MODEL_TIER="low";
else err "Minimum 8 GB RAM required. Detected: ${TOTAL_RAM_GB} GB."
fi
log "Model tier selected: ${MODEL_TIER} (${TOTAL_RAM_GB} GB RAM)"

# Disk check
AVAIL_DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
if (( AVAIL_DISK_GB < 30 )); then
  warn "Low disk: ${AVAIL_DISK_GB} GB available. Recommend 50+ GB. Continuing..."
else
  log "Disk space OK: ${AVAIL_DISK_GB} GB available"
fi

# Docker check
if ! command -v docker &>/dev/null; then
  err "Docker not found. Install Docker Desktop: https://docker.com/products/docker-desktop then re-run."
fi
if ! docker info &>/dev/null; then
  err "Docker is not running. Start Docker Desktop and re-run."
fi
DOCKER_COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "0")
log "Docker running | Compose ${DOCKER_COMPOSE_VERSION}"

# ── STEP 2: Install Dependencies ──────────────────────────────────────
step "Installing Dependencies"

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "Homebrew ready"
  for pkg in ollama git curl jq; do
    if command -v "$pkg" &>/dev/null; then
      log "$pkg already installed"
    else
      log "Installing $pkg..."
      brew install "$pkg"
    fi
  done
else
  sudo apt-get update -qq
  for pkg in git curl jq; do
    if ! command -v "$pkg" &>/dev/null; then
      sudo apt-get install -y -qq "$pkg"
    fi
    log "$pkg ready"
  done
  if ! command -v ollama &>/dev/null; then
    log "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
  else
    log "Ollama already installed"
  fi
fi

# Start Ollama service
if [[ "$OS" == "Darwin" ]]; then
  brew services start ollama 2>/dev/null || true
else
  systemctl enable ollama 2>/dev/null || true
  systemctl start ollama 2>/dev/null || true
fi

# Wait for Ollama to be ready (replaces fragile sleep 3)
log "Waiting for Ollama to be ready..."
OLLAMA_WAIT=0
until curl -sf http://localhost:11434 &>/dev/null; do
  sleep 2; OLLAMA_WAIT=$((OLLAMA_WAIT+2))
  if (( OLLAMA_WAIT >= 60 )); then
    err "Ollama did not start within 60s. Check: brew services list (macOS) or systemctl status ollama (Linux)"
  fi
done
log "Ollama service ready"

# ── STEP 3: Environment Setup ─────────────────────────────────────────
step "Environment Setup"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  # Auto-generate a random secret key
  if command -v openssl &>/dev/null; then
    SECRET=$(openssl rand -hex 32)
    sed -i.bak "s/change-me-in-env/${SECRET}/g" .env && rm -f .env.bak
    log "WEBUI_SECRET_KEY auto-generated"
  fi
  warn ".env created — edit to add optional cloud API keys for escalation"
else
  log ".env already exists — skipping"
fi

# Verify config.toml exists before attempting to patch it
if [[ ! -f "configs/perplexica/config.toml" ]]; then
  warn "configs/perplexica/config.toml not found — Perplexica model config will use defaults"
fi

# ── STEP 4: Pull Ollama Models (RAM-Aware) ────────────────────────────
step "Pulling AI Models (Tier: ${MODEL_TIER} / ${TOTAL_RAM_GB} GB)"

pull_model() {
  local model=$1
  log "Pulling ${model}..."
  ollama pull "$model" || warn "Failed to pull ${model} — skipping"
}

# Always pull embedding model (small, needed by all services)
pull_model "nomic-embed-text"

case "$MODEL_TIER" in
  low)
    # 8–15 GB: lightweight fast models
    pull_model "mistral:7b"
    pull_model "qwen2.5:7b"
    OPENHANDS_MODEL="ollama/qwen2.5:7b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:7b"
    ;;
  base)
    # 16–23 GB: solid daily-use tier
    pull_model "qwen2.5:7b"
    pull_model "qwen2.5-coder:7b"
    pull_model "deepseek-r1:7b"
    OPENHANDS_MODEL="ollama/qwen2.5-coder:7b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:7b"
    ;;
  mid)
    # 24–47 GB: recommended — Mac Mini M4 Pro 24GB sweet spot
    pull_model "qwen2.5:32b"
    pull_model "qwen2.5-coder:14b"
    pull_model "deepseek-r1:14b"
    OPENHANDS_MODEL="ollama/qwen2.5-coder:14b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:32b"
    ;;
  high)
    # 48+ GB: full power
    pull_model "llama3.3:70b-instruct-q4_K_M"
    pull_model "qwen2.5:32b"
    pull_model "qwen2.5-coder:14b"
    pull_model "deepseek-r1:32b"
    OPENHANDS_MODEL="ollama/qwen2.5-coder:14b"
    PERPLEXICA_CHAT_MODEL="llama3.3:70b-instruct-q4_K_M"
    ;;
esac

# Write selected models to .env
for key_val in "OPENHANDS_MODEL=${OPENHANDS_MODEL}" "PERPLEXICA_CHAT_MODEL=${PERPLEXICA_CHAT_MODEL}"; do
  key=$(echo "$key_val" | cut -d= -f1)
  val=$(echo "$key_val" | cut -d= -f2-)
  if grep -q "^${key}" .env; then
    sed -i.bak "s|^${key}=.*|${key}=${val}|" .env && rm -f .env.bak
  else
    echo "${key}=${val}" >> .env
  fi
done
log "OpenHands model: ${OPENHANDS_MODEL}"
log "Perplexica chat model: ${PERPLEXICA_CHAT_MODEL}"

# Update Perplexica config with correct model
if [[ -f "configs/perplexica/config.toml" ]]; then
  sed -i.bak "s|^CHAT_MODEL = .*|CHAT_MODEL = \"${PERPLEXICA_CHAT_MODEL}\"|" \
    configs/perplexica/config.toml && rm -f configs/perplexica/config.toml.bak
fi

# ── STEP 5: Docker Compose Up ─────────────────────────────────────────
step "Pulling Docker Images & Starting All Services"

docker compose pull --quiet
log "Images pulled"

docker compose up -d
log "All services started"

# ── STEP 6: Health Checks ─────────────────────────────────────────────
step "Waiting for Services to be Ready"

wait_for_service() {
  local name=$1; local url=$2; local max_wait=${3:-90}
  local elapsed=0
  printf "  Waiting for %-25s " "${name}..."
  until curl -sf "$url" &>/dev/null; do
    printf "."
    sleep 3; elapsed=$((elapsed+3))
    if (( elapsed >= max_wait )); then
      echo " TIMEOUT"
      warn "${name} not responding — check: docker compose logs"
      return 1
    fi
  done
  echo " ✓"
  return 0
}

wait_for_service "Ollama"        "http://localhost:11434"        60
wait_for_service "LiteLLM"       "http://localhost:4000/health"  120
wait_for_service "Open WebUI"    "http://localhost:3000"         90
wait_for_service "SearXNG"       "http://localhost:8080"         60
wait_for_service "Qdrant"        "http://localhost:6333/healthz" 60
wait_for_service "n8n"           "http://localhost:5678"         60

# ── STEP 7: Optional MCP Servers ──────────────────────────────────────
step "MCP Server Setup (Optional)"
if [[ -f "mcp/install-mcp-servers.sh" ]]; then
  echo -e "  ${YELLOW}Install MCP servers? (GitHub + filesystem + Qdrant MCP) [y/N]${NC}"
  read -r INSTALL_MCP
  if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    bash mcp/install-mcp-servers.sh
  else
    warn "Skipped — run manually: bash mcp/install-mcp-servers.sh"
  fi
fi

# ── STEP 8: Done — Print Dashboard ────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║          HOME AI ELITE IS READY  ✓                      ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Your Services:${NC}"
echo -e "  ${CYAN}🧠 Chat (Perplexity UI):${NC}   http://localhost:3000"
echo -e "  ${CYAN}🔍 Search AI (Perplexica):${NC}  http://localhost:3002"
echo -e "  ${CYAN}💻 Codex Agent (OpenHands):${NC} http://localhost:3003"
echo -e "  ${CYAN}🔎 Private Web Search:${NC}      http://localhost:8080"
echo -e "  ${CYAN}⚙️  Automation (n8n):${NC}        http://localhost:5678"
echo -e "  ${CYAN}📦 Vector Memory (Qdrant):${NC}  http://localhost:6333"
echo -e "  ${CYAN}🔀 Model Router (LiteLLM):${NC}  http://localhost:4000"
echo ""
echo -e "  ${BOLD}Hardware Tier:${NC} ${MODEL_TIER} (${TOTAL_RAM_GB} GB RAM)"
echo -e "  ${BOLD}Coding Model:${NC}  ${OPENHANDS_MODEL}"
echo -e "  ${BOLD}Chat Model:${NC}    ${PERPLEXICA_CHAT_MODEL}"
echo ""
echo -e "  ${YELLOW}⚠  SECURITY: Change these defaults in .env before first use:${NC}"
echo -e "     WEBUI_SECRET_KEY  (auto-generated if openssl available)"
echo -e "     N8N_PASSWORD      (default: changeme)"
echo -e "     LITELLM_MASTER_KEY (default: sk-home-ai-elite)"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "  1. http://localhost:3000  → create admin account, start chatting"
echo -e "  2. http://localhost:3002  → try a Perplexica web search"
echo -e "  3. http://localhost:3003  → give OpenHands a coding task"
echo -e "  4. http://localhost:5678  → import n8n-workflows/ai-router.json"
echo -e "  5. bash scripts/status.sh → health dashboard anytime"
echo -e "  6. bash scripts/add-model.sh <model> → pull more models"
echo ""
echo -e "  ${BOLD}Repo:${NC} https://github.com/TheYfactora12/home-ai-elite"
echo ""
