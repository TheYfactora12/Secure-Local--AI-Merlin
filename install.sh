#!/usr/bin/env bash
# Home AI Elite — interactive one-shot installer
# Usage: bash install.sh
# Repo: https://github.com/TheYfactora12/home-ai-elite
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log(){ echo -e "${GREEN}[INFO]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){ echo -e "${RED}[ERR]${NC} $1"; }
step(){ echo -e "${BLUE}\n==> $1${NC}"; }
ask(){ local p="$1" d="${2:-}" v; if [[ -n "$d" ]]; then read -r -p "$p [$d]: " v; echo "${v:-$d}"; else read -r -p "$p: " v; echo "$v"; fi; }
ask_secret(){ local p="$1" v; read -r -s -p "$p: " v; echo; echo "$v"; }
confirm(){ local p="$1" a; read -r -p "$p [y/N]: " a; [[ "$a" =~ ^[Yy]$ ]]; }
random_secret(){ python3 -c "import secrets; print(secrets.token_urlsafe(32))"; }
check_port(){ lsof -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }
require_macos(){ [[ "$(uname)" == "Darwin" ]] || { err "macOS only."; exit 1; }; }
check_arch(){ [[ "$(uname -m)" == "arm64" ]] || warn "Apple Silicon recommended; continuing on $(uname -m)."; }
check_ram(){ sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024/1024)}'; }
check_disk(){ df -g "$HOME" | awk 'NR==2{print $4}'; }

ensure_brew(){
  if ! command -v brew >/dev/null 2>&1; then
    step "Homebrew not found"
    confirm "Install Homebrew now?" || { err "Homebrew required."; exit 1; }
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

ensure_docker(){
  if ! command -v docker >/dev/null 2>&1; then
    step "Docker Desktop required — manual step"
    echo ""
    echo "  1. Download Docker Desktop: https://www.docker.com/products/docker-desktop/"
    echo "  2. Open Docker Desktop and wait until the whale icon shows green."
    echo ""
    confirm "Press y once Docker Desktop is running" || { err "Docker required."; exit 1; }
  fi
}

wait_for_docker(){
  local tries=0
  until docker info >/dev/null 2>&1; do
    tries=$((tries+1))
    (( tries > 40 )) && { err "Docker not responding. Start Docker Desktop and rerun."; exit 1; }
    warn "Waiting for Docker engine... ($tries/40)"
    sleep 3
  done
  log "Docker engine ready."
}

ensure_ollama(){
  command -v ollama >/dev/null 2>&1 || brew install ollama
  brew services start ollama || true
  sleep 3
  log "Ollama service started."
}

write_env(){
  cat > "$STACK_DIR/.env" <<ENVEOF
OPENAI_API_KEY=$OPENAI_API_KEY
PERPLEXITY_API_KEY=$PERPLEXITY_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET
QDRANT_COLLECTION=$QDRANT_COLLECTION
DEFAULT_LOCAL_MODEL=$DEFAULT_LOCAL_MODEL
DEFAULT_CODER_MODEL=$DEFAULT_CODER_MODEL
DEFAULT_EMBED_MODEL=$DEFAULT_EMBED_MODEL
INSTALL_PROFILE=$INSTALL_PROFILE
ENABLE_OPENHANDS=$ENABLE_OPENHANDS
ENVEOF
  log ".env written."
}

write_compose(){
  cp "$(dirname "$0")/docker-compose.base.yml" "$STACK_DIR/docker-compose.yml"
  if [[ "$ENABLE_OPENHANDS" == "yes" ]]; then
    cat "$(dirname "$0")/docker-compose.openhands.yml" >> "$STACK_DIR/docker-compose.yml"
    log "OpenHands added to compose."
  fi
}

write_scripts(){
  mkdir -p "$STACK_DIR/scripts" "$STACK_DIR/data"/{qdrant,n8n,open-webui,openhands} "$STACK_DIR/backups" "$STACK_DIR/logs"
  cp -r "$(dirname "$0")/scripts/" "$STACK_DIR/scripts/"
  chmod +x "$STACK_DIR"/scripts/*.sh
  log "Scripts installed."
}

write_templates(){
  mkdir -p "$STACK_DIR/templates" "$STACK_DIR/n8n-workflows"
  cp -r "$(dirname "$0")/templates/" "$STACK_DIR/templates/"
  cp -r "$(dirname "$0")/n8n-workflows/" "$STACK_DIR/n8n-workflows/"
  log "Templates and starter workflows installed."
}

write_manifest(){
  cat > "$STACK_DIR/install-manifest.txt" <<MANIFEST
Installed On: $(date)
Install Profile: $INSTALL_PROFILE
Stack Directory: $STACK_DIR
Local Model: $DEFAULT_LOCAL_MODEL
Coder Model: $DEFAULT_CODER_MODEL
Embedding Model: $DEFAULT_EMBED_MODEL
Qdrant Collection: $QDRANT_COLLECTION
Enable OpenHands: $ENABLE_OPENHANDS
RAM GB Detected: $RAM_GB
Disk Free GB Detected: $DISK_GB
OpenAI key set: $([[ -n "$OPENAI_API_KEY" ]] && echo yes || echo no)
Perplexity key set: $([[ -n "$PERPLEXITY_API_KEY" ]] && echo yes || echo no)
Anthropic key set: $([[ -n "$ANTHROPIC_API_KEY" ]] && echo yes || echo no)
MANIFEST
  log "Manifest written."
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
require_macos
check_arch

step "Home AI Elite Builder"
echo "This interactive installer sets up a local-first home AI stack on macOS."
echo "Answer the prompts. Manual checkpoints will pause and wait for you."
echo ""

RAM_GB=$(check_ram)
DISK_GB=$(check_disk)
step "Preflight"
log "RAM: ${RAM_GB} GB  |  Free disk: ${DISK_GB} GB"
(( RAM_GB < 16 )) && warn "16 GB+ recommended for local models."
(( RAM_GB < 32 )) && warn "32 GB+ preferred for 32B parameter models."
(( DISK_GB < 30 )) && warn "30 GB+ free disk recommended."
for p in 3000 3001 5678 6333 11434; do
  check_port "$p" && warn "Port $p is already in use — check before continuing." || true
done

step "Configuration"
INSTALL_PROFILE=$(ask "Install profile" "standard")
STACK_DIR=$(ask "Install location" "$HOME/home-ai-elite")
DEFAULT_LOCAL_MODEL=$(ask "Default local reasoning model" "qwen3:32b")
DEFAULT_CODER_MODEL=$(ask "Default coding model" "qwen3-coder")
DEFAULT_EMBED_MODEL=$(ask "Default embedding model" "nomic-embed-text")
QDRANT_COLLECTION=$(ask "Qdrant memory collection name" "home_ai_memory")
ENABLE_OPENHANDS=$(ask "Install OpenHands autonomous coding agent? (yes/no)" "no")
N8N_ENCRYPTION_KEY=$(ask "n8n encryption key" "$(random_secret)")
N8N_USER_MANAGEMENT_JWT_SECRET=$(ask "n8n JWT secret" "$(random_secret)")

step "Cloud API keys (optional — press Enter to skip each)"
OPENAI_API_KEY=$(ask_secret "OpenAI API key")
PERPLEXITY_API_KEY=$(ask_secret "Perplexity API key")
ANTHROPIC_API_KEY=$(ask_secret "Anthropic API key")

step "Installing dependencies"
ensure_brew
brew update -q
brew install git jq python@3.11 node uv ollama 2>/dev/null || true

step "Docker Desktop"
ensure_docker
wait_for_docker

step "Ollama service"
ensure_ollama

step "Writing stack to $STACK_DIR"
mkdir -p "$STACK_DIR"
write_env
write_compose
write_scripts
write_templates
write_manifest

step "Launching services"
"$STACK_DIR/scripts/bootstrap.sh"

step "Manual app setup"
"$STACK_DIR/scripts/next-steps.sh"

echo ""
log "Install complete."
echo "  Status:  $STACK_DIR/scripts/status.sh"
echo "  Backup:  $STACK_DIR/scripts/backup.sh"
echo "  Manifest: $STACK_DIR/install-manifest.txt"
echo "  Repo:    https://github.com/TheYfactora12/home-ai-elite"
