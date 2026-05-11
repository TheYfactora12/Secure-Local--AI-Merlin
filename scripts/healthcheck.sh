#!/usr/bin/env bash
# merlin-ai — Healthcheck + uptime webhook ping (v0.7)
# Run by launchd or manually. Checks all services and pings
# a webhook URL if everything is healthy.
# Set HEALTHCHECK_WEBHOOK_URL in .env to enable pinging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")")" && cd "${SCRIPT_DIR}/.."

# Load .env if present
[ -f .env ] && source .env

WEBHOOK_URL="${HEALTHCHECK_WEBHOOK_URL:-}"
FAIL=0

# ───────────────────────
check_http() {
  local name="$1"
  local url="$2"
  shift 2
  if curl -sf --max-time 5 "$@" "${url}" > /dev/null 2>&1; then
    echo "✅ ${name} healthy"
  else
    echo "❌ ${name} not responding (${url})"
    FAIL=1
  fi
}

# ───────────────────────
echo ""
echo "📊 merlin-ai healthcheck — $(date)"
echo "──────────────────────────────"

check_http "Ollama"       "http://localhost:11434"
check_http "Open WebUI"   "http://localhost:3000"
check_http "Perplexica"   "http://localhost:3002"
check_http "n8n"          "http://localhost:5678"
check_http "Qdrant"       "http://localhost:6333"
check_http "SearXNG"      "http://localhost:8080"
check_http "LiteLLM"      "http://localhost:4000"
if [[ "${HOME_AI_OBSERVABILITY_PROFILE_ACTIVE:-false}" == "true" ]] || \
   docker compose ps --services --filter status=running 2>/dev/null | grep -qx 'langfuse-web'; then
  check_http "Langfuse"   "http://localhost:${LANGFUSE_PORT:-3010}/api/public/health"
else
  echo "ℹ️  Langfuse observability disabled; skipping health check"
fi
check_http "Nginx HTTPS"  "https://localhost" --insecure 2>/dev/null || true

echo "──────────────────────────────"

if [ $FAIL -eq 0 ]; then
  echo "🎉 All services healthy"
  # Ping uptime webhook if configured
  if [ -n "${WEBHOOK_URL}" ]; then
    curl -sf "${WEBHOOK_URL}" > /dev/null 2>&1 \
      && echo "✅ Uptime webhook pinged: ${WEBHOOK_URL}" \
      || echo "⚠️  Webhook ping failed (non-fatal)"
  fi
else
  echo "❌ One or more services are unhealthy — run: bash scripts/restart.sh"
  exit 1
fi
