#!/usr/bin/env bash
# Static smoke test for the v3.0 trusted local beta evidence pack.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md"
FAILURE_DOC="${ROOT_DIR}/docs/operations/FAILURE_LEARNING_LOOP.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing trusted local beta evidence document"
[[ -f "$FAILURE_DOC" ]] || fail "missing failure learning loop document"

for section in \
  "Release Candidate Metadata" \
  "Release Stage Gates" \
  "Full Installer Retest Trigger" \
  "CI Baseline" \
  "8GB Low/Core Clean Install" \
  "16GB+ Matrix Placeholder" \
  "Uninstall, Reinstall, And Upgrade" \
  "Service Health Validation" \
  "Dashboard Readiness Validation" \
  "Offline Launch Validation" \
  "No Cloud Calls And No Surprise Model Downloads" \
  "Magic Mode And Audit Validation" \
  "Startup Logs Review" \
  "startup_timing" \
  "docs/release/evidence/assets" \
  "Evidence Table" \
  "Blocker Rule"; do
  grep -q "$section" "$DOC" || fail "missing evidence section: $section"
done

grep -q "HOME_AI_SKIP_MODEL_PULLS=true" "$DOC" \
  || fail "evidence pack must preserve no-surprise-model-pulls validation"
grep -q "bash install.sh --profile core --skip-model-pulls --non-interactive" "$DOC" \
  || fail "evidence pack missing protected core install command"
grep -q "bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data" "$DOC" \
  || fail "evidence pack missing fresh-data uninstall command"
grep -q "bash scripts/upgrade.sh --profile core" "$DOC" \
  || fail "evidence pack missing upgrade command"
grep -q "bash tests/dashboard-readiness-smoke.sh" "$DOC" \
  || fail "evidence pack missing dashboard readiness smoke"
grep -q "bash tests/installer-model-pull-policy-smoke.sh" "$DOC" \
  || fail "evidence pack missing model-pull policy smoke"
grep -q "bash tests/openwebui-local-first-smoke.sh" "$DOC" \
  || fail "evidence pack missing local-first smoke"
grep -q "bash tests/merlin-magic-plan-smoke.sh" "$DOC" \
  || fail "evidence pack missing Magic Mode plan-only smoke"
grep -q "api.openai.com" "$DOC" \
  || fail "evidence pack missing OpenAI cloud-call log review marker"
grep -q "api.anthropic.com" "$DOC" \
  || fail "evidence pack missing Anthropic cloud-call log review marker"
grep -q "Do not close #95" "$DOC" \
  || fail "evidence pack missing beta blocker rule"
grep -q "FAILURE_LEARNING_LOOP.md" "$DOC" \
  || fail "evidence pack must link failure learning loop"
grep -q "Failure Learning Appendix" "$DOC" \
  || fail "evidence pack missing failure learning appendix"

for required in \
  "Continuous Failure Learning Loop" \
  "Failure Response Rule" \
  "Installer Failure Learning Rule" \
  "Evidence Log Requirement" \
  "Smarter After Every Failure Rule" \
  "Known Failure Pattern Format" \
  "Failure-To-Issue Rule" \
  "Release Readiness Impact Rule" \
  "Junior Engineer Safety Rule" \
  "Local Trusted Beta blocker" \
  "HOME_AI_SKIP_MODEL_PULLS=true" \
  "Regression test added or reason not added" \
  "What not to repeat next time"; do
  grep -q "$required" "$FAILURE_DOC" || fail "failure learning doc missing: $required"
done

echo "PASS: trusted local beta evidence pack is complete"
