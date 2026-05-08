#!/usr/bin/env bash
# Plan-only Magic Mode step runner.
#
# This script creates a deterministic, auditable plan from the existing Merlin
# dry-run route decision. It does not execute steps, start services, call models,
# write memory, download models, use API keys, access external network, or run
# tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLAN_LOG="${MERLIN_MAGIC_PLAN_LOG:-${STACK_DIR}/logs/merlin-magic-plans.jsonl}"
TRACE_LOG="${MERLIN_TRACE_LOG:-${STACK_DIR}/logs/merlin-route-decisions.jsonl}"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-magic-plan.sh "user goal"
  scripts/merlin-magic-plan.sh --task-type code "debug the installer"

Options:
  --task-type <type>       Force task type: general, search, code, automation, memory
  --write-plan             Append a redacted Magic Mode plan JSONL record
  --plan-log <path>        Override Magic Mode plan log path
  --trace-log <path>       Override route trace log path passed to dry-run
  --approval-log <path>    Override approval log path passed to dry-run

Plan mode does not execute actions. It creates visible steps, risk, approval
requirements, and stop/pause guidance. With --write-plan it writes hashed goal
metadata and plan structure only; it never writes the raw user goal.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

TASK_TYPE=""
WRITE_PLAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-type)
      TASK_TYPE="${2:-}"
      [[ -n "$TASK_TYPE" ]] || fail "--task-type requires a value"
      shift 2
      ;;
    --write-plan)
      WRITE_PLAN=true
      shift
      ;;
    --plan-log)
      PLAN_LOG="${2:-}"
      [[ -n "$PLAN_LOG" ]] || fail "--plan-log requires a path"
      shift 2
      ;;
    --trace-log)
      TRACE_LOG="${2:-}"
      [[ -n "$TRACE_LOG" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
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

DRY_RUN_ARGS=(
  "${STACK_DIR}/scripts/merlin-dry-run.sh"
  --trace-log "$TRACE_LOG"
  --approval-log "$APPROVAL_LOG"
)

if [[ -n "$TASK_TYPE" ]]; then
  DRY_RUN_ARGS+=(--task-type "$TASK_TYPE")
fi

if [[ "$WRITE_PLAN" == true ]]; then
  DRY_RUN_ARGS+=(--write-trace)
fi

DRY_RUN_OUTPUT="$(bash "${DRY_RUN_ARGS[@]}" "$GOAL")"

value_for() {
  local key="$1"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' <<< "$DRY_RUN_OUTPUT"
}

PLAN_ID="magic_$(date -u +%Y%m%d_%H%M%S)_$$"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRACE_ID="$(value_for trace_id)"
USER_GOAL_HASH="$(value_for user_goal_hash)"
ROUTE_ID="$(value_for route_id)"
DETECTED_TASK_TYPE="$(value_for task_type)"
AGENT="$(value_for selected_agent)"
REQUIRED_PROFILE="$(value_for required_profile)"
ACTIVE_PROFILE="$(value_for active_profile)"
HARDWARE_TIER="$(value_for hardware_tier)"
PRIVACY_MODE="$(value_for privacy_mode)"
ONLINE_MODE="$(value_for online_mode)"
CLOUD_ALLOWED="$(value_for cloud_allowed)"
MODEL_ALIAS="$(value_for selected_model_alias)"
APPROVAL_REQUIRED="$(value_for approval_required)"
APPROVAL_REQUEST_ID="$(value_for approval_request_id)"
APPROVAL_GATES="$(value_for approval_gates)"
POLICY_DECISION="$(value_for policy_decision)"
RISK="$(value_for risk)"
DECISION_REASON="$(value_for decision_reason)"

[[ -n "$ROUTE_ID" ]] || fail "dry-run did not return a route id"

case "$ROUTE_ID" in
  general)
    TOOLS_REQUIRED="local_llm"
    ;;
  search)
    TOOLS_REQUIRED="search_profile,network"
    ;;
  code)
    TOOLS_REQUIRED="repo_read,file_write,shell,git,openhands_optional"
    ;;
  automation)
    TOOLS_REQUIRED="n8n,webhook,external_api_optional"
    ;;
  memory)
    TOOLS_REQUIRED="memory_review,qdrant_write_optional"
    ;;
  *)
    TOOLS_REQUIRED="manual_review"
    ;;
esac

case "$ROUTE_ID" in
  general)
    STEP_1="Clarify the goal and constraints"
    STEP_2="Use local model route '${MODEL_ALIAS}' for reasoning"
    STEP_3="Summarize answer and cite local limitations"
    STEP_4="Offer next safe action"
    ;;
  search)
    STEP_1="Confirm online/search permission"
    STEP_2="Start or verify search profile only after approval"
    STEP_3="Collect local search results through approved tools"
    STEP_4="Summarize findings with source notes"
    ;;
  code)
    STEP_1="Read repo context only inside approved scope"
    STEP_2="Draft change plan and tests"
    STEP_3="Request approval before file, shell, git, or OpenHands action"
    STEP_4="After approval, run scoped adapter in a later milestone"
    ;;
  automation)
    STEP_1="Inspect workflow goal and required integrations"
    STEP_2="Request approval before n8n/API/network use"
    STEP_3="Draft workflow plan without enabling triggers"
    STEP_4="Wait for explicit user approval before any activation"
    ;;
  memory)
    STEP_1="Classify memory type and sensitivity"
    STEP_2="Show proposed memory text for user review"
    STEP_3="Request approval before any persistent write/delete"
    STEP_4="Write or delete memory only through future scoped adapter"
    ;;
  *)
    STEP_1="Clarify task"
    STEP_2="Evaluate policy"
    STEP_3="Request approvals if needed"
    STEP_4="Stop before execution"
    ;;
esac

if [[ "$APPROVAL_REQUIRED" == "true" ]]; then
  PLAN_STATUS="blocked_pending_approval"
  NEXT_ALLOWED_ACTION="review_approval"
else
  PLAN_STATUS="ready_plan_only"
  NEXT_ALLOWED_ACTION="manual_user_decision"
fi

write_plan_record() {
  mkdir -p "$(dirname "$PLAN_LOG")"
  PLAN_ID="$PLAN_ID" TIMESTAMP="$TIMESTAMP" TRACE_ID="$TRACE_ID" USER_GOAL_HASH="$USER_GOAL_HASH" \
    ROUTE_ID="$ROUTE_ID" TASK_TYPE="$DETECTED_TASK_TYPE" AGENT="$AGENT" REQUIRED_PROFILE="$REQUIRED_PROFILE" \
    ACTIVE_PROFILE="$ACTIVE_PROFILE" HARDWARE_TIER="$HARDWARE_TIER" PRIVACY_MODE="$PRIVACY_MODE" \
    ONLINE_MODE="$ONLINE_MODE" CLOUD_ALLOWED="$CLOUD_ALLOWED" MODEL_ALIAS="$MODEL_ALIAS" \
    APPROVAL_REQUIRED="$APPROVAL_REQUIRED" APPROVAL_REQUEST_ID="$APPROVAL_REQUEST_ID" \
    APPROVAL_GATES="$APPROVAL_GATES" POLICY_DECISION="$POLICY_DECISION" RISK="$RISK" \
    PLAN_STATUS="$PLAN_STATUS" NEXT_ALLOWED_ACTION="$NEXT_ALLOWED_ACTION" DECISION_REASON="$DECISION_REASON" \
    TOOLS_REQUIRED="$TOOLS_REQUIRED" \
    STEP_1="$STEP_1" STEP_2="$STEP_2" STEP_3="$STEP_3" STEP_4="$STEP_4" PLAN_LOG="$PLAN_LOG" python3 - <<'PY'
import json
import os
from pathlib import Path

def as_bool(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}

gates = [] if os.environ["APPROVAL_GATES"] in {"", "none"} else os.environ["APPROVAL_GATES"].split(",")
record = {
    "plan_id": os.environ["PLAN_ID"],
    "timestamp": os.environ["TIMESTAMP"],
    "trace_id": os.environ["TRACE_ID"],
    "user_goal_hash": os.environ["USER_GOAL_HASH"],
    "route_id": os.environ["ROUTE_ID"],
    "task_type": os.environ["TASK_TYPE"],
    "selected_agent": os.environ["AGENT"],
    "required_profile": os.environ["REQUIRED_PROFILE"],
    "active_profile": os.environ["ACTIVE_PROFILE"],
    "hardware_tier": os.environ["HARDWARE_TIER"],
    "privacy_mode": os.environ["PRIVACY_MODE"],
    "online_mode": as_bool(os.environ["ONLINE_MODE"]),
    "cloud_allowed": as_bool(os.environ["CLOUD_ALLOWED"]),
    "selected_model_alias": os.environ["MODEL_ALIAS"],
    "approval_required": as_bool(os.environ["APPROVAL_REQUIRED"]),
    "approval_request_id": os.environ["APPROVAL_REQUEST_ID"],
    "approval_gates": gates,
    "policy_decision": os.environ["POLICY_DECISION"],
    "risk": os.environ["RISK"],
    "plan_status": os.environ["PLAN_STATUS"],
    "next_allowed_action": os.environ["NEXT_ALLOWED_ACTION"],
    "mode": "plan_only",
    "pause_supported": True,
    "stop_supported": True,
    "tools_required": [item for item in os.environ["TOOLS_REQUIRED"].split(",") if item],
    "steps": [
        {"id": "step_1", "title": os.environ["STEP_1"], "status": "planned", "execution_allowed": False, "approval_gates": gates, "tools_required": [item for item in os.environ["TOOLS_REQUIRED"].split(",") if item]},
        {"id": "step_2", "title": os.environ["STEP_2"], "status": "planned", "execution_allowed": False, "approval_gates": gates, "tools_required": [item for item in os.environ["TOOLS_REQUIRED"].split(",") if item]},
        {"id": "step_3", "title": os.environ["STEP_3"], "status": "planned", "execution_allowed": False, "approval_gates": gates, "tools_required": [item for item in os.environ["TOOLS_REQUIRED"].split(",") if item]},
        {"id": "step_4", "title": os.environ["STEP_4"], "status": "planned", "execution_allowed": False, "approval_gates": gates, "tools_required": [item for item in os.environ["TOOLS_REQUIRED"].split(",") if item]},
    ],
    "decision_reason": os.environ["DECISION_REASON"],
    "redaction_applied": True,
    "raw_goal_logged": False,
    "side_effects": "audit_log_only",
    "model_calls": "none",
    "memory_writes": "none",
    "service_starts": "none",
    "tool_execution": "none",
    "cloud_calls": "none",
    "external_network": "none",
    "execution_allowed": False,
}

with Path(os.environ["PLAN_LOG"]).open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, separators=(",", ":")) + "\n")
PY
}

if [[ "$WRITE_PLAN" == true ]]; then
  write_plan_record
fi

cat <<EOF
Merlin Magic Mode plan
mode: plan_only
boundary: planning_only_no_execution
plan_id: ${PLAN_ID}
timestamp: ${TIMESTAMP}
trace_id: ${TRACE_ID}
user_goal_hash: ${USER_GOAL_HASH}
route_id: ${ROUTE_ID}
task_type: ${DETECTED_TASK_TYPE}
selected_agent: ${AGENT}
required_profile: ${REQUIRED_PROFILE}
active_profile: ${ACTIVE_PROFILE}
hardware_tier: ${HARDWARE_TIER}
privacy_mode: ${PRIVACY_MODE}
online_mode: ${ONLINE_MODE}
cloud_allowed: ${CLOUD_ALLOWED}
selected_model_alias: ${MODEL_ALIAS}
approval_required: ${APPROVAL_REQUIRED}
approval_request_id: ${APPROVAL_REQUEST_ID}
approval_gates: ${APPROVAL_GATES}
tools_required: ${TOOLS_REQUIRED}
policy_decision: ${POLICY_DECISION}
risk: ${RISK}
plan_status: ${PLAN_STATUS}
next_allowed_action: ${NEXT_ALLOWED_ACTION}
pause_supported: true
stop_supported: true
pause_guidance: Pause means review this plan; no action is running.
stop_guidance: Stop means discard the plan; there is no background execution to stop.
execution_allowed: false
side_effects: $([[ "$WRITE_PLAN" == true ]] && echo "audit_log_only" || echo "none")
model_calls: none
memory_writes: none
service_starts: none
tool_execution: none
cloud_calls: none
external_network: none
plan_written: ${WRITE_PLAN}
plan_log: ${PLAN_LOG}
trace_log: ${TRACE_LOG}
approval_log: ${APPROVAL_LOG}
decision_reason: ${DECISION_REASON}

steps:
  - id: step_1
    title: ${STEP_1}
    status: planned
    execution_allowed: false
    approval_gates: ${APPROVAL_GATES:-none}
    tools_required: ${TOOLS_REQUIRED}
  - id: step_2
    title: ${STEP_2}
    status: planned
    execution_allowed: false
    approval_gates: ${APPROVAL_GATES:-none}
    tools_required: ${TOOLS_REQUIRED}
  - id: step_3
    title: ${STEP_3}
    status: planned
    execution_allowed: false
    approval_gates: ${APPROVAL_GATES:-none}
    tools_required: ${TOOLS_REQUIRED}
  - id: step_4
    title: ${STEP_4}
    status: planned
    execution_allowed: false
    approval_gates: ${APPROVAL_GATES:-none}
    tools_required: ${TOOLS_REQUIRED}
EOF
