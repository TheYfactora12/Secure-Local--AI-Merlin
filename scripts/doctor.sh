#!/usr/bin/env bash
# Home AI Elite — read-only environment and safety diagnostic
# Usage: bash scripts/doctor.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
ENV_FILE="${STACK_DIR}/.env"
MODEL_TIERS_FILE="${MERLIN_MODEL_TIERS_FILE:-${STACK_DIR}/config/merlin/model-tiers.env}"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'; DIM='\033[2m'

PASS=0
WARN=0
FAIL=0
NEXT_COMMAND=""

pass() { echo -e "  ${GREEN}✓${NC} $*"; PASS=$((PASS + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $*"; WARN=$((WARN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL + 1)); }
info() { echo -e "  ${DIM}-${NC} $*"; }

set_next_command() {
  if [[ -z "$NEXT_COMMAND" ]]; then
    NEXT_COMMAND="$*"
  fi
}

ensure_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi

  local docker_app_cli="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${docker_app_cli}/docker" ]]; then
    export PATH="${docker_app_cli}:$PATH"
    return 0
  fi

  return 1
}

env_value() {
  local key="$1"
  if [[ ! -f "$ENV_FILE" ]]; then
    echo ""
    return 0
  fi
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

ram_gb() {
  local bytes
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if bytes="$(sysctl -n hw.memsize 2>/dev/null)" && [[ "$bytes" =~ ^[0-9]+$ ]]; then
      awk -v bytes="$bytes" 'BEGIN {printf "%d", bytes / 1024 / 1024 / 1024}'
    else
      echo 0
    fi
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "%d", $2 / 1024 / 1024}' /proc/meminfo
  else
    echo 0
  fi
}

hardware_tier() {
  local ram="$1"
  if (( ram <= 0 )); then echo unknown
  elif (( ram >= 48 )); then echo high
  elif (( ram >= 24 )); then echo mid
  elif (( ram >= 16 )); then echo base
  elif (( ram >= 8 )); then echo low
  else echo unsupported
  fi
}

check_http() {
  local label="$1"
  local url="$2"
  if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
    pass "$label reachable ($url)"
  else
    warn "$label not reachable ($url)"
  fi
}

http_ok() {
  local url="$1"
  curl -fsS --max-time 2 "$url" >/dev/null 2>&1
}

secret_status() {
  local key="$1"
  local val
  if [[ ! -f "$ENV_FILE" ]]; then
    info "$key skipped because .env does not exist yet"
    return
  fi
  val="$(env_value "$key")"
  case "$val" in
    "" )
      fail "$key is missing or empty"
      ;;
    change-me-*|changeme|sk-home-ai-elite|REQUIRED_CHANGE_ME )
      fail "$key appears to be an insecure default"
      ;;
    * )
      pass "$key is set"
      ;;
  esac
}

optional_key_status() {
  local key="$1"
  local val
  val="$(env_value "$key")"
  if [[ -n "$val" ]]; then
    warn "$key is set; cloud/API use must remain explicit"
  else
    pass "$key empty (local-first default)"
  fi
}

check_bind() {
  local key="$1"
  local val
  val="$(env_value "$key")"
  if [[ "$val" == "0.0.0.0" ]]; then
    fail "$key=0.0.0.0 exposes a service beyond localhost"
  elif [[ -n "$val" ]]; then
    pass "$key=$val"
  else
    pass "$key default is localhost"
  fi
}

recommended_models_for_tier() {
  local tier="$1"
  case "$tier" in
    low) printf '%s\n' "${MERLIN_LOW_MODELS[@]:-qwen2.5:7b}" ;;
    base) printf '%s\n' "${MERLIN_BASE_MODELS[@]:-qwen2.5:7b}" ;;
    mid) printf '%s\n' "${MERLIN_MID_MODELS[@]:-qwen2.5:32b}" ;;
    high) printf '%s\n' "${MERLIN_HIGH_MODELS[@]:-qwen2.5:32b}" ;;
    *) printf '%s\n' "${MERLIN_UNKNOWN_MODELS[@]:-qwen2.5:7b}" ;;
  esac
}

installed_ollama_models() {
  if command -v ollama >/dev/null 2>&1; then
    ollama list 2>/dev/null | awk 'NR > 1 {print $1}' || true
    return 0
  fi

  if command -v python3 >/dev/null 2>&1 && http_ok "http://localhost:11434/api/tags"; then
    curl -fsS --max-time 3 "http://localhost:11434/api/tags" 2>/dev/null | \
      python3 -c 'import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    data={}
for model in data.get("models", []):
    name=model.get("name")
    if name:
        print(name)' || true
  fi
}

model_is_installed() {
  local wanted="$1"
  local installed="$2"
  echo "$installed" | grep -Fxq "$wanted"
}

if [[ -f "$MODEL_TIERS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$MODEL_TIERS_FILE"
else
  MERLIN_LOW_MODELS=("qwen2.5:7b" "nomic-embed-text")
  MERLIN_BASE_MODELS=("qwen2.5:7b" "qwen2.5-coder:7b" "nomic-embed-text")
  MERLIN_MID_MODELS=("qwen2.5:32b" "qwen2.5-coder:14b" "nomic-embed-text")
  MERLIN_HIGH_MODELS=("qwen2.5:32b" "deepseek-r1:32b" "nomic-embed-text")
  MERLIN_UNKNOWN_MODELS=("qwen2.5:7b" "nomic-embed-text")
fi

echo -e "\n${CYAN}${BOLD}HOME AI ELITE — Merlin Doctor${NC}"
echo -e "$(date)\n"

echo -e "${BOLD}Repository${NC}"
[[ -d "$STACK_DIR" ]] && pass "Stack directory exists: $STACK_DIR" || fail "Stack directory missing: $STACK_DIR"
[[ -f "${STACK_DIR}/install.sh" ]] && pass "install.sh present" || fail "install.sh missing"
[[ -f "${STACK_DIR}/docker-compose.yml" ]] && pass "docker-compose.yml present" || fail "docker-compose.yml missing"
[[ -f "${STACK_DIR}/config/merlin/profiles.yaml" ]] && pass "Merlin profiles config present" || warn "Merlin profiles config missing"
[[ -f "${STACK_DIR}/config/merlin/hardware-tiers.yaml" ]] && pass "Merlin hardware tiers config present" || warn "Merlin hardware tiers config missing"
[[ -f "${STACK_DIR}/config/merlin/model-tiers.env" ]] && pass "Merlin model tier runtime manifest present" || warn "Merlin model tier runtime manifest missing"
[[ -f "${STACK_DIR}/config/merlin/memory.yaml" ]] && pass "Merlin memory schema config present" || warn "Merlin memory schema config missing"
[[ -f "${STACK_DIR}/config/merlin/memory-collections.env" ]] && pass "Merlin memory runtime manifest present" || warn "Merlin memory runtime manifest missing"

echo -e "\n${BOLD}System${NC}"
OS="$(uname -s)"
RAM_GB="$(ram_gb)"
TIER="$(hardware_tier "$RAM_GB")"
pass "OS: $OS"
if [[ "$TIER" == "unknown" ]]; then
  warn "RAM could not be detected in this shell"
elif [[ "$TIER" == "unsupported" ]]; then
  fail "RAM: ${RAM_GB}GB is below minimum supported tier"
else
  pass "RAM: ${RAM_GB}GB (${TIER} tier)"
fi
DISK_GB="$(df -k "$STACK_DIR" | awk 'NR==2 {printf "%d", $4 / 1024 / 1024}')"
if (( DISK_GB < 30 )); then
  warn "Disk space low: ${DISK_GB}GB available"
else
  pass "Disk space: ${DISK_GB}GB available"
fi

case "$TIER" in
  low)
    warn "Low tier should avoid OpenHands, full search stack, n8n automation, and 14B+ models by default"
    ;;
  base)
    info "Base tier should run core first; enable search/coding only when needed"
    ;;
  mid|high)
    info "${TIER} tier can support optional profiles with approval gates"
    ;;
esac

echo -e "\n${BOLD}Docker${NC}"
if ensure_docker_cli; then
  pass "Docker CLI found: $(docker --version 2>/dev/null || echo unknown)"
  if docker info >/dev/null 2>&1; then
    pass "Docker engine running"
    if (cd "$STACK_DIR" && docker compose config --quiet >/dev/null 2>&1); then
      pass "docker-compose.yml validates"
    else
      fail "docker-compose.yml failed validation"
    fi
  else
    warn "Docker engine not running"
    set_next_command "Open Docker Desktop, then run: wizard doctor"
  fi
else
  if [[ "$OS" == "Darwin" && -d "/Applications/Docker.app" ]]; then
    fail "Docker Desktop is installed but Docker CLI was not found at /Applications/Docker.app/Contents/Resources/bin/docker"
  else
    fail "Docker CLI not found"
  fi
  set_next_command "Install Docker Desktop, then run: wizard doctor"
fi

echo -e "\n${BOLD}Ollama${NC}"
if command -v ollama >/dev/null 2>&1; then
  pass "Ollama CLI found"
else
  warn "Ollama CLI not found"
  if [[ "$OS" == "Darwin" ]]; then
    set_next_command "Run: brew install ollama"
  fi
fi
check_http "Ollama API" "http://localhost:11434/api/tags"

echo -e "\n${BOLD}Models${NC}"
INSTALLED_MODELS="$(installed_ollama_models)"
if [[ -z "$INSTALLED_MODELS" ]]; then
  warn "No installed Ollama models detected"
  info "Recommended ${TIER} tier pulls:"
  while IFS= read -r model; do
    [[ -n "$model" ]] && info "bash scripts/add-model.sh ${model}"
  done < <(recommended_models_for_tier "$TIER")
else
  MODEL_COUNT="$(echo "$INSTALLED_MODELS" | sed '/^$/d' | wc -l | tr -d ' ')"
  pass "Installed Ollama models detected: ${MODEL_COUNT}"
  while IFS= read -r model; do
    [[ -n "$model" ]] && info "Installed: ${model}"
  done <<< "$INSTALLED_MODELS"

  MISSING_MODELS=()
  while IFS= read -r model; do
    [[ -z "$model" ]] && continue
    if model_is_installed "$model" "$INSTALLED_MODELS"; then
      pass "Recommended model installed: ${model}"
    else
      MISSING_MODELS+=("$model")
    fi
  done < <(recommended_models_for_tier "$TIER")

  if [[ "${#MISSING_MODELS[@]}" -gt 0 ]]; then
    warn "Missing ${TIER} tier recommended model(s): ${MISSING_MODELS[*]}"
    for model in "${MISSING_MODELS[@]}"; do
      info "bash scripts/add-model.sh ${model}"
    done
  fi
fi

echo -e "\n${BOLD}Environment${NC}"
if [[ -f "$ENV_FILE" ]]; then
  pass ".env exists"
  if [[ "$OS" == "Darwin" ]]; then
    PERMS="$(stat -f "%OLp" "$ENV_FILE" 2>/dev/null || echo unknown)"
  else
    PERMS="$(stat -c "%a" "$ENV_FILE" 2>/dev/null || echo unknown)"
  fi
  [[ "$PERMS" == "600" ]] && pass ".env permissions are 600" || warn ".env permissions are $PERMS; expected 600"
else
  warn ".env missing; installer has not been run in this checkout"
  set_next_command "Run: bash install.sh --skip-model-pulls"
fi

for key in WEBUI_SECRET_KEY LITELLM_MASTER_KEY N8N_PASSWORD N8N_ENCRYPTION_KEY SEARXNG_SECRET_KEY; do
  secret_status "$key"
done

for key in OPENAI_API_KEY ANTHROPIC_API_KEY PERPLEXITY_API_KEY GITHUB_TOKEN; do
  optional_key_status "$key"
done

echo -e "\n${BOLD}Network Bindings${NC}"
for key in DASHBOARD_BIND OPEN_WEBUI_BIND PERPLEXICA_BACKEND_BIND PERPLEXICA_FRONTEND_BIND OPENHANDS_BIND SEARXNG_BIND LITELLM_BIND N8N_BIND QDRANT_BIND OLLAMA_BIND; do
  check_bind "$key"
done

echo -e "\n${BOLD}Service Health${NC}"
check_http "Dashboard" "http://localhost:8888"
check_http "Open WebUI" "http://localhost:3000"
check_http "LiteLLM" "http://localhost:4000/health/readiness"
check_http "Qdrant" "http://localhost:6333/healthz"
check_http "SearXNG" "http://localhost:8080"
check_http "Perplexica" "http://localhost:3002"
check_http "n8n" "http://localhost:5678/healthz"
check_http "OpenHands" "http://localhost:3003"

echo -e "\n${BOLD}Profile Safety${NC}"
if ensure_docker_cli && docker info >/dev/null 2>&1; then
  RUNNING_SERVICES="$(cd "$STACK_DIR" && docker compose ps --services --filter status=running 2>/dev/null || true)"
  if [[ -z "$RUNNING_SERVICES" ]]; then
    info "No Compose services are currently running"
  fi
  for svc in openhands n8n perplexica-backend perplexica-frontend searxng watchtower nginx; do
    if echo "$RUNNING_SERVICES" | grep -qx "$svc"; then
      if [[ "$TIER" == "low" && "$svc" != "nginx" ]]; then
        warn "$svc is running on low tier; consider core-only mode"
      else
        info "$svc running"
      fi
    fi
  done
else
  info "Skipping running service profile checks because Docker is unavailable"
fi

echo -e "\n${BOLD}Summary${NC}"
echo -e "  Passed: ${GREEN}${PASS}${NC}  Warnings: ${YELLOW}${WARN}${NC}  Failures: ${RED}${FAIL}${NC}"

echo -e "\n${BOLD}Next Command${NC}"
if [[ -n "$NEXT_COMMAND" ]]; then
  echo "  $NEXT_COMMAND"
elif [[ ! -f "$ENV_FILE" ]]; then
  echo "  bash install.sh --skip-model-pulls"
elif (( FAIL > 0 )); then
  echo "  Fix the required items above, then run: wizard doctor"
elif (( WARN > 0 )); then
  echo "  Review warnings, then run: bash scripts/status.sh"
else
  echo "  bash scripts/status.sh"
fi

if (( FAIL > 0 )); then
  echo -e "\n${RED}${BOLD}Doctor found required fixes.${NC}"
  exit 1
elif (( WARN > 0 )); then
  echo -e "\n${YELLOW}${BOLD}Doctor found warnings. Review before enabling heavier Merlin profiles.${NC}"
  exit 0
else
  echo -e "\n${GREEN}${BOLD}Doctor passed.${NC}"
  exit 0
fi
