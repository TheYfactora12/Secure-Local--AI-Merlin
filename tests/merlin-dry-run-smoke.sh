#!/usr/bin/env bash
# Smoke-test Merlin read-only dry-run route decisions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_output() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  echo "$output" | grep -Eq -- "$pattern" || fail "$label"
}

GENERAL_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "plan a local install")"
require_output "$GENERAL_OUTPUT" '^route_id: general$' "general task should route to general"
require_output "$GENERAL_OUTPUT" '^required_profile: core$' "general task should require core"
require_output "$GENERAL_OUTPUT" '^policy_decision: allow$' "general route should be allowed in dry-run"
require_output "$GENERAL_OUTPUT" '^approval_required: false$' "general route should not require approval"
require_output "$GENERAL_OUTPUT" '^approval_request_id: none$' "general route should not allocate approval id"
require_output "$GENERAL_OUTPUT" '^staff_mode: operator$' "general route should report staff mode"
require_output "$GENERAL_OUTPUT" '^preferred_model_alias: mistral$' "general route should report preferred staff model"
require_output "$GENERAL_OUTPUT" '^selected_model_alias: mistral$' "general route should report selected staff model"
require_output "$GENERAL_OUTPUT" '^model_fallback_applied: false$' "general route should report fallback status"
require_output "$GENERAL_OUTPUT" '^audit_written: false$' "dry-run should not write audit"
require_output "$GENERAL_OUTPUT" '^side_effects: none$' "dry-run should have no side effects"
require_output "$GENERAL_OUTPUT" '^model_calls: none$' "dry-run should not call models"
require_output "$GENERAL_OUTPUT" '^memory_writes: none$' "dry-run should not write memory"
require_output "$GENERAL_OUTPUT" '^service_starts: none$' "dry-run should not start services"
require_output "$GENERAL_OUTPUT" '^tool_execution: none$' "dry-run should not execute tools"
require_output "$GENERAL_OUTPUT" '^cloud_allowed: false$' "dry-run should keep cloud disabled"

CODE_OUTPUT="$(MERLIN_HARDWARE_TIER=low HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "debug the installer code")"
require_output "$CODE_OUTPUT" '^route_id: code$' "code task should route to code"
require_output "$CODE_OUTPUT" '^selected_agent: coding$' "code task should select coding agent"
require_output "$CODE_OUTPUT" '^required_profile: coding$' "code task should require coding profile"
require_output "$CODE_OUTPUT" '^approval_required: true$' "code task should require approval"
require_output "$CODE_OUTPUT" '^approval_request_id: approval_dryrun_' "code task should allocate approval id"
require_output "$CODE_OUTPUT" '^staff_mode: software_engineer$' "code route should report software engineer mode"
require_output "$CODE_OUTPUT" '^preferred_model_alias: qwen-coder$' "code route should prefer qwen-coder"
require_output "$CODE_OUTPUT" '^selected_model_alias: mistral$' "low-memory code route should select fallback model"
require_output "$CODE_OUTPUT" '^model_fallback_applied: true$' "low-memory code route should report fallback"
require_output "$CODE_OUTPUT" '^approval_status: required_pending$' "code task should require pending approval"
require_output "$CODE_OUTPUT" '^policy_decision: ask_to_start_profile$' "code route should not auto-start optional profile"
require_output "$CODE_OUTPUT" 'shell_command' "code route should include shell approval gate"
require_output "$CODE_OUTPUT" 'openhands_task' "code route should include OpenHands approval gate"
require_output "$CODE_OUTPUT" '^approval_request:$' "code route should include approval request block"
require_output "$CODE_OUTPUT" 'execution_allowed: false' "approval request should not allow execution"

FULL_CODE_OUTPUT="$(HOME_AI_PROFILE=full bash "${STACK_DIR}/scripts/merlin-dry-run.sh" --task-type code "review repo")"
require_output "$FULL_CODE_OUTPUT" '^route_id: code$' "forced code task should route to code"
require_output "$FULL_CODE_OUTPUT" '^active_profile: full$' "forced code route should report active profile"
require_output "$FULL_CODE_OUTPUT" '^policy_decision: require_approval$' "coding route in full profile still needs approval"
require_output "$FULL_CODE_OUTPUT" '^approval_status: required_pending$' "coding route should remain approval-gated"

SEARCH_OUTPUT="$(HOME_AI_PROFILE=developer bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "research current local AI tools")"
require_output "$SEARCH_OUTPUT" '^route_id: search$' "search task should route to search"
require_output "$SEARCH_OUTPUT" '^active_profile: developer$' "search route should report developer profile"
require_output "$SEARCH_OUTPUT" '^policy_decision: require_approval$' "search route should require network/service approval"
require_output "$SEARCH_OUTPUT" 'external_network' "search route should include external network approval"

WIZARD_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/cli/wizard" merlin dry-run "remember this approved note")"
require_output "$WIZARD_OUTPUT" '^route_id: memory$' "wizard merlin dry-run should call dry-run script"
require_output "$WIZARD_OUTPUT" '^policy_decision: require_approval$' "memory route should require approval"

TMP="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"
TRACE_OUTPUT="$(MERLIN_HARDWARE_TIER=low HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" --write-trace --trace-log "$TRACE_LOG" --approval-log "$APPROVAL_LOG" "debug token sk-test installer")"
require_output "$TRACE_OUTPUT" '^trace_written: true$' "write-trace should report trace_written"
require_output "$TRACE_OUTPUT" '^approval_required: true$' "write-trace route should require approval"
require_output "$TRACE_OUTPUT" "^trace_log: ${TRACE_LOG}$" "write-trace should report trace path"
require_output "$TRACE_OUTPUT" '^approval_written: true$' "write-trace should report approval_written"
require_output "$TRACE_OUTPUT" "^approval_log: ${APPROVAL_LOG}$" "write-trace should report approval path"
[[ -s "$TRACE_LOG" ]] || fail "write-trace should append JSONL record"
[[ "$(wc -l < "$TRACE_LOG" | tr -d ' ')" == "1" ]] || fail "write-trace should append one line"
[[ -s "$APPROVAL_LOG" ]] || fail "write-trace should append approval JSONL record"
[[ "$(wc -l < "$APPROVAL_LOG" | tr -d ' ')" == "1" ]] || fail "write-trace should append one approval line"

TRACE_LOG="$TRACE_LOG" python3 - <<'PY' || fail "trace JSONL record failed validation"
import json
import os
from pathlib import Path

line = Path(os.environ["TRACE_LOG"]).read_text(encoding="utf-8").strip()
record = json.loads(line)

required = [
    "trace_id",
    "timestamp",
    "user_goal_hash",
    "route_id",
    "task_type",
    "selected_agent",
    "required_profile",
    "active_profile",
    "hardware_tier",
    "privacy_mode",
    "online_mode",
    "cloud_allowed",
    "staff_mode",
    "preferred_model_alias",
    "selected_model_alias",
    "model_fallback_applied",
    "model_fallback_reason",
    "audit_written",
    "provider",
    "approval_required",
    "approval_request_id",
    "approval_gates",
    "approval_status",
    "policy_decision",
    "decision_reason",
    "redaction_applied",
]
missing = [field for field in required if field not in record]
if missing:
    raise SystemExit(f"missing fields: {missing}")
if record["route_id"] != "code":
    raise SystemExit("expected code route")
if record["staff_mode"] != "software_engineer":
    raise SystemExit("expected software engineer staff mode")
if record["preferred_model_alias"] != "qwen-coder":
    raise SystemExit("expected qwen-coder preferred model")
if record["selected_model_alias"] != "mistral":
    raise SystemExit("expected low-memory fallback model")
if record["model_fallback_applied"] is not True:
    raise SystemExit("expected model fallback")
if record["audit_written"] is not False:
    raise SystemExit("dry-run trace must not claim audit was written")
if record["policy_decision"] != "ask_to_start_profile":
    raise SystemExit("expected optional profile approval decision")
if record["online_mode"] is not False or record["cloud_allowed"] is not False:
    raise SystemExit("online/cloud flags must be false booleans")
if record["approval_required"] is not True:
    raise SystemExit("trace should include approval_required true")
if not str(record["approval_request_id"]).startswith("approval_dryrun_"):
    raise SystemExit("trace should include approval request id")
if record["redaction_applied"] is not True:
    raise SystemExit("redaction flag missing")
if "sk-test" in line or "debug token" in line:
    raise SystemExit("trace must not contain raw goal or secret-like prompt text")
if not str(record["user_goal_hash"]).startswith("sha256:"):
    raise SystemExit("trace must contain goal hash")
if "shell_command" not in record["approval_gates"]:
    raise SystemExit("code trace missing shell approval gate")
PY

APPROVAL_LOG="$APPROVAL_LOG" python3 - <<'PY' || fail "approval JSONL record failed validation"
import json
import os
from pathlib import Path

line = Path(os.environ["APPROVAL_LOG"]).read_text(encoding="utf-8").strip()
record = json.loads(line)

required = [
    "approval_request_id",
    "timestamp",
    "status",
    "execution_allowed",
    "user_goal_hash",
    "route_id",
    "task_type",
    "approval_gates",
    "policy_decision",
    "decision_reason",
    "redaction_applied",
]
missing = [field for field in required if field not in record]
if missing:
    raise SystemExit(f"missing approval fields: {missing}")
if not str(record["approval_request_id"]).startswith("approval_dryrun_"):
    raise SystemExit("approval record should contain approval request id")
if record["status"] != "required_pending":
    raise SystemExit("approval record should be pending")
if record["execution_allowed"] is not False:
    raise SystemExit("approval record must not allow execution")
if record["route_id"] != "code":
    raise SystemExit("approval record should match route")
if "shell_command" not in record["approval_gates"]:
    raise SystemExit("approval record missing shell gate")
if "sk-test" in line or "debug token" in line:
    raise SystemExit("approval record must not contain raw goal or secret-like prompt text")
if not str(record["user_goal_hash"]).startswith("sha256:"):
    raise SystemExit("approval record must contain goal hash")
PY

GENERAL_TRACE_LOG="${TMP}/general-route-decisions.jsonl"
GENERAL_APPROVAL_LOG="${TMP}/general-approvals.jsonl"
GENERAL_TRACE_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" --write-trace --trace-log "$GENERAL_TRACE_LOG" --approval-log "$GENERAL_APPROVAL_LOG" "plan a local install")"
require_output "$GENERAL_TRACE_OUTPUT" '^approval_required: false$' "general trace should not require approval"
require_output "$GENERAL_TRACE_OUTPUT" '^approval_written: false$' "general trace should not write approval record"
[[ -s "$GENERAL_TRACE_LOG" ]] || fail "general write-trace should still append route trace"
[[ ! -e "$GENERAL_APPROVAL_LOG" ]] || fail "general write-trace should not create approval log"

echo "PASS: Merlin dry-run control plane is read-only and approval-gated"
