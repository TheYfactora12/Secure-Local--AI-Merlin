#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        HOME AI ELITE / WIZARD AI — One-Shot Installer v1.6   ║
# ║  Perplexity + Codex + Memory + Automation on your hardware  ║
# ║  https://github.com/TheYfactora12/home-ai-elite             ║
# ╚══════════════════════════════════════════════════════════════╝
# CHANGELOG v1.6 (2026-05-03):
#   BUG-10 + BUG-15: Services no longer hard-depend on the Ollama Docker
#           container. macOS uses native Ollama through host.docker.internal;
#           Linux installer runs the Docker Ollama service through the
#           docker-ollama Compose profile.
# CHANGELOG v1.5 (2026-05-03):
#   BUG-09: Added openhands + all service aliases to KNOWN_CONTAINERS
#           pre-flight stale container removal list.
#           Fixes: "container name /openhands already in use" on re-run.
# CHANGELOG v1.4 (2026-05-03):
#   BUG-08: Pre-flight stale container removal before docker compose up.
#           Silently removes any named containers left over from partial
#           prior runs (e.g. /watchtower). Prevents "container name already
#           in use" errors on all re-runs.
# CHANGELOG v1.3 (2026-05-03):
#   BUG-07: docker compose up now uses --remove-orphans + --force-recreate
#           Fixes "container name already in use" on any re-run (e.g. /watchtower)
# CHANGELOG v1.2 (2026-05-03):
#   BUG-01: patch_compose_for_macos() — disables fail2ban (network_mode:host
#           breaks Docker Desktop on macOS), rewrites OLLAMA_BASE_URL to
#           host.docker.internal for open-webui, litellm, perplexica-backend
# CHANGELOG v1.1 (2026-05-03):
#   BUG-02: LiteLLM health check → /health/readiness
#   BUG-03: Ollama runs NATIVE on macOS (Metal GPU), not in Docker
#   BUG-04: macOS-safe stat flag for .env permission check
#   BUG-05: Dashboard URL → http://localhost:8888
#   BUG-06: Structured install log + trap ERR + auto failure report
#
# NOTE FOR FUTURE FIRMWARE / OS UPGRADES:
#   BUG-01: Re-test fail2ban on macOS if Docker Desktop adds iptables support
#   BUG-03: Re-validate host.docker.internal bridge after macOS 26+ / Ollama 0.21+
#   BUG-04: If GNU coreutils ships natively on future macOS, simplify stat branch
#   BUG-02: Verify /health/readiness path on each LiteLLM major version upgrade
#   BUG-10/15: Re-validate compose defaults if services add new Ollama routes
set -euo pipefail

NON_INTERACTIVE="${HOME_AI_NON_INTERACTIVE:-false}"
SKIP_MODEL_PULLS="${HOME_AI_SKIP_MODEL_PULLS:-false}"
PULL_RECOMMENDED_MODELS="${HOME_AI_PULL_RECOMMENDED_MODELS:-false}"
INSTALL_PROFILE="${HOME_AI_INSTALL_PROFILE:-${HOME_AI_PROFILE:-core}}"
CUSTOM_PROFILES="${HOME_AI_PROFILES:-}"

while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --non-interactive|--yes)
      NON_INTERACTIVE=true
      ;;
    --skip-model-pulls)
      SKIP_MODEL_PULLS=true
      ;;
    --profile=*)
      INSTALL_PROFILE="${arg#--profile=}"
      ;;
    --profile)
      shift
      [[ -n "${1:-}" ]] || { echo "--profile requires a value" >&2; exit 1; }
      INSTALL_PROFILE="$1"
      ;;
    --profiles=*)
      CUSTOM_PROFILES="${arg#--profiles=}"
      INSTALL_PROFILE="custom"
      ;;
    --profiles)
      shift
      [[ -n "${1:-}" ]] || { echo "--profiles requires a comma-separated value" >&2; exit 1; }
      CUSTOM_PROFILES="$1"
      INSTALL_PROFILE="custom"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --non-interactive   Do not prompt for optional API keys or setup choices.
  --skip-model-pulls  Start services without pulling Ollama models.
  --profile <name>    Install profile: core, developer, workstation, server, full, custom.
  --profiles <list>   Custom comma-separated capability profiles: search,automation,coding,security,ops.
  -h, --help          Show this help.

Environment:
  HOME_AI_NON_INTERACTIVE=true
  HOME_AI_SKIP_MODEL_PULLS=true
  HOME_AI_PULL_RECOMMENDED_MODELS=true
  HOME_AI_INSTALL_PROFILE=core
  HOME_AI_PROFILES=search,automation
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
  shift
done

# ── Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
err()    { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()   { echo -e "\n${BLUE}${BOLD}━━━ $1 ━━━${NC}"; }
info()   { echo -e "${CYAN}[i]${NC} $1"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROFILE_LIB="${SCRIPT_DIR}/scripts/profile-lib.sh"
[[ -f "$PROFILE_LIB" ]] || err "Missing profile helper library: ${PROFILE_LIB}"
# shellcheck disable=SC1090
source "$PROFILE_LIB"

# ── BUG-06 FIX: Structured logging + trap ERR + failure report ────────
LOGFILE="${HOME}/.wizard/install.log"
mkdir -p "$(dirname "$LOGFILE")"

log_to_file() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOGFILE"
}

generate_failure_report() {
  # Runs inside trap — do NOT use set -e here
  local REPORT
  REPORT="${SCRIPT_DIR:-$(pwd)}/wizard-failure-report-$(date +%Y%m%d-%H%M%S).txt"
  {
    echo "=== WIZARD AI FAILURE REPORT ==="
    echo "Date: $(date)"
    echo "OS: $(sw_vers 2>/dev/null || uname -a)"
    echo "RAM: ${TOTAL_RAM_GB:-unknown} GB"
    echo "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'not running')"
    echo "Ollama: $(ollama --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "=== INSTALL LOG (last 50 lines) ==="
    tail -50 "$LOGFILE" 2>/dev/null || echo "No log found"
    echo ""
    echo "=== DOCKER SERVICE STATUS ==="
    docker compose ps 2>/dev/null || echo "Docker compose not available"
    echo ""
    echo "=== .ENV KEY STATUS ==="
    grep -E '^[A-Z_]+=' .env 2>/dev/null | while IFS='=' read -r k v; do
      if [[ -n "$v" ]]; then echo "${k}=SET"; else echo "${k}=MISSING"; fi
    done || echo "No .env found"
  } > "$REPORT" 2>/dev/null || true
  echo -e "\n${YELLOW}📋 Failure report saved: ${REPORT}${NC}"
  echo -e "${CYAN}→ Paste this file back to continue debugging${NC}"
}

trap 'EC=$?; log_to_file "[FAIL] Line ${LINENO} exit=${EC}"; \
  echo -e "\n${RED}[✗] Install failed at line ${LINENO} (exit code ${EC})${NC}"; \
  echo -e "${YELLOW}Full log: ${LOGFILE}${NC}"; \
  generate_failure_report' ERR

log_to_file "[START] install.sh v1.6 — $(date)"

# ── Helpers ───────────────────────────────────────────────────────────
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

# ── BUG-01 FIX: Patch runtime config for macOS incompatibilities ──────
# Must be called AFTER .env exists and BEFORE docker compose up.
# Safe to call on Linux — all branches are no-ops when OS != Darwin.
# NOTE FOR FUTURE UPGRADES: Re-test fail2ban if Docker Desktop for macOS
# ever adds iptables/nftables support in the Linux VM.
patch_compose_for_macos() {
  if [[ "$OS" != "Darwin" ]]; then
    return 0
  fi

  step "Patching docker-compose.yml for macOS"
  log_to_file "[STEP] patch_compose_for_macos — applying macOS compatibility patches"

  local COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
  local ENV_FILE="${SCRIPT_DIR}/.env"

  # ── Patch 1: Disable fail2ban (network_mode: host breaks Docker Desktop) ──
  # fail2ban needs iptables which Docker Desktop's Linux VM does not expose.
  # On macOS, silently starting fail2ban causes the entire compose stack to
  # hang on startup waiting for a network namespace that never becomes available.
  if grep -q 'container_name: fail2ban' "$COMPOSE_FILE"; then
    # Add profiles: [linux-only] to fail2ban service so it never starts on macOS
    python3 - <<'PYEOF' "$COMPOSE_FILE"
import sys, re
path = sys.argv[1]
with open(path) as f:
    content = f.read()
# Add profiles: [linux-only] to fail2ban service so it never starts on macOS
content = re.sub(
    r'(  fail2ban:\n    image: crazymax/fail2ban)',
    r'  fail2ban:\n    profiles: ["linux-only"]  # disabled on macOS: network_mode:host unsupported\n    image: crazymax/fail2ban',
    content
)
with open(path, 'w') as f:
    f.write(content)
PYEOF
    warn "fail2ban disabled on macOS (network_mode:host not supported by Docker Desktop)"
    warn "On Linux/VPS deployments, fail2ban runs normally for brute-force protection."
    log_to_file "[PATCH] fail2ban disabled via profiles:linux-only"
  else
    log "fail2ban already patched or not present — skipping"
  fi

  # ── Patch 2: Set OLLAMA_BASE_URL in .env for services reading it ─────
  if [[ ! -f "$ENV_FILE" ]]; then
    warn ".env not found — skipping OLLAMA_BASE_URL patch until environment setup"
  elif grep -q '^OLLAMA_BASE_URL=' "$ENV_FILE" 2>/dev/null; then
    sed -i.bak 's|^OLLAMA_BASE_URL=.*|OLLAMA_BASE_URL=http://host.docker.internal:11434|' "$ENV_FILE" && rm -f "${ENV_FILE}.bak"
  else
    echo "OLLAMA_BASE_URL=http://host.docker.internal:11434" >> "$ENV_FILE"
  fi
  log ".env OLLAMA_BASE_URL → http://host.docker.internal:11434"
  log_to_file "[PATCH] .env OLLAMA_BASE_URL set"

  log "docker-compose.yml patched for macOS ✔"
  log_to_file "[PASS] patch_compose_for_macos complete"
}

header() {
  clear 2>/dev/null || true
  echo -e "${CYAN}"
  echo '  ███╗   ███╗███████╗██████╗ ██╗     ██╗███╗   ██╗'
  echo '  ████╗ ████║██╔════╝██╔══██╗██║     ██║████╗  ██║'
  echo '  ██╔████╔██║█████╗  ██████╔╝██║     ██║██╔██╗ ██║'
  echo '  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║     ██║██║╚██╗██║'
  echo '  ██║ ╚═╝ ██║███████╗██║  ██║███████╗██║██║ ╚████║'
  echo '  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝'
  echo -e "${NC}"
  echo -e "  ${BOLD}Merlin AI — Private Intelligence. Locally Owned.${NC}"
  echo -e "  Sovereign local-first AI command center for owned hardware"
  echo -e "  Version 1.6  |  github.com/TheYfactora12/home-ai-elite\n"
}

header

# ── STEP 1: Preflight Checks ──────────────────────────────────────────
step "Preflight Checks"
log_to_file "[STEP 1] Preflight Checks"

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
log_to_file "[INFO] OS=${OS} RAM=${TOTAL_RAM_GB}GB"

# Model tier selection based on RAM
if   (( TOTAL_RAM_GB >= 48 )); then MODEL_TIER="high";
elif (( TOTAL_RAM_GB >= 24 )); then MODEL_TIER="mid";
elif (( TOTAL_RAM_GB >= 16 )); then MODEL_TIER="base";
elif (( TOTAL_RAM_GB >=  8 )); then MODEL_TIER="low";
else err "Minimum 8 GB RAM required. Detected: ${TOTAL_RAM_GB} GB."
fi
log "Model tier selected: ${MODEL_TIER} (${TOTAL_RAM_GB} GB RAM)"

normalize_profile_name "$INSTALL_PROFILE" || err "Invalid install profile"
INSTALL_CAPABILITIES="$(profile_capabilities_for "$INSTALL_PROFILE" "$CUSTOM_PROFILES")"
INSTALL_CAPABILITIES_CSV="$(csv_from_words "$INSTALL_CAPABILITIES")"

if [[ "$SKIP_MODEL_PULLS" != true && "$PULL_RECOMMENDED_MODELS" != true ]]; then
  if [[ "$NON_INTERACTIVE" == true ]]; then
    SKIP_MODEL_PULLS=true
    warn "Non-interactive install defaults to no model pulls. Set HOME_AI_PULL_RECOMMENDED_MODELS=true to opt in."
  else
    warn "Recommended ${MODEL_TIER} tier models may download several GB."
    read -rp "Pull recommended Ollama models now? [y/N] " MODEL_PULL_CONFIRM
    if [[ "$MODEL_PULL_CONFIRM" =~ ^[Yy]$ ]]; then
      PULL_RECOMMENDED_MODELS=true
    else
      SKIP_MODEL_PULLS=true
      warn "Skipping model pulls. Pull later with: bash scripts/add-model.sh qwen2.5:7b"
    fi
  fi
fi

if [[ "$INSTALL_PROFILE" == "full" && "$NON_INTERACTIVE" != true ]]; then
  warn "Full profile enables every optional service, including OpenHands Docker socket access."
  read -rp "Type full to continue with the full profile: " FULL_CONFIRM
  [[ "$FULL_CONFIRM" == "full" ]] || err "Full profile was not confirmed."
fi
log "Install profile selected: ${INSTALL_PROFILE:-core}"
if [[ -n "$INSTALL_CAPABILITIES" ]]; then
  log "Optional capabilities enabled: ${INSTALL_CAPABILITIES}"
else
  log "Optional capabilities enabled: none"
fi
log_to_file "[INFO] install_profile=${INSTALL_PROFILE} capabilities=${INSTALL_CAPABILITIES:-none}"

# Disk space check (cross-platform: df -k works on macOS and Linux)
AVAIL_DISK_KB=$(df -k . | awk 'NR==2 {print $4}')
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
log_to_file "[PASS] STEP 1: Preflight — Docker ${DOCKER_COMPOSE_VERSION}"

# ── STEP 2: Install Dependencies ──────────────────────────────────────
step "Installing Dependencies"
log_to_file "[STEP 2] Installing Dependencies"

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "Homebrew ready"
  for pkg in git curl jq python3; do
    if command -v "$pkg" &>/dev/null; then
      log "$pkg already installed"
    else
      log "Installing $pkg..."
      brew install "$pkg"
    fi
  done
else
  sudo apt-get update -qq
  for pkg in git curl jq python3; do
    if ! command -v "$pkg" &>/dev/null; then
      sudo apt-get install -y -qq "$pkg"
    fi
    log "$pkg ready"
  done
fi

# ── BUG-03 FIX: Ollama runs NATIVE on macOS for Metal GPU acceleration ──
# NOTE FOR FUTURE UPGRADES: Re-validate after macOS 26+ / Ollama 0.21+
# The host.docker.internal bridge is stable but Docker Desktop networking
# changes between major macOS releases. Test with: curl http://host.docker.internal:11434
if [[ "$OS" == "Darwin" ]]; then
  # Install Ollama natively if not present
  if ! command -v ollama &>/dev/null; then
    log "Installing Ollama natively (required for Apple Metal GPU acceleration)..."
    brew install ollama
  else
    log "Ollama already installed natively ✔"
  fi

  # Ensure native Ollama is running persistently (not Docker).
  if curl -fsS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
    log "Native Ollama already running ✔"
  elif command -v brew >/dev/null 2>&1; then
    log "Starting native Ollama with Homebrew service..."
    brew services start ollama >/dev/null 2>&1 || true
    sleep 5
  fi

  if ! curl -fsS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
    log "Starting native Ollama fallback process..."
    mkdir -p "$HOME/.wizard"
    OLLAMA_HOST=127.0.0.1:11434 nohup ollama serve >> "$HOME/.wizard/ollama.log" 2>&1 &
    OLLAMA_PID=$!
    log_to_file "[INFO] Ollama native fallback PID=${OLLAMA_PID}"
    sleep 4
  fi
fi

log_to_file "[PASS] STEP 2: Dependencies installed"

# ── STEP 2B: Merlin Python Runtime ────────────────────────────────────
step "Installing Merlin Python Runtime"
log_to_file "[STEP 2B] Merlin Python Runtime"

MERLIN_VENV="${SCRIPT_DIR}/.venv"
MERLIN_REQUIREMENTS="${SCRIPT_DIR}/requirements-merlin.txt"

if [[ -f "$MERLIN_REQUIREMENTS" ]]; then
  if [[ ! -x "${MERLIN_VENV}/bin/python" ]]; then
    log "Creating Merlin Python virtual environment..."
    python3 -m venv "$MERLIN_VENV"
  else
    log "Merlin Python virtual environment already exists"
  fi

  if "${MERLIN_VENV}/bin/python" -c 'import yaml, pydantic, fastapi, httpx' >/dev/null 2>&1; then
    log "Merlin Python dependencies already installed"
  else
    log "Installing Merlin Python dependencies..."
    "${MERLIN_VENV}/bin/python" -m pip install --upgrade pip >/dev/null
    "${MERLIN_VENV}/bin/python" -m pip install -r "$MERLIN_REQUIREMENTS"
    log "Merlin Python dependencies installed"
  fi
else
  warn "requirements-merlin.txt missing — Merlin Python runtime may not start"
fi

log_to_file "[PASS] STEP 2B: Merlin Python Runtime ready"

# ── STEP 3: Environment Setup & Secret Hardening ──────────────────────
step "Environment Setup & Secret Hardening"
log_to_file "[STEP 3] Environment Setup"

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

# ── BUG-01 FIX: Patch docker-compose.yml for macOS ───────────────────
# Must run after .env exists so a fresh macOS install does not create a
# partial .env before copying the template.
patch_compose_for_macos

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
rotate_secret "N8N_ENCRYPTION_KEY"
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

# 3d: Verify required config files exist
# ── configs/perplexica/config.toml ──
if [[ ! -f "configs/perplexica/config.toml" ]]; then
  err "configs/perplexica/config.toml not found. This file is required for Perplexica model configuration.
  → Run: cp configs/perplexica/config.toml.example configs/perplexica/config.toml
  → Or re-clone the repo: git clone https://github.com/TheYfactora12/home-ai-elite"
fi
log "configs/perplexica/config.toml found ✔"

# ── BUG-17 FIX: configs/litellm/config.yaml pre-flight guard ──────────
# Without this check, a missing config causes LiteLLM to crash on start,
# and wait_for_service then burns the full 120s timeout with no clear error.
if [[ ! -f "configs/litellm/config.yaml" ]]; then
  err "configs/litellm/config.yaml not found. This file is required for LiteLLM model routing.
  → Run: cp configs/litellm/config.yaml.example configs/litellm/config.yaml
  Then edit it to match your model setup."
fi
log "configs/litellm/config.yaml found ✔"

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

log_to_file "[PASS] STEP 3: Environment & secrets configured"

# ── STEP 4: Pull Ollama Models (RAM-Aware) ────────────────────────────
step "Pulling AI Models (Tier: ${MODEL_TIER} / ${TOTAL_RAM_GB} GB)"
log_to_file "[STEP 4] Model pulls — tier=${MODEL_TIER}"

MODELS_TO_PULL=()

if [[ "$SKIP_MODEL_PULLS" == true ]]; then
  warn "Skipping Ollama model pulls. Pull models later with: bash scripts/add-model.sh <model>"
else
  log "Model pulls explicitly enabled"
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
    [[ "$SKIP_MODEL_PULLS" == true ]] || MODELS_TO_PULL+=("llama3.3:70b" "qwen2.5:32b" "deepseek-r1:32b")
    OPENHANDS_MODEL="ollama/qwen2.5:32b"
    PERPLEXICA_CHAT_MODEL="llama3.3:70b"
    ;;
esac

PERPLEXICA_CONFIG_FILE="./configs/perplexica/config.runtime.toml"

for key_val in \
  "HOME_AI_PROFILE=${INSTALL_PROFILE}" \
  "HOME_AI_PROFILES=${INSTALL_CAPABILITIES_CSV}" \
  "OPENHANDS_MODEL=${OPENHANDS_MODEL}" \
  "PERPLEXICA_CHAT_MODEL=${PERPLEXICA_CHAT_MODEL}" \
  "PERPLEXICA_CONFIG_FILE=${PERPLEXICA_CONFIG_FILE}"; do
  key=$(echo "$key_val" | cut -d= -f1)
  val=$(echo "$key_val" | cut -d= -f2-)
  if grep -q "^${key}" .env; then
    sed -i.bak "s|^${key}=.*|${key}=${val}|" .env && rm -f .env.bak
  else
    echo "${key}=${val}" >> .env
  fi
done

if grep -q "^N8N_SECURE_COOKIE=" .env; then
  log "N8N secure cookie mode: $(grep '^N8N_SECURE_COOKIE=' .env | cut -d= -f2-) (preserved)"
else
  echo "N8N_SECURE_COOKIE=false" >> .env
  log "N8N secure cookie mode: false (local HTTP)"
fi

log "OpenHands model: ${OPENHANDS_MODEL}"
log "Perplexica chat model: ${PERPLEXICA_CHAT_MODEL}"

if [[ -f "configs/perplexica/config.toml" ]]; then
  cp configs/perplexica/config.toml "${PERPLEXICA_CONFIG_FILE}"
  sed -i.bak "s|^CHAT_MODEL = .*|CHAT_MODEL = \"${PERPLEXICA_CHAT_MODEL}\"|" \
    "${PERPLEXICA_CONFIG_FILE}" && rm -f "${PERPLEXICA_CONFIG_FILE}.bak"
fi

# ── BUG-03: Pull models via native Ollama (not Docker exec) ──────────
if (( ${#MODELS_TO_PULL[@]} > 0 )); then
  for model in "${MODELS_TO_PULL[@]}"; do
    log "Pulling ${model} via native Ollama (Metal GPU)..."
    log_to_file "[INFO] Pulling model: ${model}"
    if ! ollama pull "$model"; then
      warn "Failed to pull ${model} — skipping. Pull manually: bash scripts/add-model.sh ${model}"
      log_to_file "[WARN] Model pull failed: ${model}"
    else
      log_to_file "[PASS] Model pulled: ${model}"
    fi
  done
fi

log_to_file "[PASS] STEP 4: Models"

# ── STEP 5: Docker Compose Up ─────────────────────────────────────────
step "Pulling Docker Images & Starting Profile Services"
log_to_file "[STEP 5] Docker Compose up"

if [[ "$OS" == "Darwin" ]]; then
  PROFILE_SERVICES=()
  while IFS= read -r service; do
    PROFILE_SERVICES+=("$service")
  done < <(profile_services_for_darwin "$INSTALL_CAPABILITIES")
  docker compose pull --quiet "${PROFILE_SERVICES[@]}"
else
  COMPOSE_PROFILE_FLAGS=()
  while IFS= read -r compose_profile; do
    [[ -n "$compose_profile" ]] && COMPOSE_PROFILE_FLAGS+=(--profile "$compose_profile")
  done < <(compose_profiles_for_linux "$INSTALL_CAPABILITIES")
  PROFILE_SERVICES=()
  while IFS= read -r service; do
    PROFILE_SERVICES+=("$service")
  done < <(profile_services_for_linux "$INSTALL_CAPABILITIES")
  docker compose "${COMPOSE_PROFILE_FLAGS[@]}" pull --quiet "${PROFILE_SERVICES[@]}"
fi
log "Images pulled"

# ── BUG-09 FIX: Complete KNOWN_CONTAINERS list ────────────────────────
# BUG-09 ROOT CAUSE: openhands was missing from this list.
# "container name /openhands already in use" occurred because the pre-flight
# check skipped it — leaving a stale container that blocked compose up.
#
# This list must match ALL container_name values in docker-compose.yml.
# Rule: any time a new service is added to docker-compose.yml with an
# explicit container_name, add it here too.
#
# Safe on first-time installs — docker rm -f on a non-existent container
# exits 1 but we suppress it with `|| true`.
log_to_file "[INFO] BUG-09: pre-flight stale container removal (complete list)"
KNOWN_CONTAINERS=(
  # Core AI services
  openhands
  open-webui
  ollama
  litellm
  # Search
  perplexica-frontend
  perplexica-backend
  searxng
  # Automation & memory
  n8n
  qdrant
  # Infrastructure
  nginx
  nginx-proxy
  swarm-dashboard
  watchtower
  fail2ban
)
for cname in "${KNOWN_CONTAINERS[@]}"; do
  if docker inspect "$cname" &>/dev/null; then
    warn "Removing stale container: ${cname}"
    docker rm -f "$cname" 2>/dev/null || true
    log_to_file "[INFO] Removed stale container: ${cname}"
  fi
done
log "Pre-flight stale container check complete"

log_to_file "[INFO] docker compose up — flags: --remove-orphans --force-recreate"

if [[ "$OS" == "Darwin" ]]; then
  log "macOS: Skipping Ollama Docker container — using native Ollama on host"
  docker compose up -d --remove-orphans --force-recreate --no-deps "${PROFILE_SERVICES[@]}"
else
  docker compose "${COMPOSE_PROFILE_FLAGS[@]}" up -d --remove-orphans --force-recreate --no-deps "${PROFILE_SERVICES[@]}"
fi

log_to_file "[PASS] STEP 5: Docker compose up complete"

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
      log_to_file "[WARN] ${name} health check TIMEOUT after ${max_wait}s"
      return 0
    fi
  done
  echo " ✓"
  log_to_file "[PASS] ${name} health check OK"
  return 0
}

# Wait for native Ollama on macOS (Step 5 — before compose services come up)
if [[ "$OS" == "Darwin" ]]; then
  wait_for_service "Ollama (native)" "http://localhost:11434" 90
fi

log_to_file "[PASS] STEP 5: Docker services up"

# ── STEP 6: Health Checks ─────────────────────────────────────────────
step "Waiting for Services to be Ready"
log_to_file "[STEP 6] Health checks"

# BUG-11 FIX: Single Ollama health check — removed duplicate from Step 5.
# On macOS, Ollama is already verified above before compose starts.
# On Linux, Ollama runs in Docker and is checked here once.
wait_for_service "Ollama"        "http://localhost:11434"           60
# BUG-02 FIX: Use /health/readiness — does NOT make live LLM calls.
wait_for_service "LiteLLM"       "http://localhost:4000/health/readiness" 120
wait_for_service "Open WebUI"    "http://localhost:3000"            90
wait_for_service "Qdrant"        "http://localhost:6333/healthz"    60
if [[ " ${INSTALL_CAPABILITIES} " == *" search "* ]]; then
  wait_for_service "SearXNG"     "http://localhost:8080"            60
fi
if [[ " ${INSTALL_CAPABILITIES} " == *" automation "* ]]; then
  # BUG-16 FIX: Use /healthz endpoint now that n8n healthcheck is defined in compose.
  wait_for_service "n8n"         "http://localhost:5678/healthz"    90
fi

log_to_file "[PASS] STEP 6: All health checks complete"

# ── STEP 7: First-Boot Init (bootstrap) ────────────────────────────────
step "First-Boot Initialization"
log_to_file "[STEP 7] First-boot bootstrap"

FIRST_BOOT_FLAG="${SCRIPT_DIR}/.wizard-bootstrapped"
BOOTSTRAP_NEEDED=false
if [[ ! -f "$FIRST_BOOT_FLAG" ]]; then
  BOOTSTRAP_NEEDED=true
elif ! curl -fsS --max-time 3 "http://localhost:6333/collections/home_ai_memory" >/dev/null 2>&1; then
  warn "Bootstrap marker exists but Qdrant collections are missing — re-running bootstrap"
  BOOTSTRAP_NEEDED=true
elif ! curl -fsS --max-time 3 "http://localhost:6333/collections/merlin_session" >/dev/null 2>&1; then
  warn "Bootstrap marker exists but Merlin canonical collections are missing — re-running bootstrap"
  BOOTSTRAP_NEEDED=true
fi

if [[ "$BOOTSTRAP_NEEDED" == true ]]; then
  if [[ -f "scripts/bootstrap.sh" ]]; then
    log "Running first-boot bootstrap (Qdrant collections + n8n workflows)..."
    # BUG-18 FIX: Verbose failure messaging so user knows exactly what to do.
    if HOME_AI_STACK_DIR="${SCRIPT_DIR}" \
      HOME_AI_PROFILE="${INSTALL_PROFILE}" \
      HOME_AI_PROFILES="${INSTALL_CAPABILITIES_CSV}" \
      HOME_AI_SKIP_MODEL_PULLS="${SKIP_MODEL_PULLS}" \
      MERLIN_CREATE_CANONICAL_COLLECTIONS=true \
      bash "${SCRIPT_DIR}/scripts/bootstrap.sh"; then
      touch "$FIRST_BOOT_FLAG"
      log "Bootstrap complete"
      log_to_file "[PASS] STEP 7: Bootstrap complete"
    else
      warn "💥 Bootstrap reported issues — check log: ${LOGFILE}"
      warn "Re-run manually: bash scripts/bootstrap.sh"
      warn "The AI stack WILL start but Qdrant collections and n8n workflows may be missing."
      warn "Memory/RAG features will not work until bootstrap completes successfully."
      log_to_file "[WARN] STEP 7: Bootstrap failed — manual action required"
    fi
  else
    warn "scripts/bootstrap.sh not found — run manually after install"
  fi
else
  log "Already bootstrapped — skipping (delete .wizard-bootstrapped to force re-run)"
  log_to_file "[INFO] STEP 7: Already bootstrapped — skipped"
fi

# ── STEP 8: Install wizard CLI system-wide ──────────────────────────────
step "Installing wizard CLI"
log_to_file "[STEP 8] CLI install"

CLI_PATH="${SCRIPT_DIR}/cli/wizard"
if [[ -f "$CLI_PATH" ]]; then
  chmod +x "$CLI_PATH"
  if [[ -w "/usr/local/bin" ]]; then
    ln -sf "$CLI_PATH" /usr/local/bin/wizard
    log "wizard CLI installed → /usr/local/bin/wizard"
  elif [[ "$NON_INTERACTIVE" == true || ! -t 0 ]]; then
    warn "/usr/local/bin is not writable; skipping system-wide wizard symlink in non-interactive mode"
    warn "Use directly for now: ${CLI_PATH}"
    log_to_file "[WARN] STEP 8: CLI symlink skipped; /usr/local/bin not writable"
  else
    sudo ln -sf "$CLI_PATH" /usr/local/bin/wizard
    log "wizard CLI installed → /usr/local/bin/wizard (via sudo)"
  fi
  if command -v wizard >/dev/null 2>&1; then
    log "Run: wizard status  |  wizard ask \"<question>\"  |  wizard help"
  else
    log "Run: ${CLI_PATH} status  |  ${CLI_PATH} ask \"<question>\"  |  ${CLI_PATH} help"
  fi
  log_to_file "[PASS] STEP 8: CLI installed"
else
  warn "cli/wizard not found at ${CLI_PATH}"
  warn "CLI not installed. To fix: ensure cli/wizard exists and re-run install.sh"
  warn "Manual workaround: bash ${SCRIPT_DIR}/scripts/status.sh"
  log_to_file "[WARN] STEP 8: CLI not found at ${CLI_PATH}"
fi

# ── STEP 8B: Start read-only Merlin status API ────────────────────────
step "Starting Merlin Status API"
log_to_file "[STEP 8B] Merlin status API"

MERLIN_STATUS_API_STARTED=false
if [[ -f "${SCRIPT_DIR}/scripts/merlin-status-api.sh" ]]; then
  if [[ "$NON_INTERACTIVE" == true || ! -t 0 ]]; then
    warn "Skipped direct Merlin Status API background start in non-interactive mode"
    warn "Run manually: bash scripts/merlin-status-api.sh start"
    warn "For persistent login startup: bash launchd/install-launchd.sh"
    log_to_file "[WARN] STEP 8B: Merlin status API start skipped in non-interactive mode"
  elif bash "${SCRIPT_DIR}/scripts/merlin-status-api.sh" start >/dev/null 2>&1; then
    MERLIN_STATUS_API_STARTED=true
    log "Merlin Status API running → http://localhost:8765/status"
    log_to_file "[PASS] STEP 8B: Merlin status API running"
  else
    warn "Merlin Status API did not start — run manually: bash scripts/merlin-status-api.sh start"
    log_to_file "[WARN] STEP 8B: Merlin status API did not start"
  fi
else
  warn "scripts/merlin-status-api.sh not found — skipping Merlin Status API startup"
  log_to_file "[WARN] STEP 8B: merlin-status-api.sh missing"
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
log_to_file "[STEP 11] Security review"

SECURITY_PASS=true

for key in WEBUI_SECRET_KEY LITELLM_MASTER_KEY N8N_PASSWORD SEARXNG_SECRET_KEY; do
  val=$(grep "^${key}=" .env | cut -d= -f2- || true)
  for bad in "change-me-in-env" "change-me-run-openssl-rand-hex-32" "sk-home-ai-elite" "changeme" ""; do
    if [[ "$val" == "$bad" ]]; then
      warn "SECURITY: ${key} is still at insecure default! Run: openssl rand -hex 32"
      SECURITY_PASS=false
    fi
  done
done

# BUG-04 FIX: macOS-safe .env permission check
if [[ "$OS" == "Darwin" ]]; then
  ENV_PERMS=$(stat -f "%OLp" .env 2>/dev/null || echo "unknown")
else
  ENV_PERMS=$(stat -c "%a" .env 2>/dev/null || echo "unknown")
fi

if [[ "$ENV_PERMS" != "600" ]]; then
  warn "SECURITY: .env permissions are ${ENV_PERMS}, expected 600. Fixing..."
  chmod 600 .env
  log ".env permissions corrected to 600"
else
  log ".env permissions: 600 ✔"
fi

if grep -q "^\.env$" .gitignore 2>/dev/null; then
  log ".env is in .gitignore ✔"
else
  warn "SECURITY: .env is NOT in .gitignore! Adding now..."
  echo ".env" >> .gitignore
  log ".env added to .gitignore"
fi

if [[ "$SECURITY_PASS" == true ]]; then
  log "Security review passed ✔"
  log_to_file "[PASS] STEP 11: Security review passed"
else
  warn "Security review found issues above — resolve before exposing to any network"
  log_to_file "[WARN] STEP 11: Security review found issues"
fi

# ── STEP 12: Done — Print Dashboard ───────────────────────────────────
log_to_file "[DONE] install.sh completed successfully"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║     WIZARD AI IS READY  ✓  v1.6                         ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Install Profile:${NC} ${INSTALL_PROFILE} (${INSTALL_CAPABILITIES:-core only})"
echo -e "  ${BOLD}Running Services:${NC}"
echo -e "  ${CYAN}🧠 Chat (Open WebUI):${NC}       http://localhost:3000"
echo -e "  ${CYAN}📦 Vector Memory (Qdrant):${NC}  http://localhost:6333"
echo -e "  ${CYAN}🔀 Model Router (LiteLLM):${NC}  http://localhost:4000"
echo -e "  ${CYAN}📊 Dashboard (Wizard HQ):${NC}   http://localhost:8888"
if [[ "$MERLIN_STATUS_API_STARTED" == true ]]; then
  echo -e "  ${CYAN}🩺 Merlin Status API:${NC}       http://localhost:8765/status"
else
  echo -e "  ${YELLOW}! Merlin Status API:${NC}       not started; run: bash scripts/merlin-status-api.sh start"
  echo -e "  ${YELLOW}! Persistent Status API:${NC}   optional launchd setup: bash launchd/install-launchd.sh"
fi
echo -e "  ${YELLOW}! Merlin Task API:${NC}         not directly started; run: bash scripts/merlin-task-api.sh start"
if [[ " ${INSTALL_CAPABILITIES} " == *" search "* ]]; then
  echo -e "  ${CYAN}🔍 Search AI (Perplexica):${NC}  http://localhost:3002"
  echo -e "  ${CYAN}🔎 Private Search (SearXNG):${NC} http://localhost:8080"
fi
if [[ " ${INSTALL_CAPABILITIES} " == *" automation "* ]]; then
  echo -e "  ${CYAN}⚙️  Automation (n8n):${NC}         http://localhost:5678"
fi
if [[ " ${INSTALL_CAPABILITIES} " == *" coding "* ]]; then
  echo -e "  ${CYAN}💻 Codex Agent (OpenHands):${NC} http://localhost:3003"
fi
echo ""
echo -e "  ${BOLD}Hardware Tier:${NC} ${MODEL_TIER} (${TOTAL_RAM_GB} GB RAM)"
echo -e "  ${BOLD}Coding Model:${NC}  ${OPENHANDS_MODEL}"
echo -e "  ${BOLD}Chat Model:${NC}    ${PERPLEXICA_CHAT_MODEL}"
echo ""
echo -e "  ${GREEN}✓  All internal secrets auto-generated${NC}"
echo -e "  ${GREEN}✓  .env locked to 600 (owner only)${NC}"
if [[ "$NON_INTERACTIVE" == true ]]; then
  echo -e "  ${GREEN}✓  Optional cloud API keys skipped (local-first default)${NC}"
else
  echo -e "  ${GREEN}✓  Optional cloud API keys handled in hidden mode${NC}"
fi
echo -e "  ${GREEN}✓  Security review complete${NC}"
echo -e "  ${GREEN}✓  Install log: ${LOGFILE}${NC}"
echo -e "  ${GREEN}✓  Read-only Merlin status is separated from task execution${NC}"
echo ""
echo -e "  ${BOLD}First commands to run:${NC}"
if command -v wizard >/dev/null 2>&1; then
  echo -e "  ${CYAN}wizard status${NC}                    → full stack health check"
  echo -e "  ${CYAN}wizard merlin status-api status${NC}  → confirm read-only Merlin status API"
  echo -e "  ${CYAN}wizard open${NC}                      → open Wizard HQ in browser"
else
  echo -e "  ${CYAN}${CLI_PATH} status${NC}               → full stack health check"
  echo -e "  ${CYAN}${CLI_PATH} merlin status-api status${NC} → confirm read-only Merlin status API"
  echo -e "  ${CYAN}${CLI_PATH} open${NC}                 → open Wizard HQ in browser"
fi
echo -e "  ${CYAN}bash scripts/merlin-task-api.sh start${NC}       → optional supervised Merlin Task API on :8766"
echo ""
echo -e "  ${BOLD}First-time setup steps:${NC}"
echo -e "  1. http://localhost:3000  → create your admin account"
echo -e "     ${YELLOW}⚠ Settings → Admin → disable Sign Up (lock it down)${NC}"
echo -e "  2. Pull a low-tier model when ready: bash scripts/add-model.sh qwen2.5:7b"
if [[ " ${INSTALL_CAPABILITIES} " == *" search "* ]]; then
  echo -e "  3. http://localhost:3002  → test Perplexica web search"
fi
if [[ " ${INSTALL_CAPABILITIES} " == *" coding "* ]]; then
  echo -e "  4. http://localhost:3003  → give OpenHands a coding task"
fi
if [[ " ${INSTALL_CAPABILITIES} " == *" automation "* ]]; then
  echo -e "  5. http://localhost:5678  → n8n workflows already imported by bootstrap"
fi
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
