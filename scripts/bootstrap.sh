#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Idempotent first-boot initializer for home-ai-elite
#
# Safe to run multiple times. Each step checks if work is already done.
#
# Steps:
#   1. Preflight — verify Docker is running
#   2. Start Docker Compose stack
#   3. Wait for Qdrant to be healthy
#   4. Create Qdrant collections if missing
#   5. Wait for n8n to be healthy
#   6. Import n8n workflows (if N8N_API_KEY set and workflows exist)
#   7. Pull default Ollama model if none present
#   8. Print service URLs
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"
ENV_FILE="${STACK_DIR}/.env"
WORKFLOW_DIR="${STACK_DIR}/n8n-workflows"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-home_ai_memory}"
QDRANT_VECTOR_SIZE="${QDRANT_VECTOR_SIZE:-768}"
N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-llama3.2}"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; CYAN="\033[0;36m"
BOLD="\033[1m"; RESET="\033[0m"

log()    { echo -e "${GREEN}[bootstrap]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[bootstrap]${RESET} $*"; }
banner() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${RESET}\n"; }
fail()   { echo "[bootstrap] ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
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

wait_for_http() {
  local url="$1"
  local label="$2"
  local max_attempts="${3:-60}"
  log "Waiting for $label"
  for i in $(seq 1 "$max_attempts"); do
    if curl -fsS --max-time 3 "$url" >/dev/null 2>&1; then
      log "  ✅ $label is ready"
      return 0
    fi
    [[ $((i % 10)) -eq 0 ]] && log "  ... still waiting ($i/${max_attempts})"
    sleep 2
  done
  warn "$label did not become ready in $((max_attempts * 2))s — continuing anyway"
  return 1
}

qdrant_collection_exists() {
  curl -fsS --max-time 5 "${QDRANT_URL}/collections/$1" >/dev/null 2>&1
}

qdrant_create_collection() {
  local name="$1"
  local size="${2:-$QDRANT_VECTOR_SIZE}"
  log "Creating Qdrant collection: $name (size=$size, Cosine distance)"
  curl -fsS -X PUT "${QDRANT_URL}/collections/${name}" \
    -H 'Content-Type: application/json' \
    --data-raw "{\"vectors\":{\"size\":${size},\"distance\":\"Cosine\"}}" >/dev/null
  log "  ✅ Created: $name"
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo -e "${CYAN}${BOLD}"
echo "  ┌──────────────────────────────────────┐"
echo "  │  home-ai-elite bootstrap           │"
echo "  └──────────────────────────────────────┘"
echo -e "${RESET}"

# ---------------------------------------------------------------------------
# Step 1: Preflight
# ---------------------------------------------------------------------------
banner "Step 1/7: Preflight"
[[ -d "$STACK_DIR" ]] || fail "Missing $STACK_DIR — re-run the installer"
[[ -f "$COMPOSE_FILE" ]] || fail "Missing docker-compose.yml"
ensure_docker_cli || fail "Docker CLI not found — install Docker Desktop first"
docker info >/dev/null 2>&1 || fail "Docker engine not running — open Docker Desktop first"
log "  ✅ Preflight passed"

# Create .env from example if missing
if [[ ! -f "$ENV_FILE" ]]; then
  cp "${STACK_DIR}/.env.example" "$ENV_FILE"
  log "  ✅ .env created from .env.example"
  warn "  Edit ~/home-ai-elite/.env to add your API keys (optional)"
fi

# Source .env so N8N_API_KEY and QDRANT_* overrides are picked up
set -a
# shellcheck disable=SC1090
source "$ENV_FILE" 2>/dev/null || true
set +a

# ---------------------------------------------------------------------------
# Step 2: Start stack
# ---------------------------------------------------------------------------
banner "Step 2/7: Starting Services"
cd "$STACK_DIR" || exit 1
docker compose up -d
log "  ✅ docker compose up -d complete"

# ---------------------------------------------------------------------------
# Step 3: Wait for Qdrant
# ---------------------------------------------------------------------------
banner "Step 3/7: Qdrant Initialization"
wait_for_http "${QDRANT_URL}/collections" "Qdrant"

# Create the default memory collection
if qdrant_collection_exists "$QDRANT_COLLECTION"; then
  log "  Collection '$QDRANT_COLLECTION' already exists — skipping"
else
  qdrant_create_collection "$QDRANT_COLLECTION" "$QDRANT_VECTOR_SIZE"
fi

# Create additional collections if defined in .env
# Format: EXTRA_QDRANT_COLLECTIONS="collection1:512,collection2:1536"
if [[ -n "${EXTRA_QDRANT_COLLECTIONS:-}" ]]; then
  IFS=',' read -ra EXTRA_COLS <<< "$EXTRA_QDRANT_COLLECTIONS"
  for col_def in "${EXTRA_COLS[@]}"; do
    col_name="$(echo "$col_def" | cut -d: -f1)"
    col_size="$(echo "$col_def" | cut -d: -f2)"
    if qdrant_collection_exists "$col_name"; then
      log "  Collection '$col_name' already exists — skipping"
    else
      qdrant_create_collection "$col_name" "${col_size:-768}"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Step 4: Wait for n8n
# ---------------------------------------------------------------------------
banner "Step 4/7: n8n Initialization"
wait_for_http "${N8N_URL}/healthz" "n8n" 60 || \
  wait_for_http "${N8N_URL}" "n8n (root)" 30 || true

# ---------------------------------------------------------------------------
# Step 5: Import n8n workflows
# ---------------------------------------------------------------------------
banner "Step 5/7: n8n Workflow Import"
if [[ -z "$N8N_API_KEY" ]]; then
  warn "N8N_API_KEY not set in .env — skipping workflow import"
  warn "To import: set N8N_API_KEY in .env and re-run bootstrap.sh"
elif [[ ! -d "$WORKFLOW_DIR" ]]; then
  warn "No workflows dir found at $WORKFLOW_DIR — skipping"
else
  shopt -s nullglob
  WORKFLOWS=("$WORKFLOW_DIR"/*.json)
  if [[ ${#WORKFLOWS[@]} -eq 0 ]]; then
    warn "No .json workflow files found in $WORKFLOW_DIR"
  else
    log "Found ${#WORKFLOWS[@]} workflow(s) to import"
    for wf in "${WORKFLOWS[@]}"; do
      name="$(basename "$wf")"
      HTTP_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" \
        -X POST "${N8N_URL}/api/v1/workflows" \
        -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        --data-binary @"$wf" 2>/dev/null || echo "000")
      if [[ "$HTTP_STATUS" =~ ^2 ]]; then
        log "  ✅ Imported: $name"
      else
        warn "  Import returned HTTP $HTTP_STATUS for $name (may already exist)"
      fi
    done
  fi
fi

# ---------------------------------------------------------------------------
# Step 6: Ollama model check
# ---------------------------------------------------------------------------
banner "Step 6/7: Ollama Models"
if docker compose ps ollama >/dev/null 2>&1; then
  MODEL_COUNT=$(docker compose exec -T ollama ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  if [[ "$MODEL_COUNT" -eq 0 ]]; then
    log "Pulling default model: $OLLAMA_DEFAULT_MODEL"
    docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL" || warn "Model pull failed — retry with: bash scripts/add-model.sh $OLLAMA_DEFAULT_MODEL"
  else
    log "  ✅ $MODEL_COUNT Ollama model(s) already present — skipping pull"
  fi
else
  warn "Ollama container not running — open http://localhost:11434 after the stack starts"
fi

# ---------------------------------------------------------------------------
# Step 7: Print service URLs
# ---------------------------------------------------------------------------
banner "Step 7/7: Your Services Are Ready"
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  SERVICE               URL                 ║"
echo "  ╠══════════════════════════════════════════╣"
echo "  ║  Open WebUI            http://localhost:3000 ║"
echo "  ║  Perplexica Search     http://localhost:3002 ║"
echo "  ║  OpenHands Agent       http://localhost:3003 ║"
echo "  ║  n8n Automation        http://localhost:5678 ║"
echo "  ║  Qdrant Dashboard      http://localhost:6333 ║"
echo "  ║  SearXNG               http://localhost:8080 ║"
echo "  ║  LiteLLM Router        http://localhost:4000 ║"
echo "  ║  Ollama API            http://localhost:11434 ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
log "Bootstrap complete. Run: bash tests/e2e-test.sh to verify."
