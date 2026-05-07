#!/usr/bin/env bash
# Verify optional Compose services stay behind explicit profiles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

services="$(cd "$STACK_DIR" && docker compose config --services)"

for service in dashboard qdrant litellm open-webui; do
  echo "$services" | grep -qx "$service" || fail "default Compose config missing core service: $service"
done

for service in searxng perplexica-backend perplexica-frontend n8n openhands nginx watchtower ollama fail2ban; do
  if echo "$services" | grep -qx "$service"; then
    fail "default Compose config includes optional service: $service"
  fi
done

search_services="$(cd "$STACK_DIR" && docker compose --profile search config --services)"
for service in searxng perplexica-backend perplexica-frontend; do
  echo "$search_services" | grep -qx "$service" || fail "search profile missing service: $service"
done

automation_services="$(cd "$STACK_DIR" && docker compose --profile automation config --services)"
echo "$automation_services" | grep -qx "n8n" || fail "automation profile missing n8n"

coding_services="$(cd "$STACK_DIR" && docker compose --profile coding config --services)"
echo "$coding_services" | grep -qx "openhands" || fail "coding profile missing openhands"

security_services="$(cd "$STACK_DIR" && docker compose --profile security --profile linux-security config --services)"
echo "$security_services" | grep -qx "nginx" || fail "security profile missing nginx"
echo "$security_services" | grep -qx "fail2ban" || fail "linux-security profile missing fail2ban"

ops_services="$(cd "$STACK_DIR" && docker compose --profile ops config --services)"
echo "$ops_services" | grep -qx "watchtower" || fail "ops profile missing watchtower"

echo "PASS: Compose optional services are profile-gated"
