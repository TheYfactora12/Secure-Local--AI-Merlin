#!/usr/bin/env bash
# Merlin AI — Pull latest Docker images and restart
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PROFILE_LIB="${STACK_DIR}/scripts/profile-lib.sh"

# shellcheck disable=SC1090
source "$PROFILE_LIB"

INSTALL_PROFILE="${HOME_AI_INSTALL_PROFILE:-core}"
CUSTOM_PROFILES="${HOME_AI_PROFILES:-}"

usage() {
  cat <<'USAGE'
Usage: bash scripts/update.sh [--profile <name>] [--profiles <list>]

Options:
  --profile <name>   Update/start profile: core, developer, workstation, server, full, custom.
  --profiles <list>  Custom comma-separated capabilities: search,automation,coding,security,ops.
  -h, --help         Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      INSTALL_PROFILE="${2:-}"
      shift 2
      ;;
    --profiles)
      CUSTOM_PROFILES="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

normalize_profile_name "$INSTALL_PROFILE" >/dev/null
CAPABILITIES="$(profile_capabilities_for "$INSTALL_PROFILE" "$CUSTOM_PROFILES")"

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

ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop, then re-run this script." >&2
  exit 1
}

cd "$STACK_DIR"
echo "Pulling latest images for profile: ${INSTALL_PROFILE}"
if [[ "$(uname -s)" == "Darwin" ]]; then
  SERVICES=()
  while IFS= read -r service; do
    SERVICES+=("$service")
  done < <(profile_services_for_darwin "$CAPABILITIES")
  docker compose pull "${SERVICES[@]}"
  echo "Restarting profile services with new images..."
  docker compose up -d "${SERVICES[@]}"
else
  SERVICES=()
  PROFILES=()
  while IFS= read -r service; do
    SERVICES+=("$service")
  done < <(profile_services_for_linux "$CAPABILITIES")
  while IFS= read -r profile; do
    PROFILES+=(--profile "$profile")
  done < <(compose_profiles_for_linux "$CAPABILITIES")
  docker compose "${PROFILES[@]}" pull "${SERVICES[@]}"
  echo "Restarting profile services with new images..."
  docker compose "${PROFILES[@]}" up -d "${SERVICES[@]}"
fi
echo "Update complete. Run: bash scripts/status.sh"
