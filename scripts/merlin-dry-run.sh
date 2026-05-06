#!/usr/bin/env bash
# Read-only Merlin route decision dry-run.
#
# This script is the first runtime control-plane slice. It reads the declarative
# Merlin policy/route contracts and prints what Merlin would do without starting
# services, calling models, writing memory, or executing tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTES_FILE="${MERLIN_ROUTES_FILE:-${STACK_DIR}/config/merlin/routes.yaml}"
POLICY_FILE="${MERLIN_POLICY_FILE:-${STACK_DIR}/config/merlin/policy.yaml}"
TRACE_FILE="${MERLIN_TRACE_FILE:-${STACK_DIR}/config/merlin/trace.yaml}"
PROFILE_LIB="${STACK_DIR}/scripts/profile-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-dry-run.sh "user goal"
  scripts/merlin-dry-run.sh --task-type code "debug the installer"

Options:
  --task-type <type>  Force task type: general, search, code, automation, memory

This command is read-only. It does not call models, start services, write memory,
download models, use API keys, or execute tools.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$ROUTES_FILE" ]] || fail "missing routes file: $ROUTES_FILE"
[[ -f "$POLICY_FILE" ]] || fail "missing policy file: $POLICY_FILE"
[[ -f "$TRACE_FILE" ]] || fail "missing trace file: $TRACE_FILE"
[[ -f "$PROFILE_LIB" ]] || fail "missing profile helper: $PROFILE_LIB"

# shellcheck source=scripts/profile-lib.sh
source "$PROFILE_LIB"

TASK_TYPE=""
if [[ "${1:-}" == "--task-type" ]]; then
  TASK_TYPE="${2:-}"
  shift 2 || true
fi

GOAL="${*:-}"
[[ -n "$GOAL" ]] || { usage; exit 1; }

classify_task_type() {
  local goal_lc
  goal_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  case "$goal_lc" in
    *remember*|*memory*|*recall*|*document*|*forget*)
      echo "memory"
      ;;
    *code*|*debug*|*refactor*|*test*|*repo*|*script*|*github*|*git\ *)
      echo "code"
      ;;
    *search*|*research*|*latest*|*current*|*citation*|*cite*|*web*)
      echo "search"
      ;;
    *automation*|*workflow*|*webhook*|*schedule*|*n8n*)
      echo "automation"
      ;;
    *)
      echo "general"
      ;;
  esac
}

route_for_task_type() {
  case "$1" in
    general|summarize|explain|plan) echo "general" ;;
    search|research|current_info|citation) echo "search" ;;
    code|debug|refactor|test) echo "code" ;;
    automation|workflow|webhook|schedule) echo "automation" ;;
    memory|memory_read|memory_write|memory_delete|document_recall) echo "memory" ;;
    *) echo "general" ;;
  esac
}

route_scalar() {
  local route="$1"
  local key="$2"
  awk -v route="$route" -v key="$key" '
    $0 ~ "^  " route ":" { in_route=1; next }
    in_route && /^  [A-Za-z0-9_-]+:/ { exit }
    in_route && $1 == key ":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$ROUTES_FILE"
}

route_list_csv() {
  local route="$1"
  local key="$2"
  awk -v route="$route" -v key="$key" '
    $0 ~ "^  " route ":" { in_route=1; next }
    in_route && /^  [A-Za-z0-9_-]+:/ { exit }
    in_route && $1 == key ":" {
      if ($0 ~ /\[\]/) {
        exit
      }
      in_list=1
      next
    }
    in_route && in_list && /^[[:space:]]+- / {
      sub(/^[[:space:]]+-[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      items = items ? items "," $0 : $0
      next
    }
    in_route && in_list && /^[[:space:]]+[A-Za-z0-9_-]+:/ { exit }
    END { print items }
  ' "$ROUTES_FILE"
}

detect_ram_gb() {
  local bytes
  bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
  if [[ "$bytes" =~ ^[0-9]+$ ]]; then
    awk -v bytes="$bytes" 'BEGIN { printf "%d", (bytes / 1024 / 1024 / 1024) + 0.5 }'
    return
  fi
  if command -v system_profiler >/dev/null 2>&1; then
    local profiler_ram
    profiler_ram="$(system_profiler SPHardwareDataType 2>/dev/null \
      | awk -F': ' '/Memory:/ { gsub(/ GB/, "", $2); print int($2 + 0.5); exit }'
    )"
    if [[ "$profiler_ram" =~ ^[0-9]+$ && "$profiler_ram" -gt 0 ]]; then
      echo "$profiler_ram"
      return
    fi
  fi
  echo "0"
}

hardware_tier_for_ram() {
  local ram_gb="$1"
  if (( ram_gb >= 48 )); then
    echo "high"
  elif (( ram_gb >= 24 )); then
    echo "mid"
  elif (( ram_gb >= 16 )); then
    echo "base"
  elif (( ram_gb > 0 )); then
    echo "low"
  else
    echo "unknown"
  fi
}

goal_hash() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print "sha256:" $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print "sha256:" $1}'
  else
    echo "sha256:unavailable"
  fi
}

profile_has_capability() {
  local active_profile="$1"
  local required_profile="$2"
  local custom_profiles="${3:-}"
  local capabilities

  [[ "$required_profile" == "core" ]] && return 0
  capabilities="$(profile_capabilities_for "$active_profile" "$custom_profiles" 2>/dev/null || true)"
  for capability in $capabilities; do
    [[ "$capability" == "$required_profile" ]] && return 0
  done
  return 1
}

TASK_TYPE="${TASK_TYPE:-$(classify_task_type "$GOAL")}"
ROUTE_ID="$(route_for_task_type "$TASK_TYPE")"

AGENT="$(route_scalar "$ROUTE_ID" "agent")"
REQUIRED_PROFILE="$(route_scalar "$ROUTE_ID" "required_profile")"
MODEL_ALIAS="$(route_scalar "$ROUTE_ID" "preferred_model_alias")"
RISK="$(route_scalar "$ROUTE_ID" "default_risk")"
APPROVAL_GATES="$(route_list_csv "$ROUTE_ID" "approval_gates")"

[[ -n "$AGENT" ]] || fail "unable to read route agent for: $ROUTE_ID"
[[ -n "$REQUIRED_PROFILE" ]] || fail "unable to read required profile for: $ROUTE_ID"
[[ -n "$MODEL_ALIAS" ]] || fail "unable to read model alias for: $ROUTE_ID"

ACTIVE_PROFILE="${HOME_AI_PROFILE:-core}"
CUSTOM_PROFILES="${HOME_AI_CUSTOM_PROFILES:-}"
normalize_profile_name "$ACTIVE_PROFILE" >/dev/null

RAM_GB="$(detect_ram_gb)"
HARDWARE_TIER="${MERLIN_HARDWARE_TIER:-$(hardware_tier_for_ram "$RAM_GB")}"
PRIVACY_MODE="${MERLIN_PRIVACY_MODE:-local_only}"
ONLINE_MODE="${MERLIN_ONLINE_MODE:-false}"
CLOUD_ALLOWED="${MERLIN_CLOUD_ALLOWED:-false}"
TRACE_ID="dryrun_$(date -u +%Y%m%d_%H%M%S)"
USER_GOAL_HASH="$(goal_hash "$GOAL")"

POLICY_DECISION="allow"
APPROVAL_STATUS="not_required"
DECISION_REASON="Core local route can proceed after runtime implementation."

if [[ -n "$APPROVAL_GATES" ]]; then
  POLICY_DECISION="require_approval"
  APPROVAL_STATUS="required_pending"
  DECISION_REASON="Route includes approval gates: ${APPROVAL_GATES}."
fi

if ! profile_has_capability "$ACTIVE_PROFILE" "$REQUIRED_PROFILE" "$CUSTOM_PROFILES"; then
  POLICY_DECISION="ask_to_start_profile"
  APPROVAL_STATUS="required_pending"
  DECISION_REASON="Route requires optional profile '${REQUIRED_PROFILE}', but active profile is '${ACTIVE_PROFILE}'."
fi

if [[ "$HARDWARE_TIER" == "low" && "$REQUIRED_PROFILE" != "core" ]]; then
  DECISION_REASON="${DECISION_REASON} Low-memory tier should avoid heavy optional profiles unless the user explicitly approves."
fi

cat <<EOF
Merlin dry-run route decision
trace_id: ${TRACE_ID}
user_goal_hash: ${USER_GOAL_HASH}
route_id: ${ROUTE_ID}
task_type: ${TASK_TYPE}
selected_agent: ${AGENT}
required_profile: ${REQUIRED_PROFILE}
active_profile: ${ACTIVE_PROFILE}
hardware_tier: ${HARDWARE_TIER}
ram_gb: ${RAM_GB}
privacy_mode: ${PRIVACY_MODE}
online_mode: ${ONLINE_MODE}
cloud_allowed: ${CLOUD_ALLOWED}
selected_model_alias: ${MODEL_ALIAS}
provider: ollama
approval_gates: ${APPROVAL_GATES:-none}
approval_status: ${APPROVAL_STATUS}
policy_decision: ${POLICY_DECISION}
risk: ${RISK}
redaction_applied: true
decision_reason: ${DECISION_REASON}

side_effects: none
model_calls: none
memory_writes: none
service_starts: none
tool_execution: none
EOF
