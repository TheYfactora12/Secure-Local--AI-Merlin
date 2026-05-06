#!/usr/bin/env bash
# =============================================================================
# import-n8n-workflows.sh — Auto-import n8n workflows via REST API
#
# Strategy (validated against ai-launchkit & n8n community patterns):
#   1. Wait for n8n to be healthy
#   2. Create an API key on first boot (n8n >=1.x supports this via env)
#   3. POST each workflow JSON in n8n-workflows/ via /api/v1/workflows
#   4. Optionally activate workflows tagged "auto-start"
#
# Reference:
#   https://docs.n8n.io/api/
#   https://community.n8n.io/t/automate-creation-of-n8n-workflows-via-agents/118650
#   https://n8n.io/workflows/3996-auto-start-tagged-workflows
# =============================================================================
set -euo pipefail

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../n8n-workflows" && pwd)"
MAX_WAIT=120
INTERVAL=5

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

log()  { echo -e "${COLOR_GREEN}[n8n-import]${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}[n8n-import]${COLOR_RESET} $*"; }
fail() { echo -e "${COLOR_RED}[n8n-import]${COLOR_RESET} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Wait for n8n API to respond
# ---------------------------------------------------------------------------
wait_for_n8n() {
  log "Waiting for n8n at $N8N_URL ..."
  local elapsed=0
  until curl -sf "${N8N_URL}/healthz" >/dev/null 2>&1; do
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
    if [[ $elapsed -ge $MAX_WAIT ]]; then
      fail "n8n did not become ready within ${MAX_WAIT}s."
    fi
    warn "  still waiting... (${elapsed}s)"
  done
  log "n8n is ready."
}

# ---------------------------------------------------------------------------
# Check API key is set
# ---------------------------------------------------------------------------
check_api_key() {
  if [[ -z "$N8N_API_KEY" ]]; then
    warn "N8N_API_KEY is not set in .env — skipping workflow import."
    warn "To enable auto-import:"
    warn "  1. Start n8n and log in at ${N8N_URL}"
    warn "  2. Settings → API Keys → Create key"
    warn "  3. Add N8N_API_KEY=<your-key> to .env"
    warn "  4. Re-run: bash scripts/import-n8n-workflows.sh"
    exit 0
  fi
}

# ---------------------------------------------------------------------------
# Import a single workflow JSON file
# Returns 0 on success/already-exists, 1 on error
# ---------------------------------------------------------------------------
import_workflow() {
  local file="$1"
  local name
  name=$(basename "$file" .json)

  # Extract just the fields n8n POST /api/v1/workflows expects
  # (name, nodes, connections, settings, staticData, tags, meta)
  local payload
  payload=$(jq '{name,nodes,connections,settings,staticData,tags,meta}' "$file" 2>/dev/null) || {
    warn "  Skipping '$name' — not valid JSON"
    return 1
  }

  # Check if workflow with same name already exists
  local existing
  existing=$(curl -sf \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    "${N8N_URL}/api/v1/workflows?name=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$name")" \
    2>/dev/null | jq -r '.data[0].id // empty' 2>/dev/null || true)

  if [[ -n "$existing" ]]; then
    log "  Workflow '$name' already exists (id=$existing) — skipping."
    return 0
  fi

  local http_code
  http_code=$(curl -sf -o /tmp/n8n_import_response.json -w "%{http_code}" \
    -X POST "${N8N_URL}/api/v1/workflows" \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    -H 'Content-Type: application/json' \
    -d "$payload" 2>/dev/null || echo "000")

  if [[ "$http_code" =~ ^2 ]]; then
    local wf_id
    wf_id=$(jq -r '.id // "?"' /tmp/n8n_import_response.json 2>/dev/null || echo "?")
    log "  ✅ Imported '$name' (id=$wf_id)"
  else
    warn "  ⚠️  Failed to import '$name' (HTTP $http_code)"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Activate workflows tagged "auto-start"
# Pattern from: https://n8n.io/workflows/3996
# ---------------------------------------------------------------------------
activate_tagged_workflows() {
  log "Activating workflows tagged 'auto-start'..."
  local workflows
  workflows=$(curl -sf \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    "${N8N_URL}/api/v1/workflows?limit=100" \
    2>/dev/null | jq -r '.data[] | select(.tags[]?.name == "auto-start") | .id' 2>/dev/null || true)

  if [[ -z "$workflows" ]]; then
    log "  No workflows tagged 'auto-start' found."
    return
  fi

  while IFS= read -r wf_id; do
    curl -sf -o /dev/null \
      -X PATCH "${N8N_URL}/api/v1/workflows/${wf_id}" \
      -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
      -H 'Content-Type: application/json' \
      -d '{"active": true}' 2>/dev/null && \
      log "  ✅ Activated workflow id=$wf_id" || \
      warn "  ⚠️  Could not activate id=$wf_id"
  done <<< "$workflows"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  wait_for_n8n
  check_api_key

  if [[ ! -d "$WORKFLOW_DIR" ]]; then
    warn "Workflow directory not found: $WORKFLOW_DIR"
    exit 0
  fi

  local files=()
  while IFS= read -r file; do
    [[ -n "$file" ]] && files+=("$file")
  done < <(find "$WORKFLOW_DIR" -maxdepth 2 -name '*.json' | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    warn "No .json workflow files found in $WORKFLOW_DIR"
    exit 0
  fi

  log "Found ${#files[@]} workflow file(s) to import..."
  local ok=0 skip=0 fail_count=0

  for file in "${files[@]}"; do
    if import_workflow "$file"; then
      ((ok++)) || true
    else
      ((fail_count++)) || true
    fi
  done

  activate_tagged_workflows

  log ""
  log "✅ n8n workflow import complete."
  log "   Imported: ${ok} | Failed: ${fail_count}"
  log "   Dashboard: ${N8N_URL}"
}

main "$@"
