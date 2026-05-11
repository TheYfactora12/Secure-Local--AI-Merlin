#!/usr/bin/env bash
# Merlin AI — start optional observability profile intentionally.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

ram_gb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    local bytes
    bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    awk -v b="$bytes" 'BEGIN {printf "%d", b/1024/1024/1024}'
  elif [[ -r /proc/meminfo ]]; then
    awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo
  else
    echo 0
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

require_env_key() {
  local key="$1"
  if ! grep -Eq "^${key}=.+" "${STACK_DIR}/.env" 2>/dev/null; then
    echo "Missing ${key} in .env" >&2
    return 1
  fi
}

cat <<'TXT'
Observability profile starts self-hosted Langfuse plus Postgres, ClickHouse,
Redis, and MinIO. This is optional and not recommended for 8GB low/core installs.
TXT

RAM_GB="$(ram_gb)"
if (( RAM_GB < 16 )) && [[ "${HOME_AI_ALLOW_LOW_TIER_OBSERVABILITY:-false}" != "true" ]]; then
  cat >&2 <<EOF
Refusing to start observability on ${RAM_GB}GB RAM.
8GB/low tier remains JSONL-only by default.
Set HOME_AI_ALLOW_LOW_TIER_OBSERVABILITY=true only for an explicit local test.
EOF
  exit 1
fi

if [[ "${HOME_AI_ASSUME_YES:-false}" != "true" ]]; then
  printf "Start optional observability profile? [y/N] "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

cd "$STACK_DIR"

if [[ ! -f .env ]]; then
  echo ".env missing. Run bash install.sh first, then add Langfuse keys from configs/langfuse/langfuse.env.example." >&2
  exit 1
fi

REQUIRED_KEYS=(
  LANGFUSE_SALT
  LANGFUSE_ENCRYPTION_KEY
  LANGFUSE_NEXTAUTH_SECRET
  LANGFUSE_POSTGRES_PASSWORD
  LANGFUSE_CLICKHOUSE_PASSWORD
  LANGFUSE_REDIS_AUTH
  LANGFUSE_MINIO_ROOT_PASSWORD
)

MISSING=0
for key in "${REQUIRED_KEYS[@]}"; do
  require_env_key "$key" || MISSING=1
done

if (( MISSING != 0 )); then
  cat >&2 <<'EOF'
Add missing keys to .env first. Example names are in:
  configs/langfuse/langfuse.env.example
EOF
  exit 1
fi

ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run." >&2
  exit 1
}

docker info >/dev/null 2>&1 || {
  echo "Docker engine not running. Start Docker Desktop, then re-run." >&2
  exit 1
}

echo "Starting optional observability profile..."
docker compose \
  -f docker-compose.yml \
  -f docker-compose.observability.yml \
  --profile observability \
  up -d langfuse-web langfuse-worker

echo "Observability profile started."
echo "Langfuse: http://localhost:${LANGFUSE_PORT:-3010}"
echo "JSONL baseline remains available: wizard score; wizard trace <id>"
