# Local Trusted Beta Progress Note — 2026-05-08

## Date / Time

2026-05-08, all-night release-readiness push.

## Branch

`main`

## Commit SHA Before Changes

`1b9eb03` — `docs(issue-97): add trusted local beta evidence pack`

## Commit SHA After Changes

`3a9e5ee` — `docs(issue-95): tighten local trusted beta readiness evidence`

## Target Issues

- #94: verified closed; installer/downloader Merlin brand surface remains
  protected.
- #96: verified closed; Wizard HQ startup/readiness surface remains read-only.
- #97: verified closed; trusted local beta evidence pack exists and is
  CI-covered.
- #37: supported with conservative README release-readiness positioning.
- #95: supported with audit-aligned evidence and retest gating.
- #64: remains open for Developer ID signing/notarization.

## Audit Team Gate

| Role | Status | Notes |
|---|---|---|
| Scrum Master / Delivery Lead | PASS | Active target is Local Trusted Beta readiness; #92 and #81-#84 remain out of scope. |
| Product Manager | PASS | Public Beta is not claimed; evidence pack gates beta language. |
| Installer / macOS Release Engineer | PASS | No installer behavior changed in this hygiene pass; #94 remains protected. |
| Security / Privacy Architect | PASS | No cloud defaults, telemetry, POST controls, or approval bypasses added. |
| Local AI Systems Engineer | PASS | 8GB low/core remains the protected baseline; no heavy default profiles added. |
| Backend / Merlin Core Engineer | PASS | 8765/8766 boundaries unchanged. |
| UX Director | PASS | Readiness language remains honest and staged. |
| UI Designer | PASS | Merlin branding remains premium and non-fantasy. |
| UI Tester / First-Time User Tester | WATCH | Full first-run screenshots still need to be captured during the manual evidence run. |
| QA Automation Engineer | PASS | Added static README/evidence checks without live-service dependencies. |
| Manual QA / UAT Lead | WATCH | Full installer retest is triggered but not yet executed in this pass. |
| Documentation / Governance Lead | PASS | Updated stale queue references after #97 closure. |
| Commercial Readiness Reviewer | WATCH | Local Trusted Beta path improved; Public Beta remains blocked on evidence and signing/onboarding work. |

## Files Changed

- `.github/workflows/ci.yml`
- `README.md`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MASTER_CONTEXT.md`
- `docs/MASTER_PROMPT.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`
- `docs/operations/FAILURE_LEARNING_LOOP.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `tests/beta-readiness-evidence-smoke.sh`
- `tests/release-readiness-readme-smoke.sh`

## Tests Run

- `git diff --check`
- `bash -n install.sh`
- `bash install.sh --help`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `bash tests/beta-readiness-evidence-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `bash tests/master-prompt-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`

## Test Output Summary

All static validation commands above passed locally. `bash install.sh --help`
returned usage only and had no install side effects.

## Tests Skipped And Why

- Full clean install/uninstall/reinstall/upgrade retest: not run in this
  hygiene pass. It is explicitly triggered and must be run against the evidence
  pack before Local Trusted Beta signoff.
- Live Docker/Ollama/Qdrant checks: not required for docs/static hygiene.

## Failures Found

- Stale docs still described #97 as active after GitHub showed it closed.
  Corrected in canonical roadmap/context.
- Local process gap: the repo had evidence notes but did not yet have a
  canonical continuous failure-learning protocol. Added
  `docs/operations/FAILURE_LEARNING_LOOP.md` and linked it from the beta
  evidence pack.

## Failure Category

- Roadmap/governance drift
- Test design gap

## Root Cause Or Current Hypothesis

Release evidence existed, but the failure capture contract was embedded in chat
instructions instead of enforced by repo docs and static smokes.

## Fix Applied

- Added continuous failure-learning operations doc.
- Linked it from the Local Trusted Beta evidence pack.
- Extended `tests/beta-readiness-evidence-smoke.sh` so CI checks for the
  failure-learning contract.

## Retest Result

Passed:

- `bash tests/beta-readiness-evidence-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `bash tests/master-prompt-smoke.sh`
- `bash -n tests/beta-readiness-evidence-smoke.sh`
- `git diff --check`

## Regression Test Added Or Reason Not Added

Updated `tests/beta-readiness-evidence-smoke.sh` to assert the evidence pack and
failure-learning protocol include the required release-readiness rules.

## Follow-Up Issues Created Or Recommended

- #98 created for the GitHub Actions Node.js 20 deprecation warning observed in
  green CI run `25532642692`.
- Continue existing #37 for public onboarding/release packaging hardening.
- Continue existing #64 for Developer ID signing/notarization.
- Continue existing #95 as the umbrella until the evidence pack is filled with
  manual results.

## What Was Learned

- The repo is improving faster because #94/#96/#97 now have CI-backed static
  checks, but Local Trusted Beta still depends on a real 8GB low/core installer
  retest after these user-facing changes.
- Failure learning has to live in the repository, not just in a session prompt,
  or future agents will skip it during a long validation run.

## What Not To Touch Next Time

- Do not start #92 native automation runtime.
- Do not touch #81-#84 patent/IP implementation without explicit instruction.
- Do not change installer/uninstaller behavior unless a verified defect is
  found during the evidence-pack retest.
- Do not claim Public Beta readiness.
- Do not fix installer or service failures without recording the failure
  pattern, retest, release impact, and regression-test decision.

## Next Recommended Step

Run `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md` on the 8GB Mac low/core
path and fill the evidence table. Any failure becomes a focused GitHub issue
before #95 can close.
