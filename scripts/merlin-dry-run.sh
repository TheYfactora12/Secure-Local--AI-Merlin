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
  scripts/merlin-dry-run.sh --write-trace "plan a local install"

Options:
  --task-type <type>  Force task type: general, search, code, automation, memory
  --write-trace       Append a redacted JSONL route trace
  --trace-log <path>  Override trace log path for --write-trace
  --approval-log <path>
                       Override pending approval JSONL path for --write-trace

By default this command is read-only. It does not call models, start services,
write memory, download models, use API keys, or execute tools. With
--write-trace it appends redacted route metadata and pending approval metadata
to local JSONL logs. It still does not approve or execute anything.
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
WRITE_TRACE=false
TRACE_LOG_OVERRIDE=""
APPROVAL_LOG_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-type)
      TASK_TYPE="${2:-}"
      [[ -n "$TASK_TYPE" ]] || fail "--task-type requires a value"
      shift 2
      ;;
    --write-trace)
      WRITE_TRACE=true
      shift
      ;;
    --trace-log)
      TRACE_LOG_OVERRIDE="${2:-}"
      [[ -n "$TRACE_LOG_OVERRIDE" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG_OVERRIDE="${2:-}"
      [[ -n "$APPROVAL_LOG_OVERRIDE" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      fail "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

GOAL="${*:-}"
[[ -n "$GOAL" ]] || { usage; exit 1; }

classify_task_type() {
  local goal_lc
  goal_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  if [[ "$goal_lc" =~ remember|memory|recall|document|forget ]]; then
    echo "memory"
  elif [[ "$goal_lc" =~ automation|workflow|webhook|schedule|n8n ]]; then
    echo "automation"
  elif [[ "$goal_lc" =~ search|research|latest|current|citation|cite|web ]]; then
    echo "search"
  elif [[ "$goal_lc" =~ code|debug|refactor|test|repo|script|github|git ]]; then
    echo "code"
  else
    echo "general"
  fi
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

default_trace_log_path() {
  local configured
  configured="$(awk -F': ' '/^[[:space:]]+local_file:/ { print $2; exit }' "$TRACE_FILE")"
  configured="${configured:-logs/merlin-route-decisions.jsonl}"
  if [[ "$configured" = /* ]]; then
    echo "$configured"
  else
    echo "${STACK_DIR}/${configured}"
  fi
}

default_approval_log_path() {
  echo "${STACK_DIR}/logs/merlin-approvals.jsonl"
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

json_array_from_csv() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    printf '[]'
    return
  fi
  CSV_VALUE="$csv" python3 -c '
import json
import os
print(json.dumps([item for item in os.environ["CSV_VALUE"].split(",") if item]))
'
}

json_bool() {
  case "$1" in
    true|TRUE|True|1|yes|YES|Yes) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

write_trace_record() {
  local trace_log="$1"
  local timestamp="$2"
  local approval_gates_json
  local approval_request_id_json
  local approval_required_json
  local decision_reason_json
  local user_goal_hash_json
  local online_mode_json
  local cloud_allowed_json

  approval_gates_json="$(json_array_from_csv "$APPROVAL_GATES")"
  approval_request_id_json="$(printf '%s' "$APPROVAL_REQUEST_ID" | json_escape)"
  approval_required_json="$(json_bool "$APPROVAL_REQUIRED")"
  decision_reason_json="$(printf '%s' "$DECISION_REASON" | json_escape)"
  user_goal_hash_json="$(printf '%s' "$USER_GOAL_HASH" | json_escape)"
  online_mode_json="$(json_bool "$ONLINE_MODE")"
  cloud_allowed_json="$(json_bool "$CLOUD_ALLOWED")"

  mkdir -p "$(dirname "$trace_log")"
  printf '{"trace_id":%s,"timestamp":%s,"user_goal_hash":%s,"route_id":%s,"task_type":%s,"selected_agent":%s,"required_profile":%s,"active_profile":%s,"hardware_tier":%s,"privacy_mode":%s,"online_mode":%s,"cloud_allowed":%s,"selected_model_alias":%s,"provider":%s,"approval_required":%s,"approval_request_id":%s,"approval_gates":%s,"approval_status":%s,"policy_decision":%s,"decision_reason":%s,"redaction_applied":true,"side_effects":"none","model_calls":"none","memory_writes":"none","service_starts":"none","tool_execution":"none"}\n' \
    "$(printf '%s' "$TRACE_ID" | json_escape)" \
    "$(printf '%s' "$timestamp" | json_escape)" \
    "$user_goal_hash_json" \
    "$(printf '%s' "$ROUTE_ID" | json_escape)" \
    "$(printf '%s' "$TASK_TYPE" | json_escape)" \
    "$(printf '%s' "$AGENT" | json_escape)" \
    "$(printf '%s' "$REQUIRED_PROFILE" | json_escape)" \
    "$(printf '%s' "$ACTIVE_PROFILE" | json_escape)" \
    "$(printf '%s' "$HARDWARE_TIER" | json_escape)" \
    "$(printf '%s' "$PRIVACY_MODE" | json_escape)" \
    "$online_mode_json" \
    "$cloud_allowed_json" \
    "$(printf '%s' "$MODEL_ALIAS" | json_escape)" \
    "$(printf '%s' "ollama" | json_escape)" \
    "$approval_required_json" \
    "$approval_request_id_json" \
    "$approval_gates_json" \
    "$(printf '%s' "$APPROVAL_STATUS" | json_escape)" \
    "$(printf '%s' "$POLICY_DECISION" | json_escape)" \
    "$decision_reason_json" >> "$trace_log"
}

write_approval_record() {
  local approval_log="$1"
  local timestamp="$2"
  local approval_gates_json
  local decision_reason_json
  local user_goal_hash_json

  [[ "$APPROVAL_REQUIRED" == true ]] || return 0

  approval_gates_json="$(json_array_from_csv "$APPROVAL_GATES")"
  decision_reason_json="$(printf '%s' "$DECISION_REASON" | json_escape)"
  user_goal_hash_json="$(printf '%s' "$USER_GOAL_HASH" | json_escape)"

  mkdir -p "$(dirname "$approval_log")"
  printf '{"approval_request_id":%s,"timestamp":%s,"status":"required_pending","execution_allowed":false,"user_goal_hash":%s,"route_id":%s,"task_type":%s,"selected_agent":%s,"required_profile":%s,"active_profile":%s,"hardware_tier":%s,"privacy_mode":%s,"online_mode":%s,"cloud_allowed":%s,"selected_model_alias":%s,"provider":%s,"approval_gates":%s,"policy_decision":%s,"decision_reason":%s,"redaction_applied":true,"side_effects":"none","model_calls":"none","memory_writes":"none","service_starts":"none","tool_execution":"none"}\n' \
    "$(printf '%s' "$APPROVAL_REQUEST_ID" | json_escape)" \
    "$(printf '%s' "$timestamp" | json_escape)" \
    "$user_goal_hash_json" \
    "$(printf '%s' "$ROUTE_ID" | json_escape)" \
    "$(printf '%s' "$TASK_TYPE" | json_escape)" \
    "$(printf '%s' "$AGENT" | json_escape)" \
    "$(printf '%s' "$REQUIRED_PROFILE" | json_escape)" \
    "$(printf '%s' "$ACTIVE_PROFILE" | json_escape)" \
    "$(printf '%s' "$HARDWARE_TIER" | json_escape)" \
    "$(printf '%s' "$PRIVACY_MODE" | json_escape)" \
    "$(json_bool "$ONLINE_MODE")" \
    "$(json_bool "$CLOUD_ALLOWED")" \
    "$(printf '%s' "$MODEL_ALIAS" | json_escape)" \
    "$(printf '%s' "ollama" | json_escape)" \
    "$approval_gates_json" \
    "$(printf '%s' "$POLICY_DECISION" | json_escape)" \
    "$decision_reason_json" >> "$approval_log"
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
TRACE_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
USER_GOAL_HASH="$(goal_hash "$GOAL")"
APPROVAL_REQUEST_ID="none"
APPROVAL_REQUIRED=false

POLICY_DECISION="allow"
APPROVAL_STATUS="not_required"
DECISION_REASON="Core local route can proceed after runtime implementation."

if [[ -n "$APPROVAL_GATES" ]]; then
  APPROVAL_REQUIRED=true
  POLICY_DECISION="require_approval"
  APPROVAL_STATUS="required_pending"
  DECISION_REASON="Route includes approval gates: ${APPROVAL_GATES}."
fi

if ! profile_has_capability "$ACTIVE_PROFILE" "$REQUIRED_PROFILE" "$CUSTOM_PROFILES"; then
  APPROVAL_REQUIRED=true
  POLICY_DECISION="ask_to_start_profile"
  APPROVAL_STATUS="required_pending"
  DECISION_REASON="Route requires optional profile '${REQUIRED_PROFILE}', but active profile is '${ACTIVE_PROFILE}'."
fi

if [[ "$HARDWARE_TIER" == "low" && "$REQUIRED_PROFILE" != "core" ]]; then
  DECISION_REASON="${DECISION_REASON} Low-memory tier should avoid heavy optional profiles unless the user explicitly approves."
fi

if [[ "$APPROVAL_REQUIRED" == true ]]; then
  APPROVAL_REQUEST_ID="approval_${TRACE_ID}"
fi

TRACE_LOG_PATH="${TRACE_LOG_OVERRIDE:-$(default_trace_log_path)}"
APPROVAL_LOG_PATH="${APPROVAL_LOG_OVERRIDE:-$(default_approval_log_path)}"
APPROVAL_WRITTEN=false

if [[ "$WRITE_TRACE" == true ]]; then
  write_trace_record "$TRACE_LOG_PATH" "$TRACE_TIMESTAMP"
  if [[ "$APPROVAL_REQUIRED" == true ]]; then
    write_approval_record "$APPROVAL_LOG_PATH" "$TRACE_TIMESTAMP"
    APPROVAL_WRITTEN=true
  fi
fi

cat <<EOF
Merlin dry-run route decision
trace_id: ${TRACE_ID}
timestamp: ${TRACE_TIMESTAMP}
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
approval_required: ${APPROVAL_REQUIRED}
approval_request_id: ${APPROVAL_REQUEST_ID}
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
trace_written: ${WRITE_TRACE}
trace_log: ${TRACE_LOG_PATH}
approval_written: ${APPROVAL_WRITTEN}
approval_log: ${APPROVAL_LOG_PATH}

approval_request:
  id: ${APPROVAL_REQUEST_ID}
  required: ${APPROVAL_REQUIRED}
  status: ${APPROVAL_STATUS}
  route_id: ${ROUTE_ID}
  gates: ${APPROVAL_GATES:-none}
  proposed_action: evaluate route only; no execution requested
  execution_allowed: false
EOF
