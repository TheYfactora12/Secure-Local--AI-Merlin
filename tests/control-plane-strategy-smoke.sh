#!/usr/bin/env bash
# Static smoke test for the Merlin AI control-plane strategy.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md"
CANONICAL="${ROOT_DIR}/docs/CANONICAL_PROJECT_STATE.md"
ROADMAP="${ROOT_DIR}/docs/MERLIN_IMPLEMENTATION_ROADMAP.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing control-plane strategy doc"

for required in \
  "What Exists Today" \
  "Current Merlin does not yet provide" \
  "Current-State Architecture" \
  "Future-State Control Plane" \
  "Milestone Ladder" \
  "v3.1" \
  "v3.2" \
  "v3.3" \
  "v3.4" \
  "v3.5" \
  "v3.6" \
  "v3.7" \
  "v4.x" \
  "Do Not Build Yet" \
  "Release Claims Rule"; do
  grep -q "$required" "$DOC" || fail "strategy doc missing: $required"
done

grep -q "not yet be described as a completed AI firewall, IDS, IPS, DLP" "$DOC" \
  || fail "strategy doc must prevent current-state security overclaiming"
grep -q "cloud providers" "$DOC" \
  || fail "strategy doc must cover cloud providers as optional future/connector scope"
grep -q "Telemetry by default" "$DOC" \
  || fail "strategy doc must explicitly forbid telemetry by default"
grep -q "Automatic model downloads after install" "$DOC" \
  || fail "strategy doc must forbid automatic model downloads after install"

grep -q "MERLIN_CONTROL_PLANE_STRATEGY.md" "$CANONICAL" \
  || fail "canonical state must link the control-plane strategy"
grep -q "#101" "$CANONICAL" \
  || fail "canonical queue must include Wizard HQ product shell issue"
grep -q "#113" "$CANONICAL" \
  || fail "canonical queue must include native Merlin Chat follow-up"
grep -q "#114" "$CANONICAL" \
  || fail "canonical queue must include policy-gated Settings follow-up"
grep -q "Developer ID signing/notarization remains tracked by #64" "$CANONICAL" \
  || fail "canonical state must document #64 deferred status"

grep -q "Commercial Control Plane Roadmap" "$ROADMAP" \
  || fail "roadmap must include commercial control-plane roadmap"
grep -q "not yet a completed DLP, IDS, IPS" "$ROADMAP" \
  || fail "roadmap must prevent current-state security overclaiming"

echo "PASS: Merlin control-plane strategy is current/future scoped"
