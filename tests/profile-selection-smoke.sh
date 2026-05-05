#!/usr/bin/env bash
# Smoke-test install profile capability and service mappings without Docker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${STACK_DIR}/scripts/profile-lib.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

join_lines() {
  awk '{printf "%s%s", sep, $0; sep=" "}'
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  [[ "$actual" == "$expected" ]] || fail "${label}: expected '${expected}', got '${actual}'"
}

assert_capabilities() {
  local profile="$1"
  local custom="${2:-}"
  local expected="$3"
  local actual
  actual="$(profile_capabilities_for "$profile" "$custom")"
  assert_eq "$actual" "$expected" "${profile} capabilities"
}

assert_services() {
  local os="$1"
  local capabilities="$2"
  local expected="$3"
  local actual
  if [[ "$os" == "darwin" ]]; then
    actual="$(profile_services_for_darwin "$capabilities" | join_lines)"
  else
    actual="$(profile_services_for_linux "$capabilities" | join_lines)"
  fi
  assert_eq "$actual" "$expected" "${os} services for '${capabilities}'"
}

assert_capabilities core "" ""
assert_capabilities developer "" "search"
assert_capabilities workstation "" "search automation"
assert_capabilities server "" "search automation security ops"
assert_capabilities full "" "search automation coding security ops"
assert_capabilities custom "search,coding" "search coding"

assert_services darwin "" "dashboard qdrant litellm open-webui"
assert_services darwin "search automation" "dashboard qdrant litellm open-webui searxng perplexica-backend perplexica-frontend n8n"
assert_services darwin "search automation coding security ops" "dashboard qdrant litellm open-webui searxng perplexica-backend perplexica-frontend n8n openhands nginx watchtower"

assert_services linux "" "ollama dashboard qdrant litellm open-webui"
assert_services linux "search automation" "ollama dashboard qdrant litellm open-webui searxng perplexica-backend perplexica-frontend n8n"
assert_services linux "search automation coding security ops" "ollama dashboard qdrant litellm open-webui searxng perplexica-backend perplexica-frontend n8n openhands nginx fail2ban watchtower"

LINUX_PROFILES="$(compose_profiles_for_linux "search automation security ops" | join_lines)"
assert_eq "$LINUX_PROFILES" "docker-ollama linux-security" "linux compose profiles"

CSV="$(csv_from_words "search automation coding")"
assert_eq "$CSV" "search,automation,coding" "capability csv"

echo "PASS: installer profile mappings are valid"
