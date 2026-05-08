#!/usr/bin/env bash
# Static smoke test for the v3.0 trusted local beta evidence pack.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing trusted local beta evidence document"

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

echo "PASS: trusted local beta evidence pack is complete"
