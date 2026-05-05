#!/usr/bin/env bash
# Shared install/profile mapping helpers.

profile_error() {
  echo "[profile] ERROR: $*" >&2
  return 1
}

normalize_profile_name() {
  local profile="$1"
  case "$profile" in
    core|developer|workstation|server|full|custom)
      return 0
      ;;
    *)
      profile_error "Unknown install profile: ${profile}. Use core, developer, workstation, server, full, or custom."
      ;;
  esac
}

profile_capabilities_for() {
  local profile="$1"
  local custom_profiles="${2:-}"

  case "$profile" in
    core)
      echo ""
      ;;
    developer)
      echo "search"
      ;;
    workstation)
      echo "search automation"
      ;;
    server)
      echo "search automation security ops"
      ;;
    full)
      echo "search automation coding security ops"
      ;;
    custom)
      echo "$custom_profiles" | tr ',' ' '
      ;;
    *)
      profile_error "Unknown install profile: ${profile}"
      ;;
  esac
}

csv_from_words() {
  echo "$1" | awk '{$1=$1; gsub(/ /,","); print}'
}

profile_services_for_darwin() {
  local capabilities="$1"
  local services=(dashboard qdrant litellm open-webui)
  local capability

  for capability in $capabilities; do
    case "$capability" in
      search)
        services+=(searxng perplexica-backend perplexica-frontend)
        ;;
      automation)
        services+=(n8n)
        ;;
      coding)
        services+=(openhands)
        ;;
      security)
        services+=(nginx)
        ;;
      ops)
        services+=(watchtower)
        ;;
      "")
        ;;
      *)
        profile_error "Unknown capability in profile list: ${capability}"
        return 1
        ;;
    esac
  done

  printf '%s\n' "${services[@]}"
}

profile_services_for_linux() {
  local capabilities="$1"
  local services=(ollama dashboard qdrant litellm open-webui)
  local capability

  for capability in $capabilities; do
    case "$capability" in
      search)
        services+=(searxng perplexica-backend perplexica-frontend)
        ;;
      automation)
        services+=(n8n)
        ;;
      coding)
        services+=(openhands)
        ;;
      security)
        services+=(nginx fail2ban)
        ;;
      ops)
        services+=(watchtower)
        ;;
      "")
        ;;
      *)
        profile_error "Unknown capability in profile list: ${capability}"
        return 1
        ;;
    esac
  done

  printf '%s\n' "${services[@]}"
}

compose_profiles_for_linux() {
  local capabilities="$1"
  local profiles=(docker-ollama)
  local capability

  for capability in $capabilities; do
    case "$capability" in
      security|server|ops)
        profiles+=(linux-security)
        ;;
    esac
  done

  printf '%s\n' "${profiles[@]}" | awk '!seen[$0]++'
}
