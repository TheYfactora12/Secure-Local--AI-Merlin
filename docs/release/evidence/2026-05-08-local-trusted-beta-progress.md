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

---

## Live 8GB Low/Core Evidence Run — 2026-05-08 UTC

### Date / Time

2026-05-08 UTC / 2026-05-07 EDT.

### Branch

`main`

### Starting Commit SHA

`4fccc027745f842de4224779ba36384c1858fb6d` —
`docs(issue-95): add continuous failure learning loop`

### Ending Commit SHA

`1a7ad16` —
`fix(beta): harden local trusted beta readiness evidence — refs #95 #99 #100`

### GitHub Actions

CI run `25533751581` passed on `main`.

### Target Issues

- #95: Product push audit / release-readiness umbrella.
- #37: Public release onboarding and packaging hardening support.
- #64: Developer ID signing/notarization remains open.
- #99: Created from this run for stale installer final readiness branding.
- #100: Created from this run for 8GB warmup diagnostics hardening.

### Scope

8GB Mac low/core Local Trusted Beta evidence run:

- uninstall with data reset for fresh local stack state,
- non-interactive core install with model pulls disabled,
- launchd registration and delayed readiness validation,
- doctor/status/dashboard/API/privacy smokes,
- uninstall/reinstall/upgrade path smoke,
- failure learning and regression-test updates.

### Files Changed

- `docker-compose.yml`
- `install.sh`
- `scripts/status.sh`
- `scripts/upgrade.sh`
- `tests/installer-branding-smoke.sh`
- `tests/qdrant-local-first-smoke.sh`
- `tests/status-profile-smoke.sh`
- `tests/update-upgrade-profile-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `install.sh`: text-only final summary fix. No install behavior, model pull,
  non-interactive, uninstall, package, cloud, or service-start behavior changed.

### Commands Run

| Command | Result |
|---|---|
| `git status --short` | PASS; clean before live run. |
| `git rev-parse HEAD` | PASS; `4fccc027745f842de4224779ba36384c1858fb6d`. |
| `uname -a` / `sw_vers` | PASS; macOS 26.4.1 arm64. |
| `docker info --format '{{json .ServerVersion}}'` | PASS; Docker `29.4.2`. |
| `bash scripts/doctor.sh --help` | PASS. |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS. |
| `bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data` | PASS; removed core containers/volumes and launchd agents. |
| `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive` | PASS; installed low/core, skipped model pulls, local-first keys empty. |
| `bash launchd/install-launchd.sh` | PASS; launchd agents registered. |
| `bash scripts/doctor.sh` before launchd delay | PASS with warnings; 8765/8766 warming/closed. |
| `sleep 35` then `curl http://localhost:8765/healthz` | PASS; status API read-only and `execution_allowed: false`. |
| `curl http://localhost:8766/status/routes` | PASS. |
| `bash tests/core-live-smoke.sh` | PASS; 18 passed, 0 warnings, 0 failures. |
| `bash tests/merlin-status-api-smoke.sh` | PASS; status API read-only and redacted. |
| `bash tests/merlin-task-api-smoke.sh` | PASS; task API lifecycle separate and localhost-only. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS. |
| `bash tests/dashboard-security-center-smoke.sh` | PASS. |
| `bash tests/installer-model-pull-policy-smoke.sh` | PASS. |
| `bash tests/openwebui-local-first-smoke.sh` | PASS. |
| `bash tests/sast-gitleaks-smoke.sh` | SKIP; local `gitleaks` CLI not installed, CI gitleaks gate remains configured. |
| `bash tests/merlin-magic-plan-smoke.sh` | PASS. |
| `bash tests/merlin-audit-view-smoke.sh` | PASS. |
| `bash cli/wizard merlin magic-plan "prepare a local-first beta readiness checklist"` | FAIL; CLI syntax is stale. |
| `bash cli/wizard merlin audit recent` | FAIL; CLI syntax is stale. |
| `bash cli/wizard merlin magic plan "prepare a local-first beta readiness checklist"` | PASS; plan-only, no model calls, no memory writes, no execution. |
| `bash cli/wizard merlin audit list` | PASS; local JSONL, redacted, no telemetry. |
| `curl http://localhost:4000/health/readiness` | PASS. |
| `curl http://localhost:3000` | PASS. |
| `curl http://localhost:8766/status/approvals` at 3s/10s during concurrent probes | FAIL; timed out during load/warmup. |
| `curl -v --max-time 5 http://localhost:8766/status/approvals` after warmup | PASS. |
| `curl -v --max-time 5 http://localhost:8766/status/memory` after warmup | PASS. |
| `bash scripts/status.sh` inside sandbox | FAIL; sandbox blocked accurate Docker/localhost access. |
| `bash scripts/status.sh` outside sandbox | PASS; showed accurate core services. |
| `bash pkg/scripts/uninstall.sh --yes --keep-files` | PASS; removed stack and launchd agents, kept files/models. |
| Reinstall command with non-interactive low/core flags | PASS. |
| `bash scripts/upgrade.sh --profile core` | PASS; backup saved and repo already up to date. |
| `docker compose logs --tail=80 qdrant` before fix | FAIL privacy check; Qdrant logged `Telemetry reporting enabled`. |
| `bash tests/qdrant-local-first-smoke.sh` | PASS after fix. |
| `docker compose up -d --force-recreate qdrant` | PASS. |
| `docker compose logs --tail=80 qdrant` after fix | PASS; Qdrant logged `Telemetry reporting disabled`. |
| `bash tests/installer-branding-smoke.sh` | PASS after installer final banner fix. |
| `bash tests/status-profile-smoke.sh` | PASS. |
| `bash tests/update-upgrade-profile-smoke.sh` | PASS. |
| `docker compose config -q` | PASS. |
| `bash -n install.sh` | PASS. |
| `bash install.sh --help` | PASS. |
| `bash scripts/doctor.sh` after fixes | PASS; 52 passed, 3 warnings, 0 failures. |
| `bash scripts/status.sh` after fix | PASS; disabled optional services now show `DISABLED`, not red `DOWN`. |

### Test Output Summary

The low/core stack installed, launched, and served the expected local endpoints
on an 8GB Mac. Core services validated:

- Wizard HQ dashboard: `http://localhost:8888`
- Open WebUI: `http://localhost:3000`
- LiteLLM: `http://localhost:4000`
- Qdrant: `http://localhost:6333`
- Merlin Status API: `http://localhost:8765`
- Merlin Task API: `http://localhost:8766`
- Native Ollama: `http://localhost:11434`

Privacy checks passed after the Qdrant telemetry fix:

- OpenAI/Anthropic/Perplexity/GitHub keys empty by default.
- Status API reports `execution_allowed: false`.
- Magic Mode remains `plan_only`.
- Qdrant telemetry is disabled.
- Optional n8n/OpenHands/search profiles did not start in core mode.

### Tests Skipped And Why

- `bash tests/sast-gitleaks-smoke.sh`: skipped locally because the `gitleaks`
  CLI is not installed on this Mac. The CI gitleaks/secret-scan gate remains
  configured and must stay required.
- Developer ID signing/notarization: not in scope; tracked by #64.
- Public Beta package signoff: not claimed. Full package GUI install evidence
  remains required before Public Beta.

### Failures Found

1. Installer final banner still said `WIZARD AI IS READY ✓ v1.6`.
2. Qdrant default container telemetry was enabled.
3. `scripts/status.sh` showed disabled optional profiles as red `DOWN`.
4. `scripts/upgrade.sh --profile core` success banner advertised n8n despite
   the automation profile being disabled.
5. Evidence prompt/manual command examples used stale CLI forms:
   `wizard merlin magic-plan` and `wizard merlin audit recent`.
6. Merlin task API status probes timed out during concurrent warmup/load but
   passed after warmup.
7. Doctor log scan still sees an old task API bind error in historical logs.
8. Local `gitleaks` CLI is missing.
9. Tooling failure: an initial `gh issue create --body "..."` attempt used an
   inline shell string containing command examples and caused local shell
   expansion/execution. The hung process was killed and the issue was recreated
   safely with `--body-file`.
10. Tooling failure repeated on an inline `gh issue comment --body "..."` with
    backticks in the body. The issue had already been closed successfully; a
    safe follow-up comment was posted with `--body-file`.

### Failure Categories

- Installer flow
- Wizard HQ/dashboard readiness
- No-cloud/default privacy
- UX/readiness confusion
- Documentation mismatch
- CI/static smoke gap
- Test design gap
- Launchd/autostart timing
- Low-memory/8GB behavior
- Release tooling/operator error

### Root Cause Or Current Hypothesis

- The #94 branding work did not include the final installer completion banner.
- Qdrant telemetry defaults to enabled unless explicitly disabled by environment.
- `scripts/status.sh` was not profile-aware even though doctor/profile-lib are.
- `scripts/upgrade.sh` used a static success banner rather than active profile
  capabilities.
- Some manual evidence commands came from older CLI syntax and were not kept in
  sync with current `cli/wizard`.
- Task API timeouts were transient during warmup/concurrent probing on 8GB;
  final sequential checks passed. This remains a WATCH item for dashboard
  timeout tolerance.
- The doctor log warning is historical: an earlier task API process attempted to
  bind to 8766 while another listener existed. Current API process is healthy.
- Inline `gh issue create --body "..."` is unsafe for multiline issue bodies
  that contain backticks, shell examples, or command substitutions.

### Fix Attempted

- Added `QDRANT__TELEMETRY_DISABLED=true` to the Qdrant service.
- Added `tests/qdrant-local-first-smoke.sh`.
- Changed final installer banner to `MERLIN AI CORE INSTALLED`.
- Extended `tests/installer-branding-smoke.sh` to reject the stale
  `WIZARD AI IS READY` phrase.
- Made `scripts/status.sh` profile-aware and changed disabled optional profiles
  from red `DOWN` to `DISABLED`.
- Added `tests/status-profile-smoke.sh`.
- Made `scripts/upgrade.sh` advertise optional profile URLs only when enabled.
- Extended `tests/update-upgrade-profile-smoke.sh` to catch n8n in core upgrade
  output.
- Opened #99 for the installer banner before making the local fix, preserving
  failure traceability.
- Killed the malformed `gh issue create` process and recreated the diagnostics
  follow-up as #100 using `--body-file /private/tmp/homeai-issue-100.md`.
- Reposted the #99 completion comment using
  `--body-file /private/tmp/homeai-issue-99-close-comment.md`.

### Retest Result

Passed after fixes:

- `bash tests/qdrant-local-first-smoke.sh`
- `docker compose config -q`
- `docker compose up -d --force-recreate qdrant`
- `docker compose logs --tail=80 qdrant` showed
  `Telemetry reporting disabled`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/status-profile-smoke.sh`
- `bash tests/update-upgrade-profile-smoke.sh`
- `bash -n install.sh`
- `bash install.sh --help`
- `bash scripts/doctor.sh`
- `bash scripts/status.sh`

### Regression Tests Added

- `tests/qdrant-local-first-smoke.sh`
- `tests/status-profile-smoke.sh`

Regression tests updated:

- `tests/installer-branding-smoke.sh`
- `tests/update-upgrade-profile-smoke.sh`

### Runbook / Docs Updated

- This evidence note was updated with the live run.
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md` was updated to use the
  current CLI syntax: `wizard merlin magic plan` and
  `wizard merlin audit list`.

### Follow-Up Issues Created Or Recommended

- Created #99: `v3.0: Align installer final readiness banner with Merlin brand
  and partial readiness`. Fixed in `1a7ad16`, verified by CI `25533751581`,
  and closed.
- Created #100: `v3.0: Harden 8GB warmup diagnostics for Merlin API readiness`.
- Recommended follow-up: tune dashboard/task API polling for 8GB warmup so
  transient 3-second endpoint timeouts display as `warming`, not failure.
- Recommended follow-up: doctor log scan should distinguish historical/stale
  errors from current-run errors.
- Recommended follow-up: install `gitleaks` locally or document local skip
  while CI remains authoritative.

### Lessons Learned

- Live logs matter. Static docs said no telemetry, but Qdrant live logs proved
  the runtime default was still telemetry-enabled.
- Profile-aware status output is as important as profile-aware startup. Red
  `DOWN` for intentionally disabled optional services weakens user trust on
  8GB/core.
- Evidence prompts must be tested against the real CLI. Stale command examples
  create false failures during release validation.
- Launchd readiness has a deliberate delay; first-run UI and docs should call
  this `warming`, not `down`.

### What Not To Repeat Next Time

- Do not assume “local-first” config means every third-party container telemetry
  flag is disabled; verify logs after startup.
- Do not run status diagnostics inside a sandbox and treat Docker/socket failures
  as product failures without an outside-sandbox retest.
- Do not advertise optional profile URLs in core-mode success banners.
- Do not mark stale historical log errors as current defects without checking
  live process and port state.
- Do not use old CLI command examples in evidence runs.
- Do not create multiline GitHub issues with inline `--body "..."` when the body
  contains shell snippets; write a body file and use `--body-file`.

### Whether Any Failure Blocks Local Trusted Beta

Before fixes, Qdrant telemetry enabled was a Local Trusted Beta blocker.
After fix and retest, no confirmed Local Trusted Beta blocker remains from this
specific run, but the following WATCH items remain before signoff:

- task API/dashboard warmup timeout tolerance on 8GB,
- stale CLI examples in release docs,
- doctor historical log warning behavior,
- #64 Developer ID signing/notarization for broader release packaging.

### Whether Any Failure Blocks Public Beta

Yes. Public Beta remains blocked by:

- #64 Developer ID signing/notarization,
- complete package GUI install evidence,
- screenshot/log evidence pack completion,
- public onboarding polish under #37,
- resolution or accepted deferral of 8GB warmup/status UX WATCH items.

### Local Trusted Beta Impact

Improved. This run turned a real privacy blocker into a tested config invariant
and tightened the first-run diagnostics surface for 8GB/core.

### Public Beta Impact

Improved but not enough for Public Beta. The product is closer to a controlled
Local Trusted Beta path, but public release still requires packaging/signing and
full human-facing onboarding evidence.

---

## Issue #100 Warmup Diagnostics Fix — 2026-05-08 UTC

### Scope

Harden first-run readiness diagnostics so 8GB/core users see `warming` and
historical-log guidance instead of ambiguous degraded/down states.

### Files Changed

- `dashboard/index.html`
- `scripts/doctor.sh`
- `tests/dashboard-readiness-smoke.sh`
- `tests/doctor-warmup-diagnostics-smoke.sh`

### Commands Run

| Command | Result |
|---|---|
| `gh issue edit 100 --milestone "v3.0 — Public Product Release" --add-label "v3.0" --add-label "release" --add-label "ux" --add-label "qa" --add-label "priority: high"` | PASS |
| `bash tests/doctor-warmup-diagnostics-smoke.sh` | PASS |
| `bash tests/dashboard-readiness-smoke.sh` | PASS |
| `bash scripts/doctor.sh` | PASS; `52 passed / 3 warnings / 0 failures` |
| `bash scripts/status.sh` | PASS |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS |
| `bash tests/dashboard-security-center-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Failures Found

- Static dashboard smoke initially expected `readiness: degraded`, but #100
  intentionally changes launchd/API startup copy to `readiness: warming`.

### Failure Category

- Test design gap
- UX/readiness confusion

### Root Cause Or Current Hypothesis

The old test encoded the previous degraded-state language and did not reflect
the newer warmup contract for launchd-delayed services on 8GB systems.

### Fix Applied

- Increased dashboard service probe timeout to 5 seconds.
- Increased dashboard status-panel timeout to 7 seconds.
- Added shared launchd warmup copy: 35-40 seconds after launchd registration.
- Changed Task API, approvals, memory, router, and final readiness copy from
  premature degraded/fix-needed language to warming where appropriate.
- Updated doctor to label stale log warnings as historical when Merlin API ports
  are currently open.
- Added a safe stale-log remediation hint after evidence is saved.

### Retest Result

All #100 targeted tests passed locally. Live doctor output now says:

`Historical log scan: 1 ERROR/CRITICAL lines found, but Merlin API ports are currently open`

### Regression Tests Added

- `tests/doctor-warmup-diagnostics-smoke.sh`

Regression tests updated:

- `tests/dashboard-readiness-smoke.sh`

### Lessons Learned

Readiness UX must model time. On an 8GB Mac, a service can be correctly
launching and still look down for a short window. The product should call that
`warming`, not make the user diagnose launchd timing.

### What Not To Repeat Next Time

Do not encode degraded-state wording in tests when the intended state is a
temporary launchd warmup window.

### Local Trusted Beta Impact

Improved. This removes one of the remaining first-run trust gaps from the prior
evidence run.

### Public Beta Impact

Improved, but Public Beta remains blocked by signing/notarization and full
package/onboarding evidence.

---

## Issue #37 First-Run Product Clarity Slice — 2026-05-08 UTC

### Scope

Advance public onboarding/package-hardening issue #37 without claiming Public
Beta readiness: make Wizard HQ explain where Merlin lives today, how local chat
relates to Qwen/Open WebUI, and which setup actions remain disabled or
approval-gated.

### Starting Commit SHA

`a291ed3bf5e01ee3740a797b9655e7470a9714fe` —
`fix(readiness): harden 8GB warmup diagnostics — closes #100`

### Files Changed

- `.github/workflows/ci.yml`
- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. `install.sh`, `pkg/scripts/*`, uninstall behavior, model-pull defaults,
service startup, status API, and task API behavior were not changed.

### Commands Run

| Command | Result |
|---|---|
| `gh issue view 37 --json number,title,state,labels,milestone,body` | PASS; #37 is open in `v3.0 — Public Product Release`. |
| `bash -n tests/dashboard-first-run-smoke.sh` | PASS |
| `bash tests/dashboard-first-run-smoke.sh` | FAIL first run; test falsely matched safety copy. PASS after test fix. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS |
| `bash tests/dashboard-security-center-smoke.sh` | PASS |
| `bash tests/dashboard-readiness-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `bash tests/release-readiness-readme-smoke.sh` | PASS |
| `bash tests/installer-branding-smoke.sh` | PASS |
| `bash tests/pkg-readiness-smoke.sh` | PASS |
| `bash tests/uninstall-smoke.sh` | PASS |
| `gh run watch 25535113030 --exit-status` | PASS; full CI completed successfully for commit `7dc471e`. |
| `gh api repos/TheYfactora12/home-ai-elite/actions/runs/25535113030/annotations` | FAIL; endpoint does not exist for workflow-run annotations. |
| `gh api repos/TheYfactora12/home-ai-elite/commits/7dc471edf4f624bca9b989278ba4cb2d58fc8c34/check-runs --jq '.check_runs[] | [.id,.name,.conclusion] | @tsv'` | PASS; listed successful check run IDs. |
| `gh api repos/TheYfactora12/home-ai-elite/check-runs/74949294820/annotations` | PASS; returned `[]` for the Python unit-test check run. |
| `gh issue comment 98 --body-file /private/tmp/homeai-issue-98-close-comment.md` | PASS |
| `gh issue close 98 --comment "Closed after setup-python v6 migration..."` | PASS |
| `bash -n install.sh` | PASS |
| `bash install.sh --help` | PASS; usage only, no install side effects. |
| `bash scripts/doctor.sh` | PASS; 52 passed, 3 warnings, 0 failures. |
| `bash scripts/status.sh` | PASS; core services running, optional profiles disabled. |
| `git diff --check` | PASS |

### Failures Found

- New first-run smoke initially failed because the unsafe-action regex matched
  the existing safety sentence that says the dashboard does not download models.

### Failure Category

- Test design gap

### Root Cause Or Current Hypothesis

The test searched for broad phrases like `download model` instead of detecting
actual controls, function names, or imperative unsafe actions.

### Fix Applied

Changed the smoke test to detect unsafe buttons/functions such as
`downloadModel`, `pullModel`, `runShell`, `writeMemory`, or configure-provider
controls while allowing safety copy that explains those actions are blocked.

### Retest Result

Passed:

- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/beta-readiness-evidence-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `bash -n install.sh`
- `bash install.sh --help`
- `bash scripts/doctor.sh`
- `bash scripts/status.sh`
- `git diff --check`

### Regression Tests Added

- `tests/dashboard-first-run-smoke.sh`

Regression tests updated:

- `tests/dashboard-merlin-status-smoke.sh`
- `.github/workflows/ci.yml` now runs the first-run dashboard smoke in CI.

### Runbook / Docs Updated

- This evidence note records the #37 first-run slice and the test-design
  failure pattern.

### Lessons Learned

The user-facing product needs to say plainly: Open WebUI/Qwen is the current
local chat/model workspace, while Merlin is the routing, policy, memory, audit,
and readiness layer. Hiding that relationship makes the product feel confusing
even when the stack is technically healthy.

### What Not To Repeat Next Time

Do not treat safety copy as an unsafe action in static tests. Tests should look
for controls and executable wiring, not block the words used to explain guardrails.

### Local Trusted Beta Impact

Improved. First-run users now get a clearer answer to "where is Merlin?" without
adding write controls, model downloads, cloud setup, or memory actions.

### Public Beta Impact

Improved, but #37 remains open. Public Beta still requires full onboarding,
package GUI evidence, backup/restore verification, and #64 signing/notarization.

---

## Issue #98 CI Node Runtime Hardening — 2026-05-08 UTC

### Scope

Resolve the known GitHub Actions Node.js 20 deprecation warning for the Python
unit-test job without changing job semantics, test coverage, installer behavior,
dashboard behavior, Merlin runtime behavior, or package behavior.

### Starting Commit SHA

`5ef94a7186cead87e6bcdbe3d6b0e18eb7b125a4` —
`feat(dashboard): clarify Merlin first-run experience — refs #37 #95`

### Files Changed

- `.github/workflows/ci.yml`
- `tests/ci-actions-node-runtime-smoke.sh`
- #98 was commented and closed after CI and annotation verification.
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `.github/workflows/ci.yml`: protected CI gate file. Change is limited to
  `actions/setup-python@v6` and adding a static smoke to the existing static
  smoke job.

No installer, package script, uninstall, launchd, service startup, model-pull,
API, memory, dashboard, cloud, or execution behavior changed.

### Commands Run

| Command | Result |
|---|---|
| `gh issue view 98 --json number,title,state,body,labels,milestone` | PASS; #98 is open in `v3.0 — Public Product Release`. |
| `rg -n "uses: actions/setup-python\|uses: actions/checkout\|actions/" .github/workflows` | PASS; only `actions/setup-python@v5` needed upgrade. |
| `bash -n tests/ci-actions-node-runtime-smoke.sh` | PASS |
| `bash tests/ci-actions-node-runtime-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `bash tests/release-readiness-readme-smoke.sh` | PASS |
| `git diff --check` | PASS |
| `bash -n install.sh` | PASS |
| `bash install.sh --help` | PASS; usage only, no install side effects. |
| `bash tests/installer-branding-smoke.sh` | PASS |
| `bash tests/pkg-readiness-smoke.sh` | PASS |
| `bash tests/uninstall-smoke.sh` | PASS |

### Tests Skipped And Why

No live Docker/Ollama/Qdrant checks were required because this is a
workflow-version change only.

### Failures Found

- `gh api repos/TheYfactora12/home-ai-elite/actions/runs/25535113030/annotations`
  returned 404 because workflow-run annotations are not exposed at that path.

### Failure Category

- Release tooling/operator error

### Root Cause Or Current Hypothesis

GitHub Actions emitted a Node.js 20 runtime deprecation annotation for
`actions/setup-python@v5`. Updating to `actions/setup-python@v6` is the narrow
release-hardening fix.

### Fix Applied

- Updated `.github/workflows/ci.yml` from `actions/setup-python@v5` to
  `actions/setup-python@v6`.
- Added `tests/ci-actions-node-runtime-smoke.sh` so CI rejects
  `actions/setup-python@v5` and any workflow-local `node20` references.
- Wired the new smoke into the existing static smoke job.

### Retest Result

Passed locally:

- `bash tests/ci-actions-node-runtime-smoke.sh`
- `bash tests/beta-readiness-evidence-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `git diff --check`
- `bash -n install.sh`
- `bash install.sh --help`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/uninstall-smoke.sh`

GitHub Actions run `25535113030` passed for commit `7dc471e`. The Python
unit-test check run annotation query returned `[]`, so the previously observed
Node.js 20 warning was not present on the affected job after the v6 upgrade.

### Regression Tests Added

- `tests/ci-actions-node-runtime-smoke.sh`

### Runbook / Docs Updated

- This evidence note records the #98 CI runtime-hardening slice.

### Lessons Learned

CI platform warnings are release-hardening work even when the current run is
green. If a warning can become a future CI failure, pin a regression smoke near
the workflow instead of relying on memory.

GitHub Actions annotations are attached to check runs, not to the workflow run
path I first tried. Use the commit check-runs endpoint, then query the affected
check-run annotations.

### What Not To Repeat Next Time

Do not treat green CI as sufficient when GitHub emits platform deprecation
annotations. Track and close the warning while the replacement action is still
a safe one-line update.

Do not use the nonexistent workflow-run annotations path; query check-run
annotations instead.

### Local Trusted Beta Impact

Neutral to slightly improved. This does not affect runtime behavior, but it
keeps the required CI gates from carrying known platform drift.

### Public Beta Impact

Improved. Public Beta should not ship with known avoidable GitHub Actions
runtime deprecation warnings.

---

## Clean Install Prep Uninstall — 2026-05-08 UTC

### Scope

Uninstall the local Home AI Elite product stack to prepare for a later clean
install test. Developer ID signing/notarization remains deferred until the
product surface is complete.

### Starting Commit SHA

`10080608005eebd8b89e3cafea57dd97f68becd0` —
`docs(issue-98): align roadmap after ci warning closure`

### Files Changed

- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package script, uninstall script, launchd plist, service,
API, dashboard, model, memory, cloud, or execution behavior was changed.

### Commands Run

| Command | Result |
|---|---|
| `bash pkg/scripts/uninstall.sh --help` | PASS; confirmed `--keep-files` and `--remove-data` behavior. |
| `git status --short --branch` | PASS; clean before uninstall. |
| `bash scripts/status.sh` before uninstall | PASS; core stack running, optional profiles disabled. |
| `sed -n '1,260p' pkg/scripts/uninstall.sh` | PASS; verified default mode would remove the working repo path, so `--keep-files` was required. |
| `bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data` | PASS with admin warning for pkg receipt cleanup. |
| `bash scripts/status.sh` after uninstall | PASS; Dashboard/Open WebUI/LiteLLM/Qdrant down, optional services disabled, native Ollama still running. |
| `docker compose ps` | PASS; no compose containers running. |
| `launchctl list | rg 'homeai|merlin' || true` | PASS; no HomeAI/Merlin launchd agents listed. |
| `ls -l /Users/kevinmedeiros/home-ai-elite-env-backup-20260507_234435.env` | PASS; `.env` backup exists with `600` permissions. |
| `curl -fsS --max-time 3 http://localhost:8765/healthz` | Expected FAIL; port 8765 no longer listening after uninstall. |
| `curl -fsS --max-time 3 http://localhost:8766/status/routes` | Expected FAIL; port 8766 no longer listening after uninstall. |
| `docker volume ls --format '{{.Name}}'` | PASS with escalation; showed only unrelated Docker volume. |
| `docker volume ls --filter name=home-ai-elite --format '{{.Name}}'` | PASS; no Home AI Elite Docker volumes remain. |

### Tests Skipped And Why

- Full clean reinstall: intentionally deferred. This uninstall prepares the
  machine for that later clean-install evidence run.
- Developer ID / notarization tests: explicitly deferred until the final product
  is polished enough to justify public distribution signing.

### Failures Found

- Package receipt cleanup could not run without admin privileges:
  `sudo pkgutil --forget com.homeai.elite` is still needed if receipt cleanup
  is required before the clean install test.
- A non-escalated `docker volume ls | rg ...` check hit Docker socket permission
  denial; reran volume verification with approved Docker volume access and
  without a pipe.

### Failure Category

- Package signing/notarization
- Package/uninstall cleanup
- Release tooling/operator environment

### Root Cause Or Current Hypothesis

- The uninstaller correctly avoids privileged receipt removal unless sudo is
  available non-interactively.
- Docker socket access can differ between sandboxed and escalated commands.

### Fix Applied

- Preserved repo files by using `--keep-files`.
- Removed product Docker data with `--remove-data`.
- Verified Home AI Elite volumes are absent using `docker volume ls --filter`.
- Did not force package receipt cleanup because it requires admin privileges and
  is not needed to stop services or remove Docker data.

### Retest Result

After uninstall:

- Core Docker containers are stopped and removed.
- Home AI Elite Docker volumes are removed.
- HomeAI/Merlin launchd agents are not listed.
- 8765 and 8766 are down as expected.
- `.env` backup exists at
  `/Users/kevinmedeiros/home-ai-elite-env-backup-20260507_234435.env`.
- Native Ollama and local models remain installed, matching the uninstaller
  safety contract.

### Regression Test Added Or Reason Not Added

No regression test added. Existing `tests/uninstall-smoke.sh` already covers
guarded uninstaller behavior. This was a live machine state operation, not a
code defect.

### Follow-Up Issues Created Or Recommended

- No new issue required.
- Before the later clean install test, decide whether to manually run:
  `sudo pkgutil --forget com.homeai.elite`
  if package receipt state matters for that test.

### Lessons Learned

The uninstaller default would remove `/Users/kevinmedeiros/home-ai-elite`, which
is also the active development repo. For clean-install prep during development,
use `--keep-files --remove-data` unless the repo has first been moved or cloned
elsewhere.

### What Not To Repeat Next Time

Do not run the uninstaller default from inside the working repo unless the goal
is to delete the repo. Use `--keep-files` for development-machine reset runs.

### Local Trusted Beta Impact

Improved. The machine is now reset at the product-stack/data level and ready for
a later clean install validation run.

### Public Beta Impact

Neutral. Developer ID signing remains intentionally deferred until product
quality, onboarding, and release evidence are stronger.

---

## Issue #101 Wizard HQ Front Door Spec — 2026-05-08 UTC

### Scope

Capture the next Wizard HQ direction: Merlin AI becomes the primary product
front door, while Qwen/Ollama, Open WebUI, LiteLLM, other local models, and
optional cloud APIs are shown as replaceable brains/connectors under Merlin.

### Starting Commit SHA

`3fc65d924956e144df4c8c7e79d94773d83a35fc` —
`docs(release): record clean install prep uninstall`

### Files Changed

- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/product/DASHBOARD_UI_SPEC.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package, dashboard runtime, service, API, memory, model,
cloud, or execution behavior changed.

### Commands Run

| Command | Result |
|---|---|
| `gh issue list --state open --milestone "v3.0 — Public Product Release" --json number,title,labels` | PASS |
| `sed -n '1,220p' docs/product/MERLIN_BRAND_UX_SPEC.md` | PASS |
| `sed -n '1,220p' docs/product/DASHBOARD_UI_SPEC.md` | PASS |
| `sed -n '1,220p' docs/product/DASHBOARD_PRODUCT_SPEC.md` | PASS |
| `gh issue create --title "v3.0: Wizard HQ Merlin-native front door and brains tab UX" --body-file /private/tmp/homeai-wizard-hq-front-door-issue.md --milestone "v3.0 — Public Product Release" --label "release" --label "v3.0" --label "ux" --label "product" --label "priority: high"` | PASS; created #101. |
| `bash tests/master-prompt-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `git diff --check` | PASS |
| `git push origin main` | PASS; pushed `a02dbbe`. |
| `gh run watch 25535810742 --exit-status` | PASS; CI passed for `a02dbbe`. |
| `gh run view 25535810742 --json status,conclusion,headSha,url` | FAIL; transient GitHub API connection error after the watch had already confirmed success. |

### Tests Skipped And Why

- Live dashboard/browser testing was skipped because the local product stack is
  intentionally uninstalled/reset for the later clean install test.
- No live Docker/Ollama/Qdrant checks were required for this docs/issue slice.

### Failures Found

- Final `gh run view` retry failed with a transient `api.github.com`
  connection error after `gh run watch` had already confirmed the workflow
  passed.

### Failure Category

- Release tooling/operator environment

### Root Cause Or Current Hypothesis

Network/API transient after the authoritative CI watch result completed.

### Fix Applied

No code fix required. The successful `gh run watch` output is the evidence for
CI success on this slice.

### Retest Result

- Local static checks passed.
- GitHub Actions run `25535810742` passed for commit `a02dbbe`.

### Regression Test Added Or Reason Not Added

No regression test added yet. #101 defines the next implementation slice, whose
acceptance criteria require static dashboard tab/no-unsafe-controls tests when
the UI changes land.

### Follow-Up Issues Created Or Recommended

- Created #101: `v3.0: Wizard HQ Merlin-native front door and brains tab UX`.

### Lessons Learned

The product needs to stop feeling like "Open WebUI plus a status dashboard."
Wizard HQ should make Merlin feel like the app, with models and APIs presented
as optional brains/connectors.

### What Not To Repeat Next Time

Do not let Qwen, Llama, Open WebUI, LiteLLM, or any provider become the product
identity. They are engines Merlin can use.

### Local Trusted Beta Impact

Improved planning clarity. No runtime behavior changed.

### Public Beta Impact

Improved product direction. Public Beta still requires implementation,
onboarding evidence, clean install evidence, and final release-hardening work.
