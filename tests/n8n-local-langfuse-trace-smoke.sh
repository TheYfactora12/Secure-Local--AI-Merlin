#!/usr/bin/env bash
# Static smoke test for optional n8n -> local Langfuse trace emission.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ROOT_DIR}/n8n-workflows/07-local-langfuse-trace-emitter.json"
GUIDE="${ROOT_DIR}/docs/observability-guide.md"
RUNTIME_DOC="${ROOT_DIR}/docs/architecture/AUTOMATION_RUNTIME_STRATEGY.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$WORKFLOW" ]] || fail "local Langfuse trace emitter workflow missing"
[[ -f "$GUIDE" ]] || fail "observability guide missing"
[[ -f "$RUNTIME_DOC" ]] || fail "automation runtime strategy doc missing"

WORKFLOW="$WORKFLOW" python3 - <<'PY' || fail "workflow validation failed"
import json
import os
from pathlib import Path

path = Path(os.environ["WORKFLOW"])
workflow = json.loads(path.read_text())
body = json.dumps(workflow)

if workflow.get("active") is not False:
    raise SystemExit("workflow must ship inactive by default")

nodes = {node["name"]: node for node in workflow.get("nodes", [])}
required = {
    "Local Trace Webhook",
    "Validate + Redact Trace",
    "Observability Active?",
    "Post to Local Langfuse",
    "Respond: Emitted",
    "Respond: Skipped",
}
missing = required - set(nodes)
if missing:
    raise SystemExit(f"missing nodes: {sorted(missing)}")

webhook_path = nodes["Local Trace Webhook"]["parameters"]["path"]
if webhook_path != "swarm/observability/trace":
    raise SystemExit(f"unexpected webhook path: {webhook_path}")

if "HOME_AI_OBSERVABILITY_PROFILE_ACTIVE" not in body:
    raise SystemExit("workflow must gate emission on observability profile")
if "observability_active" not in body:
    raise SystemExit("workflow must allow explicit per-call opt-in")
if "cloud\\\\.langfuse\\\\.com" not in body or "hostedBlocked" not in body:
    raise SystemExit("workflow must refuse hosted Langfuse")
if "raw_payload_exported" not in body or "external_telemetry" not in body:
    raise SystemExit("workflow must declare safe trace flags")
if "langfuse_public_key" in body or "langfuse_write_key" in body:
    raise SystemExit("Langfuse write keys must come from n8n environment, not webhook body")

post = nodes["Post to Local Langfuse"]
if post.get("continueOnFail") is not True:
    raise SystemExit("local Langfuse post must degrade gracefully")

url = post["parameters"]["url"]
if "langfuse_url" not in url or "api/public/ingestion" not in url:
    raise SystemExit("Langfuse ingestion URL missing")

if "https://cloud.langfuse.com" in body or "https://us.cloud.langfuse.com" in body:
    raise SystemExit("workflow must not configure hosted Langfuse")

serialized = body.casefold()
for forbidden in [
    "raw_prompt",
    "raw_input",
    "raw_output",
    "api_key",
    "authorization\": \"bearer",
    "password\":",
    "secret\":",
    "token\":",
]:
    if forbidden in serialized:
        raise SystemExit(f"workflow contains forbidden raw field: {forbidden}")

tags = {tag["name"] for tag in workflow.get("tags", [])}
for tag in {"observability", "langfuse", "local-only", "issue-87"}:
    if tag not in tags:
        raise SystemExit(f"missing tag: {tag}")
PY

grep -q '07-local-langfuse-trace-emitter.json' "$GUIDE" \
  || fail "observability guide missing n8n trace emitter section"
grep -q 'swarm/observability/trace' "$GUIDE" \
  || fail "observability guide missing webhook path"
grep -q 'observability profile is active' "$GUIDE" \
  || fail "guide must state trace emission is profile-gated"
grep -q 'Build Our Own Automation Runtime' "$RUNTIME_DOC" \
  || fail "automation runtime strategy missing commercial replacement section"
grep -q 'Last-mile milestone' "$RUNTIME_DOC" \
  || fail "automation runtime strategy must keep replacement as later milestone"

echo "PASS: n8n local Langfuse trace emission is optional, local-only, and redacted"
