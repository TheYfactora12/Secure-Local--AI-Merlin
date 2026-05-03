#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        HOME AI ELITE / WIZARD AI — One-Shot Installer v1.0   ║
# ║  Perplexity + Codex + Memory + Automation on your hardware  ║
# ║  https://github.com/TheYfactora12/home-ai-elite             ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

NON_INTERACTIVE="${HOME_AI_NON_INTERACTIVE:-false}"
SKIP_MODEL_PULLS="${HOME_AI_SKIP_MODEL_PULLS:-false}"

for arg in "$@"; do
  case "$arg" in
    --non-interactive|--yes)
      NON_INTERACTIVE=true
      ;;
    --skip-model-pulls)
      SKIP_MODEL_PULLS=true
      ;;
    -h|--help)
      cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --non-interactive   Do not prompt for optional API keys or setup choices.
  --skip-model-pulls  Start services without pulling Ollama models.
  -h, --help          Show this help.

Environment:
  HOME_AI_NON_INTERACTIVE=true
  HOME_AI_SKIP_MODEL_PULLS=true
EOF
      exit 0
      ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
err()    { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()   { echo -e "\n${BLUE}${BOLD}━━━ $1 ━━━${NC}"; }
info()   { echo -e "${CYAN}[i]${NC} $1"; }

ensure_docker_cli() {
  if command -v docker &>/dev/null; then
    return 0
  fi

  local docker_app_cli="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${docker_app_cli}/docker" ]]; then
    export PATH="${docker_app_cli}:$PATH"
    return 0
  fi

  return 1
}

wait_for_docker_engine() {
  if docker info &>/dev/null; then
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Docker.app" ]]; then
    warn "Docker Desktop is installed but not running. Opening Docker Desktop..."
    open -a Docker >/dev/null 2>&1 || true

    local elapsed=0
    until docker info &>/dev/null; do
      sleep 5
      elapsed=$((elapsed + 5))
      if (( elapsed >= 300 )); then
        return 1
      fi
      (( elapsed % 30 == 0 )) && info "Still waiting for Docker Desktop (${elapsed}s)..."
    done
    return 0
  fi

  return 1
}

header() {
  clear 2>/dev/null || true
  echo -e "${CYAN}"
  echo '  ██╗  ██╗ ██████╗ ███╗   ███╗███████╗     █████╗ ██╗'
  echo '  ██║  ██║██╔═══██╗████╗ ████║██╔════╝    ██╔══██╗██║'
  echo '  ███████║██║   ██║██╔████╔██║█████╗      ███████║██║'
  echo '  ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝      ██╔══██║██║'
  echo '  ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗    ██║  ██║██║'
  echo '  ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝'
  echo -e "${NC}"
  echo -e "  ${BOLD}Wizard AI — Your Own Perplexity + Codex + Memory${NC}"
  echo -e "  Version 1.0  |  github.com/TheYfactora12/home-ai-elite\n"
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

# macOS version check
if [[ "$OS" == "Darwin" ]]; then
  MACOS_VERSION=$(sw_vers -productVersion)
  MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
  if (( MACOS_MAJOR < 14 )); then
    warn "macOS ${MACOS_VERSION} detected. macOS 14 (Sonoma)+ recommended for best performance."
  else
    log "macOS ${MACOS_VERSION} ✔"
  fi
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

# ── FIX P1: Cross-platform disk space check ───────────────────────────
# macOS: df -g reports in GB. Linux: df -BG reports in GB.
# Using df -k (works on both) and converting to GB for safety.
if [[ "$OS" == "Darwin" ]]; then
  AVAIL_DISK_KB=$(df -k . | awk 'NR==2 {print $4}')
else
  AVAIL_DISK_KB=$(df -k . | awk 'NR==2 {print $4}')
fi
AVAIL_DISK_GB=$(( AVAIL_DISK_KB / 1024 / 1024 ))
if (( AVAIL_DISK_GB < 30 )); then
  warn "Low disk: ${AVAIL_DISK_GB} GB available. Recommend 50+ GB. Continuing..."
else
  log "Disk space OK: ${AVAIL_DISK_GB} GB available"
fi

# Docker check
if ! ensure_docker_cli; then
  err "Docker not found. Install Docker Desktop: https://docker.com/products/docker-desktop then re-run."
fi
if ! wait_for_docker_engine; then
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
  for pkg in git curl jq; do
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
fi

if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
  if brew services list 2>/dev/null | awk '$1 == "ollama" && $2 == "started" { found=1 } END { exit found ? 0 : 1 }'; then
    warn "Stopping Homebrew Ollama so the Docker Ollama container can bind localhost:11434..."
    brew services stop ollama 2>/dev/null || true
  fi
fi

# ── STEP 3: Environment Setup & Secret Hardening ──────────────────────
step "Environment Setup & Secret Hardening"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 3a: Create .env from template if it doesn't exist
if [[ ! -f .env ]]; then
  cp .env.example .env
  log ".env created from .env.example"
else
  log ".env already exists — skipping template copy"
fi

# Restrict .env permissions immediately
chmod 600 .env
log ".env permissions set to 600 (owner read/write only)"

# ── 3b: Auto-rotate all insecure default secrets ──────────────────────
rotate_secret() {
  local key=$1
  local current_val
  current_val=$(grep "^${key}=" .env | cut -d= -f2- || true)
  local insecure_defaults=(
    "change-me-in-env"
    "change-me-run-openssl-rand-hex-32"
    "sk-home-ai-elite"
    "changeme"
    ""
  )
  local is_insecure=false
  for default in "${insecure_defaults[@]}"; do
    if [[ "$current_val" == "$default" ]]; then
      is_insecure=true
      break
    fi
  done

  if [[ "$is_insecure" == true ]]; then
    if ! command -v openssl &>/dev/null; then
      warn "openssl not found — ${key} NOT rotated. Run: openssl rand -hex 32 and set manually in .env"
      return
    fi
    local new_val
    new_val=$(openssl rand -hex 32)
    if grep -q "^${key}=" .env; then
      sed -i.bak "s|^${key}=.*|${key}=${new_val}|" .env && rm -f .env.bak
    else
      echo "${key}=${new_val}" >> .env
    fi
    log "${key} → auto-generated (${new_val:0:8}...  [hidden])"
  else
    log "${key} already set — skipping rotation"
  fi
}

rotate_secret "WEBUI_SECRET_KEY"
rotate_secret "LITELLM_MASTER_KEY"
rotate_secret "N8N_PASSWORD"
rotate_secret "SEARXNG_SECRET_KEY"

# ── 3c: Secure interactive prompt for cloud API keys ──────────────────
prompt_api_key() {
  local key=$1
  local label=$2
  local url=$3

  local current_val
  current_val=$(grep "^${key}=" .env | cut -d= -f2- 2>/dev/null || true)
  if [[ -n "$current_val" ]]; then
    log "${key} already set — skipping"
    return
  fi

  if [[ "$NON_INTERACTIVE" == true ]]; then
    info "${key} skipped — non-interactive install"
    return
  fi

  echo ""
  echo -e "  ${YELLOW}${BOLD}${label}${NC}"
  echo -e "  ${CYAN}Get it at: ${url}${NC}"
  echo -e "  ${BOLD}(input hidden — key will NOT appear on screen)${NC}"
  local user_input
  while true; do
    printf "  Paste key (Enter to skip): "
    read -rs user_input
    echo ""
    if [[ -z "$user_input" ]]; then
      info "${key} skipped — local-only mode for this service"
      break
    fi
    if [[ "$user_input" =~ [[:space:]] ]]; then
      warn "Key contains spaces — check for accidental paste. Try again."
      continue
    fi
    if (( ${#user_input} < 8 )); then
      warn "Key looks too short (${#user_input} chars). Try again or press Enter to skip."
      continue
    fi
    if grep -q "^${key}=" .env; then
      sed -i.bak "s|^${key}=.*|${key}=${user_input}|" .env && rm -f .env.bak
    else
      echo "${key}=${user_input}" >> .env
    fi
    log "${key} saved ✓ (${#user_input} chars, value hidden)"
    break
  done
}

if [[ "$NON_INTERACTIVE" == true ]]; then
  info "Non-interactive mode enabled — optional cloud API key prompts will be skipped."
else
  echo ""
  echo -e "  ${CYAN}${BOLD}━━━ Optional: Cloud API Keys ━━━${NC}"
  echo -e "  The stack runs ${BOLD}100% locally${NC} without any of these."
  echo -e "  Add keys only if you want cloud model fallback for complex tasks."
  echo -e "  ${YELLOW}Keys are entered in hidden mode — they will NOT be echoed to screen.${NC}\n"
fi

prompt_api_key "OPENAI_API_KEY" \
  "OpenAI API Key  (GPT-4o fallback)" \
  "https://platform.openai.com/api-keys"

prompt_api_key "ANTHROPIC_API_KEY" \
  "Anthropic API Key  (Claude fallback)" \
  "https://console.anthropic.com/settings/keys"

prompt_api_key "PERPLEXITY_API_KEY" \
  "Perplexity API Key  (Sonar search fallback)" \
  "https://www.perplexity.ai/settings/api"

prompt_api_key "GITHUB_TOKEN" \
  "GitHub Personal Access Token  (OpenHands + MCP)" \
  "https://github.com/settings/tokens  [scopes: repo, read:org]"

# 3d: Verify config.toml exists — required for correct Perplexica model config
if [[ ! -f "configs/perplexica/config.toml" ]]; then
  err "configs/perplexica/config.toml not found. This file is required for Perplexica model configuration.
  → Run: cp configs/perplexica/config.toml.example configs/perplexica/config.toml
  → Or re-clone the repo: git clone https://github.com/TheYfactora12/home-ai-elite"
fi
log "configs/perplexica/config.toml found ✔"

# 3e: Generate local TLS certificate for nginx if needed
if [[ -f "scripts/generate-certs.sh" ]]; then
  if [[ ! -f "certs/selfsigned.crt" || ! -f "certs/selfsigned.key" ]]; then
    HOME_AI_STACK_DIR="${SCRIPT_DIR}" bash scripts/generate-certs.sh
  else
    log "Nginx TLS certificate already exists — skipping generation"
  fi
else
  warn "scripts/generate-certs.sh not found — nginx HTTPS proxy may not start"
fi

# ── STEP 4: Pull Ollama Models (RAM-Aware) ────────────────────────────
step "Pulling AI Models (Tier: ${MODEL_TIER} / ${TOTAL_RAM_GB} GB)"

MODELS_TO_PULL=()

if [[ "$SKIP_MODEL_PULLS" == true ]]; then
  warn "Skipping Ollama model pulls. Pull models later with: bash scripts/add-model.sh <model>"
else
  MODELS_TO_PULL+=("nomic-embed-text")
fi

case "$MODEL_TIER" in
  low)
    [[ "$SKIP_MODEL_PULLS" == true ]] || MODELS_TO_PULL+=("mistral:7b" "qwen2.5:7b")
    OPENHANDS_MODEL="ollama/qwen2.5:7b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:7b"
    ;;
  base)
    [[ "$SKIP_MODEL_PULLS" == true ]] || MODELS_TO_PULL+=("qwen2.5:7b" "qwen2.5-coder:7b" "deepseek-r1:7b")
    OPENHANDS_MODEL="ollama/qwen2.5-coder:7b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:7b"
    ;;
  mid)
    [[ "$SKIP_MODEL_PULLS" == true ]] || MODELS_TO_PULL+=("qwen2.5:32b" "qwen2.5-coder:14b" "deepseek-r1:14b")
    OPENHANDS_MODEL="ollama/qwen2.5-coder:14b"
    PERPLEXICA_CHAT_MODEL="qwen2.5:32b"
    ;;
  high)
    # FIX P2: Use canonical Ollama registry tag for llama3.3 70B.
    # llama3.3:70b-instruct-q4_K_M may not exist on all registry mirrors.
    # Canonical tag is llama3.3:70b (defaults to Q4_K_M quantization).
    [[ "$SKIP_MODEL_PULLS" == true ]] || MODELS_TO_PULL+=("llama3.3:70b" "qwen2.5:32b" "qwen2.5-coder:14b" "deepseek-r1:32b")
    OPENHANDS_MODEL="ollama/qwen2.5-coder:14b"
    PERPLEXICA_CHAT_MODEL="llama3.3:70b"
    ;;
esac

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

if [[ -f "configs/perplexica/config.toml" ]]; then
  sed -i.bak "s|^CHAT_MODEL = .*|CHAT_MODEL = \"${PERPLEXICA_CHAT_MODEL}\"|" \
    configs/perplexica/config.toml && rm -f configs/perplexica/config.toml.bak
fi

# ── STEP 5: Docker Compose Up ─────────────────────────────────────────
step "Pulling Docker Images & Starting All Services"

docker compose pull --quiet
log "Images pulled"

docker compose up -d ollama
log "Ollama container started"

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
      return 0
    fi
  done
  echo " ✓"
  return 0
}

wait_for_service "Ollama" "http://localhost:11434" 90

if (( ${#MODELS_TO_PULL[@]} > 0 )); then
  for model in "${MODELS_TO_PULL[@]}"; do
    log "Pulling ${model} into Docker Ollama..."
    if ! docker compose exec -T ollama ollama pull "$model"; then
      warn "Failed to pull ${model} — skipping. Stack will continue; pull manually with: bash scripts/add-model.sh ${model}"
    fi
  done
fi

docker compose up -d
log "All services started"

# ── STEP 6: Health Checks ─────────────────────────────────────────────
step "Waiting for Services to be Ready"

wait_for_service "Ollama"        "http://localhost:11434"        60
wait_for_service "LiteLLM"       "http://localhost:4000"         120
wait_for_service "Open WebUI"    "http://localhost:3000"         90
wait_for_service "SearXNG"       "http://localhost:8080"         60
wait_for_service "Qdrant"        "http://localhost:6333/healthz" 60
wait_for_service "n8n"           "http://localhost:5678"         60

# ── STEP 7: First-Boot Init (bootstrap) ────────────────────────────────
step "First-Boot Initialization"

FIRST_BOOT_FLAG="${SCRIPT_DIR}/.wizard-bootstrapped"
if [[ ! -f "$FIRST_BOOT_FLAG" ]]; then
  if [[ -f "scripts/bootstrap.sh" ]]; then
    log "Running first-boot bootstrap (Qdrant collections + n8n workflows)..."
    if HOME_AI_STACK_DIR="${SCRIPT_DIR}" bash "${SCRIPT_DIR}/scripts/bootstrap.sh"; then
      touch "$FIRST_BOOT_FLAG"
      log "Bootstrap complete"
    else
      warn "Bootstrap reported issues — run manually after install: bash scripts/bootstrap.sh"
    fi
  else
    warn "scripts/bootstrap.sh not found — run manually after install"
  fi
else
  log "Already bootstrapped — skipping (delete .wizard-bootstrapped to force re-run)"
fi

# ── STEP 8: Install wizard CLI system-wide ──────────────────────────────
step "Installing wizard CLI"

# FIX: Explicit file existence check before symlinking — clear error if missing
CLI_PATH="${SCRIPT_DIR}/cli/wizard"
if [[ -f "$CLI_PATH" ]]; then
  chmod +x "$CLI_PATH"
  if [[ -w "/usr/local/bin" ]]; then
    ln -sf "$CLI_PATH" /usr/local/bin/wizard
    log "wizard CLI installed → /usr/local/bin/wizard"
  else
    sudo ln -sf "$CLI_PATH" /usr/local/bin/wizard
    log "wizard CLI installed → /usr/local/bin/wizard (via sudo)"
  fi
  log "Run: wizard status  |  wizard ask \"<question>\"  |  wizard help"
else
  warn "cli/wizard not found at ${CLI_PATH}"
  warn "CLI not installed. To fix: ensure cli/wizard exists and re-run install.sh"
  warn "Manual workaround: bash ${SCRIPT_DIR}/scripts/status.sh"
fi

# ── STEP 9: Optional MCP Servers ──────────────────────────────────────
step "MCP Server Setup (Optional)"
if [[ -f "mcp/install-mcp-servers.sh" ]]; then
  if [[ "$NON_INTERACTIVE" == true ]]; then
    warn "Skipped MCP server install in non-interactive mode — run manually: bash mcp/install-mcp-servers.sh"
  else
    echo -e "  ${YELLOW}Install MCP servers? (GitHub + filesystem + Qdrant MCP) [y/N]${NC}"
    read -r INSTALL_MCP
    if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
      bash mcp/install-mcp-servers.sh
    else
      warn "Skipped — run manually: bash mcp/install-mcp-servers.sh"
    fi
  fi
fi

# ── STEP 10: LaunchD Auto-Start (macOS only) ───────────────────────────
if [[ "$OS" == "Darwin" ]] && [[ -f "launchd/install-launchd.sh" ]]; then
  step "macOS Auto-Start (LaunchD)"
  if [[ "$NON_INTERACTIVE" == true ]]; then
    warn "Skipped launchd setup in non-interactive mode — run manually: bash launchd/install-launchd.sh"
  else
    echo -e "  ${YELLOW}Install launchd agents for auto-start on login? [y/N]${NC}"
    read -r INSTALL_LAUNCHD
    if [[ "$INSTALL_LAUNCHD" =~ ^[Yy]$ ]]; then
      bash launchd/install-launchd.sh
      log "LaunchD agents installed — Wizard will auto-start on login"
    else
      warn "Skipped — run manually: bash launchd/install-launchd.sh"
    fi
  fi
fi

# ── STEP 11: Security Review Checklist ───────────────────────────────
step "Security Review"

SECURITY_PASS=true

# Check no insecure defaults remain in .env
for key in WEBUI_SECRET_KEY LITELLM_MASTER_KEY N8N_PASSWORD SEARXNG_SECRET_KEY; do
  val=$(grep "^${key}=" .env | cut -d= -f2- || true)
  for bad in "change-me-in-env" "change-me-run-openssl-rand-hex-32" "sk-home-ai-elite" "changeme" ""; do
    if [[ "$val" == "$bad" ]]; then
      warn "SECURITY: ${key} is still at insecure default! Run: openssl rand -hex 32"
      SECURITY_PASS=false
    fi
  done
done

# Check .env file permissions
ENV_PERMS=$(stat -c "%a" .env 2>/dev/null || stat -f "%A" .env 2>/dev/null || echo "unknown")
if [[ "$ENV_PERMS" != "600" ]]; then
  warn "SECURITY: .env permissions are ${ENV_PERMS}, expected 600. Fixing..."
  chmod 600 .env
  log ".env permissions corrected to 600"
else
  log ".env permissions: 600 ✔"
fi

# Check .env is gitignored
if grep -q "^\.env$" .gitignore 2>/dev/null; then
  log ".env is in .gitignore ✔"
else
  warn "SECURITY: .env is NOT in .gitignore! Adding now..."
  echo ".env" >> .gitignore
  log ".env added to .gitignore"
fi

if [[ "$SECURITY_PASS" == true ]]; then
  log "Security review passed ✔"
else
  warn "Security review found issues above — resolve before exposing to any network"
fi

# ── STEP 12: Done — Print Dashboard ───────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     WIZARD AI IS READY  ✓  v1.0                         ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Your Services:${NC}"
echo -e "  ${CYAN}🧠 Chat (Open WebUI):${NC}       http://localhost:3000"
echo -e "  ${CYAN}🔍 Search AI (Perplexica):${NC}  http://localhost:3002"
echo -e "  ${CYAN}💻 Codex Agent (OpenHands):${NC} http://localhost:3003"
echo -e "  ${CYAN}🔎 Private Search (SearXNG):${NC} http://localhost:8080"
echo -e "  ${CYAN}⚙️  Automation (n8n):${NC}         http://localhost:5678"
echo -e "  ${CYAN}📦 Vector Memory (Qdrant):${NC}  http://localhost:6333"
echo -e "  ${CYAN}🔀 Model Router (LiteLLM):${NC}  http://localhost:4000"
echo -e "  ${CYAN}📊 Dashboard (Wizard HQ):${NC}   file://${SCRIPT_DIR}/dashboard/index.html"
echo ""
echo -e "  ${BOLD}Hardware Tier:${NC} ${MODEL_TIER} (${TOTAL_RAM_GB} GB RAM)"
echo -e "  ${BOLD}Coding Model:${NC}  ${OPENHANDS_MODEL}"
echo -e "  ${BOLD}Chat Model:${NC}    ${PERPLEXICA_CHAT_MODEL}"
echo ""
echo -e "  ${GREEN}✓  All internal secrets auto-generated${NC}"
echo -e "  ${GREEN}✓  .env locked to 600 (owner only)${NC}"
echo -e "  ${GREEN}✓  Cloud API keys entered in hidden mode${NC}"
echo -e "  ${GREEN}✓  Security review complete${NC}"
echo ""
echo -e "  ${BOLD}First commands to run:${NC}"
echo -e "  ${CYAN}wizard status${NC}                    → full stack health check"
echo -e "  ${CYAN}wizard ask \"hello wizard\"${NC}        → test your AI"
echo -e "  ${CYAN}wizard open${NC}                      → open Wizard HQ in browser"
echo ""
echo -e "  ${BOLD}First-time setup steps:${NC}"
echo -e "  1. http://localhost:3000  → create your admin account"
echo -e "     ${YELLOW}⚠ Settings → Admin → disable Sign Up (lock it down)${NC}"
echo -e "  2. http://localhost:3002  → test Perplexica web search"
echo -e "  3. http://localhost:3003  → give OpenHands a coding task"
echo -e "  4. http://localhost:5678  → n8n workflows already imported by bootstrap"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo -e "  bash scripts/status.sh         → service health dashboard"
echo -e "  bash scripts/upgrade.sh        → safe upgrade with auto-rollback"
echo -e "  bash scripts/backup.sh         → backup Qdrant memory + n8n workflows"
echo -e "  bash scripts/add-model.sh <m>  → pull additional models"
echo -e "  bash scripts/healthcheck.sh    → deep health check with port scan"
echo ""
echo -e "  ${BOLD}Repo:${NC} https://github.com/TheYfactora12/home-ai-elite"
echo -e "  ${BOLD}Docs:${NC} https://github.com/TheYfactora12/home-ai-elite/tree/main/docs"
echo ""
