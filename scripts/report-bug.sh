#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
# Source redact helper
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/redact.sh"

# Arg parsing
CREATE_ISSUE=false
FAILING_CMD="not specified"
EXIT_CODE="not specified"
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --create-issue) CREATE_ISSUE=true ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
[[ "${#POSITIONAL[@]}" -ge 1 ]] && FAILING_CMD="${POSITIONAL[0]}"
[[ "${#POSITIONAL[@]}" -ge 2 ]] && EXIT_CODE="${POSITIONAL[1]}"

detect_component() {
  case "$1" in
    *install.sh*) echo "installer" ;;
    *wizard*) echo "cli" ;;
    *docker*) echo "docker" ;;
    *) echo "unknown" ;;
  esac
}

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
hardware_tier() {
  local r="$1"
  if (( r >= 48 )); then echo high
  elif (( r >= 24 )); then echo mid
  elif (( r >= 16 )); then echo base
  elif (( r >= 8 )); then echo low
  else echo unsupported
  fi
}

http_status() {
  curl -fsS --max-time 2 "$1" >/dev/null 2>&1 && echo "reachable" || echo "unreachable"
}

installer_version() {
  local line
  line="$(grep -m1 '^#' "${STACK_DIR}/install.sh" 2>/dev/null || true)"
  if [[ -n "$line" ]]; then
    echo "$line" | sed 's/^#[[:space:]]*//'
  else
    echo "unknown"
  fi
}

RAM="$(ram_gb)"; TIER="$(hardware_tier "$RAM")"
DISK_GB="$(df -k "$STACK_DIR" | awk 'NR==2 {printf "%d", $4/1024/1024}')"
COMMIT="$(git -C "$STACK_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
OS_STR="$(uname -s) $(uname -r)"
ARCH="$(uname -m)"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
COMPONENT="$(detect_component "$FAILING_CMD")"
SUGGESTED_TITLE="fix(${COMPONENT}): ${FAILING_CMD} failed on $(uname -s) (${TIER} tier)"

env_keys_report() {
  local example="${STACK_DIR}/.env.example"
  local envfile="${STACK_DIR}/.env"
  local key
  if [[ ! -f "$example" ]]; then
    echo "- .env.example not found"
    return
  fi
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    key="${line%%=*}"
    [[ -z "$key" ]] && continue
    if [[ ! -f "$envfile" ]]; then
      echo "- ${key}: MISSING (.env not found)"
    elif [[ "$(grep -c "^${key}=" "$envfile" 2>/dev/null || true)" -gt 0 ]]; then
      echo "- ${key}: PRESENT"
    else
      echo "- ${key}: MISSING"
    fi
  done < "$example"
}

log_errors_report() {
  local logdir="${STACK_DIR}/logs"
  local lines=""
  local logfile
  [[ -d "$logdir" ]] || { echo "No recent errors found"; return; }
  while IFS= read -r logfile; do
    while IFS= read -r line; do
      lines+="${line}"$'\n'
    done < <(tail -50 "$logfile" 2>/dev/null | grep -E "ERROR|CRITICAL" || true)
  done < <(find "$logdir" -maxdepth 1 \( -name "*.log" -o -name "*.jsonl" \) 2>/dev/null || true)
  if [[ -z "$lines" ]]; then
    echo "No recent errors found"
  else
    echo "$lines" | head -10 | redact_string
  fi
}

# Build report
REPORT="$(cat <<REPORT
# Merlin Bug Report

## Header
- Timestamp: ${TIMESTAMP}
- Commit: ${COMMIT}
- Installer version: $(installer_version)

## Environment
- OS: ${OS_STR}
- Arch: ${ARCH}
- Docker: $(docker --version 2>/dev/null || echo "not found")
- Compose: $(docker compose version 2>/dev/null || echo "not found")

## Hardware
- RAM: ${RAM}GB (${TIER} tier)
- Disk free: ${DISK_GB}GB

## .env Key Presence
$(env_keys_report)

## Service Health
| Service | Status |
|---------|--------|
| Ollama (11434) | $(http_status "http://localhost:11434") |
| LiteLLM (4000) | $(http_status "http://localhost:4000/health/readiness") |
| Qdrant (6333) | $(http_status "http://localhost:6333/healthz") |
| OpenWebUI (3000) | $(http_status "http://localhost:3000") |
| StatusAPI (8765) | $(http_status "http://localhost:8765/healthz") |
| TaskAPI (8766) | $(http_status "http://localhost:8766/status/routes") |

## Failing Command
${FAILING_CMD}

## Exit Code
${EXIT_CODE}

## Recent Log Errors
$(log_errors_report)

## Suggested Issue Title
${SUGGESTED_TITLE}

## Component
${COMPONENT}
REPORT
)"

# Redact entire report before writing
REDACTED_REPORT="$(echo "$REPORT" | redact_string)"

# Write to logs/
mkdir -p "${STACK_DIR}/logs"
OUTFILE="${STACK_DIR}/logs/merlin-bug-report-${TIMESTAMP//:/}.md"
echo "$REDACTED_REPORT" > "$OUTFILE"

# GitHub issue creation (explicit flag only)
if [[ "$CREATE_ISSUE" == "true" ]]; then
  if command -v gh >/dev/null 2>&1; then
    gh issue create \
      --title "$SUGGESTED_TITLE" \
      --body-file "$OUTFILE" \
      --label "auto-report,installer-failure,needs-triage"
  else
    echo "  gh CLI not installed. Install: https://cli.github.com"
    echo "  Then run: gh issue create --title '${SUGGESTED_TITLE}' --body-file '${OUTFILE}'"
  fi
fi

GREEN='\033[0;32m'
NC='\033[0m'
printf "%b  ✓ %s%b\n" "$GREEN" "$(echo "$OUTFILE" | redact_string)" "$NC"
