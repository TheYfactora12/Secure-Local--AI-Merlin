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

---

## Uninstaller Full-Purge Product Gap — 2026-05-08 UTC

### Scope

User expectation check after uninstall/reset: a product uninstall should offer a
clear way to remove every Merlin-managed piece it downloaded, not only stop the
stack and preserve models/images.

### Starting Commit SHA

`8e8e719b105c96e5fdf5b66d83b673d44f43dc88` —
`docs(release): record wizard hq front door planning`

### Target Issues

- #37 Public release onboarding and packaging hardening
- #95 Product push audit / release-readiness evidence

### Files Changed

- `pkg/scripts/uninstall.sh`
- `tests/uninstall-smoke.sh`
- `pkg/README.md`
- `pkg/resources/readme.html`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `pkg/scripts/uninstall.sh` — touched because uninstall completeness is release
  hardening and directly affects clean reinstall testing.
- `pkg/resources/readme.html` — touched to expose the full-purge path in package
  user docs.

### Commands Run

| Command | Result |
|---|---|
| `sed -n '1,260p' pkg/scripts/uninstall.sh` | PASS; confirmed old behavior explicitly kept Ollama models. |
| `sed -n '1,240p' tests/uninstall-smoke.sh` | PASS; confirmed existing smoke locked old preserve-model behavior. |
| `sed -n '130,185p' pkg/README.md` | PASS; confirmed docs only described default and `--remove-data`. |
| `sed -n '60,90p' pkg/resources/readme.html` | PASS; confirmed package readme lacked full-purge guidance. |
| `sed -n '1,220p' configs/merlin/model-tiers.env` | PASS; used Merlin model manifest as the safe purge list. |
| `bash -n pkg/scripts/uninstall.sh` | PASS |
| `bash tests/uninstall-smoke.sh` | PASS |
| `bash tests/pkg-readiness-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Tests Skipped And Why

- Did not run destructive live `--purge-all`; this slice adds and tests the
  dry-run path so CI can verify behavior without deleting local user assets.
- Did not run a clean reinstall yet because the next release validation pass
  should use the documented evidence-pack flow.

### Failures Found

- Product expectation failure: current uninstall behavior preserved Ollama
  models and Docker images by design, which does not satisfy a user expectation
  of "delete everything Merlin downloaded."

### Failure Category

- Installer flow
- Uninstall
- UX/readiness confusion
- Documentation mismatch

### Root Cause Or Current Hypothesis

The original uninstaller optimized for developer safety and fast reinstall by
preserving shared local dependencies and model downloads. That is a reasonable
default, but the product lacked an explicit full-purge mode for clean product
removal/reinstall testing.

### Fix Applied

- Added `--purge-all`.
- Added `--purge-models` for known Merlin-recommended Ollama models.
- Added `--purge-images` for Docker images used by the stack.
- Kept Docker Desktop, Homebrew, and the Ollama app/binary out of scope because
  they are system dependencies that may be used by other software.
- Updated package docs and smoke tests.

### Retest Result

- Static syntax and smoke tests passed.
- Dry-run purge verifies Docker volume/image cleanup and model removal commands
  without deleting local assets.

### Regression Test Added

- `tests/uninstall-smoke.sh` now verifies:
  - `--purge-all`
  - `--purge-models`
  - `--purge-images`
  - dry-run `docker compose down --volumes --rmi all --remove-orphans`
  - dry-run `ollama rm qwen2.5:7b`
  - dry-run `ollama rm nomic-embed-text`

### Follow-Up Issues Created Or Recommended

- No new issue required yet; this aligns with #37/#95 release hardening.
- Recommended later: a manual full-purge clean reinstall evidence run before
  Local Trusted Beta signoff.

### Lesson Learned

Default-safe uninstall and product-complete uninstall are different workflows.
Merlin needs both: a conservative default and an explicit full-purge path for
clean reinstall testing or user removal.

### What Not To Repeat Next Time

Do not describe uninstall as complete if known Merlin-managed downloads are
preserved without a visible purge option.

### Local Trusted Beta Impact

Improved. Trusted testers now have a documented full-purge path for clean
reinstall validation.

### Public Beta Impact

Improved. Public Beta still needs live uninstall/reinstall evidence after the
full-purge path lands.

---

## Issue #101 Wizard HQ Tab Shell Implementation — 2026-05-08 UTC

### Scope

Implemented the first read-only Wizard HQ product-shell slice so the dashboard
feels like Merlin AI first, with Qwen/Ollama, Open WebUI, LiteLLM, local models,
and future cloud APIs presented as replaceable brains/connectors under Merlin.

### Starting Commit SHA

`765a388976954057c3bdb0bfa31812164fc72c99` —
`feat(uninstall): add full Merlin purge path`

### Target Issues

- #101 Wizard HQ Merlin-native front door and brains tab UX
- #37 Public release onboarding and packaging hardening
- #95 Product push audit / release-readiness evidence

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-tabs-smoke.sh`
- `.github/workflows/ci.yml`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `.github/workflows/ci.yml` — touched only to add the new #101 dashboard tab
  smoke to the existing static smoke gate. Test semantics stayed the same.

### Commands Run

| Command | Result |
|---|---|
| `git status --short --branch` | PASS; working tree had only dashboard slice changes before implementation. |
| `gh issue view 101 --json number,title,state,body,labels,milestone` | PASS; confirmed #101 scope and acceptance criteria. |
| `sed -n '1,260p' dashboard/index.html` | PASS |
| `sed -n '261,620p' dashboard/index.html` | PASS |
| `sed -n '621,1040p' dashboard/index.html` | PASS |
| `sed -n '1,220p' tests/dashboard-readiness-smoke.sh` | PASS |
| `sed -n '1,220p' tests/dashboard-merlin-status-smoke.sh` | PASS |
| `sed -n '1,220p' tests/dashboard-security-center-smoke.sh` | PASS |
| `sed -n '1,220p' tests/dashboard-first-run-smoke.sh` | PASS |
| `bash -n tests/dashboard-tabs-smoke.sh` | PASS |
| `bash tests/dashboard-tabs-smoke.sh` | PASS |
| `bash tests/dashboard-readiness-smoke.sh` | PASS |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS |
| `bash tests/dashboard-first-run-smoke.sh` | PASS |
| `bash tests/dashboard-security-center-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `bash tests/release-workflow-smoke.sh` | PASS |
| `bash tests/master-prompt-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Tests Skipped And Why

- Live browser/dashboard smoke was skipped because the local product stack is
  intentionally uninstalled/reset for the later clean install validation run.
- No Docker/Ollama/Qdrant live checks were required for this static UI shell
  slice.

### Failures Found

None in local static validation.

### Failure Category

No failure.

### Root Cause Or Current Hypothesis

Not applicable.

### Fix Applied

- Added a premium, Merlin-first tab shell:
  - Chat
  - Brains
  - Memory
  - Agents
  - Security
  - System
  - Settings
- Added safe read-only status surfaces for brains/connectors, memory, agents,
  sovereignty/security, system health, and conservative settings.
- Added `selectTab()` client-side tab switching.
- Mirrored existing read-only service probes into new tab status fields.
- Added `tests/dashboard-tabs-smoke.sh`.
- Wired the new smoke into CI.

### Retest Result

All local static dashboard/release checks listed above passed.

### Regression Test Added

- `tests/dashboard-tabs-smoke.sh` verifies:
  - all seven tab labels and tab pages exist,
  - Merlin is presented as the product owner,
  - models/providers are presented as connectors,
  - Open WebUI is framed as a bridge, not product identity,
  - cloud is disabled by default,
  - no surprise-download language is preserved,
  - low-memory/8GB warning language exists,
  - approval-gated learning language exists,
  - no POST/execution calls, unsafe controls, secret fields, or secret-like
    values are introduced.

### Follow-Up Issues Created Or Recommended

- No new issue required. #101 remains open until live clean-install/browser
  validation confirms the tab shell renders correctly in the installed product.

### Lesson Learned

The right near-term path is not to replace Open WebUI internally yet. The safer
product step is to make Wizard HQ the Merlin front door and present Open WebUI
as the current local chat bridge.

### What Not To Repeat Next Time

Do not add Settings controls that collect API keys, download models, enable
cloud routing, write memory, or execute approvals until each has a dedicated
policy-gated backend issue and tests.

### Local Trusted Beta Impact

Improved. Wizard HQ now has the first product shell needed for a non-technical
trusted tester to understand Merlin as the app.

### Public Beta Impact

Improved but incomplete. Public Beta still requires live install/browser
evidence, onboarding polish, known limitations, and release hardening.

---

## Clean Install Evidence Run After Full Purge — 2026-05-08 UTC

### Scope

Ran a clean local install validation loop after adding the full-purge uninstall
path. The test intentionally used the low/core profile with model pulls disabled
to verify local-first, no-surprise-download behavior on the 8GB Mac.

### Starting Commit SHA

`1e0dede34d524ebc7d0d438bebcab3a43c6639ab` —
`feat(dashboard): add Merlin-native Wizard HQ tab shell`

### Target Issues

- #37 Public release onboarding and packaging hardening
- #95 Product push audit / release-readiness evidence
- #101 Wizard HQ Merlin-native front door and brains tab UX

### Files Changed

- `tests/core-live-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer logic, runtime APIs, dashboard runtime, Docker Compose, or
policy files were changed during this evidence/fix pass.

### Commands Run

| Command | Result |
|---|---|
| `bash pkg/scripts/uninstall.sh --purge-all --keep-files --yes` | PASS with expected warnings: Docker engine was not running for image/volume cleanup at the first purge step; package receipt cleanup needs admin privileges. Merlin-recommended Ollama models were removed when present. |
| `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive` | PASS; low/core profile installed, cloud keys skipped, model pulls skipped, Qdrant collections bootstrapped, dashboard/Open WebUI/LiteLLM/Qdrant started. |
| `bash scripts/doctor.sh` immediately after install | PASS with warnings: 47 passed, 8 warnings, 0 failures. Status/task APIs were not started because non-interactive install skips direct API start and launchd setup. |
| `bash scripts/status.sh` | PASS; Dashboard, Open WebUI, LiteLLM, Qdrant, Ollama running; optional profiles disabled. |
| `docker compose ps` | PASS; dashboard, open-webui, litellm, qdrant running. |
| `ollama list` | PASS; only `nomic-embed-text:latest` remained after purge. |
| `curl -v --max-time 5 http://127.0.0.1:8888/` | PASS; Wizard HQ returned HTTP 200. |
| `curl -v --max-time 5 http://127.0.0.1:3000/` | PASS; Open WebUI returned HTTP 200. |
| `bash launchd/install-launchd.sh` | PASS; registered Docker, stack, Merlin status API, and Merlin task API LaunchAgents. |
| `sleep 35` | PASS; waited through documented launchd warmup. |
| `curl -fsS --max-time 5 http://127.0.0.1:8765/healthz` | PASS after launchd warmup; execution_allowed false. |
| `curl -fsS --max-time 5 http://127.0.0.1:8766/status/routes` | PASS after launchd warmup; routes returned. |
| `bash scripts/doctor.sh` after launchd warmup | PASS with warnings: 51 passed, 4 warnings, 0 failures. |
| `bash tests/merlin-status-api-smoke.sh` | PASS |
| `bash tests/merlin-task-api-smoke.sh` | PASS |
| `bash tests/dashboard-tabs-smoke.sh` | PASS |
| `curl -fsS --max-time 5 http://127.0.0.1:8888/ -o /tmp/wizard-hq.html && rg -n "Wizard HQ\|data-tab-target=\"brains\"\|Merlin owns the experience\|Open WebUI Bridge\|cloud disabled by default\|Settings" /tmp/wizard-hq.html` | PASS; installed Wizard HQ contains the new tab shell and Brains copy. |
| `bash tests/core-live-smoke.sh` before fix | FAIL; LiteLLM chat completion failed for `qwen7b` because no generation model was installed after full purge plus skipped model pulls. |
| `bash -n tests/core-live-smoke.sh` after fix | PASS |
| `bash tests/core-live-smoke.sh` after fix | PASS with 15 passed, 2 warnings, 0 failures. |
| `bash tests/installer-model-pull-policy-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Tests Skipped And Why

- Did not pull `qwen2.5:7b`; model pulls are intentionally explicit and should
  not be forced during a no-surprise-download clean install test.
- Did not run full browser screenshot capture from this shell. HTTP evidence
  verifies the installed Wizard HQ HTML includes the tab shell; visual screenshot
  remains a manual beta evidence item.

### Failures Found

- `tests/core-live-smoke.sh` failed after the intentionally model-free install
  because it still attempted a LiteLLM chat completion against `qwen7b`.
- Manual `scripts/merlin-status-api.sh start` / `scripts/merlin-task-api.sh start`
  returned started PIDs from the Codex-managed shell, but those background
  processes did not persist. The launchd path did persist and passed health
  checks after warmup.
- `curl localhost:8888` was inconsistent from the sandboxed shell while direct
  elevated `curl 127.0.0.1:8888` and Docker/nginx logs confirmed Wizard HQ HTTP
  200 responses. Use `127.0.0.1` for evidence commands.
- While posting a GitHub issue comment, shell backticks in the `gh issue comment
  --body "..."` text were interpreted as command substitution. This accidentally
  executed text intended to be quoted evidence, including an uninstall command
  and smoke-test fragments. The stack remained running afterward, and API health
  checks passed, but this is a serious operator-safety failure pattern.

### Failure Categories

- Test design gap
- Installer flow
- Launchd/autostart
- Wizard HQ/dashboard
- Low-memory/8GB behavior
- No-surprise-model-download
- Release tooling/operator environment

### Root Cause Or Current Hypothesis

- The live smoke assumed a configured LiteLLM alias meant a generation-capable
  model was installed. That assumption is false after `--purge-all` followed by
  `--skip-model-pulls`.
- Background process lifecycle from this Codex-managed shell is not equivalent
  to product persistence. launchd is the product-supported persistence path and
  passed after documented warmup.
- GitHub CLI comments that include shell-looking evidence must be passed through
  `--body-file`, not inline `--body`, because backticks and command
  substitutions are evaluated by the local shell before `gh` receives the text.

### Fix Applied

- Updated `tests/core-live-smoke.sh` so LiteLLM chat completion is skipped with a
  warning when no Ollama generation-capable model is installed.
- Kept LiteLLM readiness and model alias checks as hard checks.
- Switched remaining GitHub issue comments to body-file usage for multiline
  evidence containing commands.

### Retest Result

- `bash tests/core-live-smoke.sh` now passes with warnings on a model-free
  low/core install.
- Doctor passes with 51 checks, 4 warnings, 0 failures after launchd warmup.
- Wizard HQ installed HTML contains the new tab shell.

### Regression Test Added

- `tests/core-live-smoke.sh` now covers the no-generation-model degraded path.
- No code regression test added for the `gh issue comment --body` quoting
  mistake because it was an operator workflow failure, not repo runtime code.
  The evidence note records the rule: use `--body-file` for command-heavy
  comments.

### Follow-Up Issues Created Or Recommended

- Recommended: create a focused issue to make non-interactive install optionally
  enable launchd with an explicit flag, or improve postinstall/next-step copy so
  users know Wizard HQ status panels are degraded until launchd/status APIs are
  started.
- Recommended: create a focused issue for browser screenshot evidence of Wizard
  HQ after clean install.

### Lesson Learned

A clean install with `--skip-model-pulls` must not be treated as chat-ready.
It is stack-ready and dashboard-ready, but generation is intentionally degraded
until the user explicitly pulls a model.

### What Not To Repeat Next Time

Do not fail a no-surprise-download install because a model was not downloaded.
Tests must distinguish service readiness from generation readiness.

Do not place command examples inside inline `gh issue comment --body "..."`.
Use a temporary body file so backticks cannot execute locally.

### Local Trusted Beta Impact

Improved. Core install path is validated on the 8GB Mac with model pulls
disabled, and the live smoke now matches the product's conservative model policy.

### Public Beta Impact

Improved but still incomplete. Public Beta still needs browser screenshot
evidence, clearer status-API persistence onboarding, model-add guidance, and
known-warning documentation.

## Control Plane Strategy Alignment Pass

### Date/Time

2026-05-08 00:58:28 EDT

### Branch

`main`

### Starting Commit SHA

`eecc8be482dc1384eafc2858cf3d5e8ab7c5a38f`

### Target Issues

- #37 public release onboarding and packaging hardening
- #95 product push audit and release readiness evidence
- #101 Wizard HQ Merlin-native front door and Brains tab UX
- #102 Wizard HQ status API first-run persistence

### Scope

Validate the proposed Merlin AI control-plane / AI governance product direction
against current repo truth, then align docs and tests so future roadmap language
does not overclaim current product behavior.

### Files Changed

- `docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/product/PRODUCT_GUIDE.md`
- `tests/control-plane-strategy-smoke.sh`
- `.github/workflows/ci.yml`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `.github/workflows/ci.yml`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`

These were touched for governance alignment and static CI coverage only. No
installer, runtime, policy, memory, status API, task API, or dashboard execution
behavior changed.

### Commands Run

| Command | Result |
| --- | --- |
| `bash tests/control-plane-strategy-smoke.sh` before test fix | FAIL; brittle wording assertion did not match the strategy doc's actual anti-overclaim sentence. |
| `bash tests/control-plane-strategy-smoke.sh` after test fix | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `bash tests/master-prompt-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Tests Skipped And Why

Live service tests are not required for this docs/governance pass. The live
clean-install evidence above remains the current runtime evidence for today.

### Failures Found

`tests/control-plane-strategy-smoke.sh` initially failed because it expected the
phrase `not yet a completed AI firewall...` while the doc says `not yet be
described as a completed AI firewall...`.

### Failure Category

Test design gap

### Root Cause Or Current Hypothesis

The validated product direction is aligned with Merlin's foundation, but the
roadmap needed a clearer current/future boundary. The main risk was language
drift: describing Merlin as a completed AI firewall, IDS, IPS, DLP, or
enterprise governance product before those controls exist.

The smoke-test failure root cause was brittle exact text matching.

### Fix Applied

- Added a control-plane strategy doc with current-state and future-state
  architecture diagrams.
- Updated canonical active queue to put #102 and #101 before broader public
  polish, with #64 explicitly deferred until product polish is otherwise ready.
- Updated the implementation roadmap with v3.1 through v3.7 control-plane
  milestones and a v4.x native-runtime boundary.
- Added a static smoke test to enforce the current/future product-claim
  boundary in CI.
- Tightened the smoke assertion to match the doc's actual anti-overclaim
  sentence.

### Retest Result

`bash tests/control-plane-strategy-smoke.sh` passed after the assertion fix.
`bash tests/beta-readiness-evidence-smoke.sh`, `bash tests/master-prompt-smoke.sh`,
and `git diff --check` also passed.

### Regression Test Added

`tests/control-plane-strategy-smoke.sh` verifies the strategy doc exists,
contains the v3.1-v4.x ladder, links from canonical state and roadmap, and
contains explicit anti-overclaim language.

### Follow-Up Issues Created Or Recommended

Created GitHub milestones and parent roadmap issues:

| Milestone | Parent Issue |
| --- | --- |
| `v3.1 — Wizard HQ Product Shell` | #106 |
| `v3.2 — AI Asset Inventory + Identity Graph` | #105 |
| `v3.3 — Access Control + Reviews` | #103 |
| `v3.4 — Monitoring IDS Signals + Drift` | #104 |
| `v3.5 — DLP + Prevention Gates` | #107 |
| `v3.6 — Governance Reporting + Evidence` | #112 |
| `v3.7 — Local Fallback + DR` | #108 |
| `v4.x — MerlinFlow Native Runtime` | #111 |

During issue creation, GitHub returned transient GraphQL errors for two
parallel `gh issue create` calls. I checked existing issues before retrying and
only retried the missing v3.6 and v4.x parent issues. No duplicate issues were
created.

### Lesson Learned

The control-plane direction is good, but it must be structured as future
milestones. The installed system is currently a strong local-first foundation
and Wizard HQ shell, not a completed governance/security suite.

### What Not To Repeat Next Time

Do not let market or investor language rewrite current-state docs as if future
DLP/IDS/RBAC features already exist. Current-state docs must always match code
and evidence.

### Local Trusted Beta Impact

Improved. The next build path is clearer: stabilize first-run Wizard HQ and
Brains before adding deeper governance layers.

### Public Beta Impact

Improved but still incomplete. Public Beta still needs product-shell visual
validation, status API persistence clarity, model-add UX, and installer retest
evidence after final onboarding changes.

## Closed Milestone Drift Review

### Date/Time

2026-05-08

### Branch

`main`

### Starting Commit SHA

`dd98b68bfb91df38b43d122e3e7b348820904afa`

### Target Issues

- v1.0 through v2.2 closed milestone review
- v2.0 open stale issue cleanup
- v3.0 release readiness alignment

### Scope

Reviewed closed milestone state and open carryover issues to decide whether any
completed milestone needs reopening, tweaking, or new follow-up issues.

### Files Changed

- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `docs/CANONICAL_PROJECT_STATE.md`

No installer, runtime, policy, dashboard, memory, or API behavior changed.

### Commands Run

| Command | Result |
| --- | --- |
| `gh api repos/TheYfactora12/home-ai-elite/milestones --jq ...` | PASS; listed open milestones. |
| `gh issue list --state closed --limit 80 --json number,title,milestone,labels,closedAt --jq ...` | PASS; reviewed recently closed milestone issues. |
| `gh api 'repos/TheYfactora12/home-ai-elite/milestones?state=all&per_page=100' --jq ...` | PASS; confirmed closed and open milestone counts. |
| `gh issue list --state open --milestone 'v2.0 — Merlin Staff Core' --limit 20 --json number,title,labels --jq ...` | PASS; identified stale v2.0 carryover issues. |
| `gh issue view 27/29/31/32/38/40 --json ...` | PASS after retry; first network attempt failed, later issue views succeeded. |
| `rg -n "memory delete\|audit review\|no automatic learning\|model router visibility\|low-memory\|fallback" ...` | PASS; verified which v2.0 issues are already covered by code and which remain real gaps. |
| `gh issue comment 27/29/38/40 --body-file ...` | PASS; posted evidence comments using safe body-file pattern. |
| `gh issue close 27/29/38/40 --reason completed` | PASS; closed stale/satisfied v2.0 issues. |

### Tests Skipped And Why

No runtime tests were required for this governance-only pass. No runtime files
changed. The latest pushed commit had green CI before this review.

### Failures Found

- `gh issue view` initially failed with `error connecting to api.github.com`.
- `gh issue close --comment-file` failed because this installed GitHub CLI does
  not support that flag.

### Failure Category

- Release tooling/operator environment
- Documentation/governance drift

### Root Cause Or Current Hypothesis

- GitHub connectivity is intermittent on the current network.
- This GitHub CLI version supports `gh issue comment --body-file` but not
  `gh issue close --comment-file`.

### Fix Applied

- Retried GitHub issue views after the network failure.
- Used the safe two-step pattern: `gh issue comment --body-file ...`, then
  `gh issue close --reason completed`.
- Updated canonical state to show that v2.0 now only has memory approval and
  memory review/delete follow-up work.

### Retest Result

- `gh issue view 27`, `29`, `38`, and `40` returned `CLOSED`.
- Milestone review confirmed v3.0 remains the active product-readiness track.

### Regression Test Added

No automated test added. This was GitHub issue hygiene, not repo runtime logic.
The lesson is captured here as an operator runbook pattern.

### Follow-Up Issues Created Or Recommended

No new issues were required from this pass.

Keep these open:

- #31: explicit user-facing memory approval flow remains product-relevant.
- #32: memory review/delete remains product-relevant.
- #101/#102: Wizard HQ and first-run status API remain the next active product
  work.

Closed as stale or satisfied:

- #27: superseded by canonical state and current roadmap.
- #29: router visibility and low-memory fallback are implemented and tested;
  product model/provider polish belongs to #101/#106.
- #38: session alignment protocol is covered by canonical state and master
  prompt smoke.
- #40: stale v1/v2 queue superseded by v3.0 and v3.1-v3.7 milestones.

### Lesson Learned

Closed milestone review should distinguish completed acceptance criteria from
product-follow-up work. Reopening old issues is usually worse than creating or
keeping focused follow-up issues because old bodies often reference stale docs
and stale ordering.

### What Not To Repeat Next Time

Do not leave old pinned queue issues open after canonical state and GitHub
milestones move forward. They become a drift source for future Codex sessions.

Do not use `gh issue close --comment-file`; this CLI does not support it. Use
`gh issue comment --body-file` followed by `gh issue close --reason ...`.

### Local Trusted Beta Impact

Improved. The active backlog is cleaner and now points back to the real next
product blockers: #102, #101, #31, and #32.

### Public Beta Impact

Improved. Stale v1/v2 queue issues no longer compete with the v3.0/v3.1 product
track, but Public Beta remains blocked by Wizard HQ polish, full evidence,
model-add UX, memory review/delete, and final packaging trust decisions.

## Issue #102 First-Run Merlin API Readiness Copy

### Date/Time

2026-05-08 06:58:46 EDT

### Branch

`main`

### Starting Commit SHA

`2294a33a985b6b236c701734d709f2d75b4b4d55`

### Target Issues

- #102: clarify Wizard HQ status API first-run persistence
- #101: Wizard HQ Merlin-native front door and Brains tab UX
- #95: product push audit / release readiness evidence

### Scope

Clarify the first-run state after a non-interactive clean install: Wizard HQ is
available immediately, but Merlin Status API and Task API panels can remain
warming/degraded until the user starts APIs manually or installs launchd agents.

This pass changed copy and static tests only. It did not change launchd behavior,
API behavior, installer service startup order, cloud defaults, model downloads,
or dashboard execution boundaries.

### Files Changed

- `install.sh`
- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/installer-merlin-api-policy-smoke.sh`
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `install.sh`

Reason: #102 specifically concerns install output and first-run next-step copy.
Only user-facing copy was changed; no install logic, profile selection,
non-interactive behavior, launchd behavior, model-pull defaults, or cloud
defaults changed.

### Commands Run

| Command | Result |
| --- | --- |
| `bash -n install.sh` | PASS |
| `bash tests/installer-merlin-api-policy-smoke.sh` | PASS |
| `bash tests/dashboard-first-run-smoke.sh` | PASS |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS |
| `git diff --check` | PASS |

### Tests Skipped And Why

- Full clean install retest was not rerun for this copy-only pass. The earlier
  2026-05-08 clean install evidence already verified the exact behavior this
  copy now explains: non-interactive install leaves 8765/8766 unavailable until
  launchd/manual API startup, then `bash launchd/install-launchd.sh`, warmup,
  and doctor validation make both APIs reachable.
- Live browser screenshot capture remains part of #101/#95 evidence.

### Failures Found

None in this pass.

### Failure Category

None.

### Root Cause Or Current Hypothesis

The original runtime behavior was intentional but the first-run copy was not
specific enough for a trusted beta user. Wizard HQ and install output needed to
name the supported next commands and the 35-40 second launchd warmup window.

### Fix Applied

- Installer output now says non-interactive installs skip direct API start and
  launchd setup, and that launchd starts Status API on :8765 after roughly 35s
  and Task API on :8766 after roughly 40s.
- Installer final command list now includes `bash launchd/install-launchd.sh`
  and `sleep 35 && bash scripts/doctor.sh`.
- Wizard HQ now shows persistent API and manual Task API commands in Safe Next
  Commands.
- Route panel degraded/warming copy now names `bash scripts/merlin-task-api.sh
  start` and `bash launchd/install-launchd.sh`.
- Evidence pack now includes the launchd warmup and first-run API readiness
  expectations.

### Retest Result

Focused static smokes passed.

### Regression Test Added

Updated existing static smokes:

- `tests/installer-merlin-api-policy-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`

These now assert the exact launchd/manual API commands and warmup language.

### Follow-Up Issues Created Or Recommended

No new issue required. #101 remains open for browser visual validation and
product-shell polish.

### Lesson Learned

A correct degraded state still feels broken if the UI does not explain the exact
next command and expected warmup timing. First-run copy is part of readiness,
not a cosmetic detail.

### What Not To Repeat Next Time

Do not say "status panels degraded" without naming the command that resolves the
state and the time window before it should be judged failed.

### Local Trusted Beta Impact

Improved. The non-interactive clean install path is clearer for trusted beta
users without changing protected installer behavior.

### Public Beta Impact

Improved but incomplete. Public Beta still requires browser screenshot evidence,
model-add UX, memory review/delete, final onboarding pass, and later packaging
trust decisions.

## Issue #101 Browser Evidence Attempt

### Date/Time

2026-05-08 07:03:57 EDT

### Branch

`main`

### Starting Commit SHA

`4ef6245a98031a47206071fcba036d09474942b7`

### Target Issues

- #101: Wizard HQ Merlin-native front door and Brains tab UX
- #95: product push audit / release readiness evidence

### Scope

Attempt browser/screenshot validation for the Wizard HQ product shell and record
what evidence could be collected from this session.

### Files Changed

- `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-http-snapshot.html`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

| Command | Result |
| --- | --- |
| `bash scripts/status.sh` | PASS; reported Wizard HQ, Open WebUI, LiteLLM, Qdrant, and Ollama running. |
| `curl -v --max-time 5 http://127.0.0.1:8888/` with host-level permission | PASS; HTTP 200 from nginx, returned Wizard HQ HTML. |
| `docker compose ps dashboard` | PASS; `swarm-dashboard` running on `127.0.0.1:8888->80/tcp`. |
| `docker logs --tail 30 swarm-dashboard` | FAIL; Docker socket permission denied from this shell. |
| `osascript ... open location "http://127.0.0.1:8888"` | PASS; Safari open command completed. |
| `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-chat.png` | FAIL; `could not create image from display`. |
| `curl -fsS --max-time 5 http://127.0.0.1:8888/ -o docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-http-snapshot.html` | PASS; saved 51K HTML snapshot as evidence artifact. |
| `rg -n "Wizard HQ\|Merlin AI\|data-tab-target=\"chat\"\|data-tab-target=\"brains\"\|Open WebUI Bridge\|cloud disabled by default\|bash launchd/install-launchd.sh" docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-http-snapshot.html` | PASS; snapshot contains Merlin product shell, tabs, Open WebUI bridge framing, cloud-disabled copy, and launchd first-run command. |

### Tests Skipped And Why

No new runtime tests were added in this attempt. #101 remains open because true
browser screenshot evidence could not be captured from this shell.

### Failures Found

- Sandbox `curl` to `127.0.0.1:8888` failed even though host-level curl and
  `scripts/status.sh` verified the dashboard was running.
- `docker logs` failed due Docker socket permission from this shell.
- `screencapture` failed with `could not create image from display`.

### Failure Category

- Wizard HQ/dashboard
- Test design gap
- Release tooling/operator environment

### Root Cause Or Current Hypothesis

- Localhost access can differ between the sandboxed shell and host-level command
  path in this environment.
- Docker socket access from this shell is restricted.
- macOS screenshot capture likely lacks display/session or Screen Recording
  permission in this Codex environment.

### Fix Applied

No product fix applied. Captured an HTML snapshot as partial evidence and kept
#101 open for manual visual screenshot capture.

### Retest Result

Host-level HTTP evidence passed and the HTML snapshot contains the expected
Merlin-native product shell markers.

### Regression Test Added

No regression test added. Existing static tests already cover the tab shell and
unsafe control boundaries. The missing item is manual visual evidence, not a
code behavior gap.

### Follow-Up Issues Created Or Recommended

No new issue required. Keep #101 open until manual browser screenshots are
captured or a reliable screenshot tool is added to the evidence workflow.

### Lesson Learned

Do not treat missing screenshots as proof the dashboard is down. Verify with
host-level HTTP and container status first, then record screenshot-tool failures
separately.

### What Not To Repeat Next Time

Do not close #101 with static grep evidence alone. It needs actual browser
visual evidence or an explicit documented reason from the manual QA run.

### Local Trusted Beta Impact

Partial improvement. HTML evidence confirms the installed Wizard HQ product shell
is being served, but Local Trusted Beta visual evidence still needs screenshots.

### Public Beta Impact

Still blocked on browser screenshot evidence and manual first-impression review.

## Issue #101 Chat Bridge + Settings Product Hub Polish

### Date/Time

2026-05-08 07:19:59 EDT

### Branch

`main`

### Starting Commit SHA

`15cd9831ca8f4c2f7a9cb590bec4e0bab1e79d80`

### Target Issues

- #101: Wizard HQ Merlin-native front door and Brains tab UX
- #106: Wizard HQ Product Shell parent
- #37/#95: release onboarding and product audit evidence

### Scope

Tighten Wizard HQ as the Merlin product hub after visual review showed users can
still experience chat as "Llama/Open WebUI" instead of Merlin. This slice keeps
runtime behavior safe: the dashboard remains read-only, the chat button opens
the current local chat bridge, and Settings explains future controls without
adding browser-side execution, API-key fields, model downloads, memory writes,
or approval buttons.

### Files Changed

- `dashboard/index.html`
- `README.md`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/product/DASHBOARD_UI_SPEC.md`
- `docs/product/GTM_STRATEGY.md`
- `docs/product/PRODUCT_GUIDE.md`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-top-shell.png`
- `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-manual.png`

### Protected Files Touched

None. Installer, uninstall, package scripts, policy engine, router, memory
manager, task endpoint, status API, and Docker defaults were not changed.

### Commands Run

| Command | Result |
| --- | --- |
| `git status --short --branch` | PASS; branch `main`, dashboard edit plus untracked screenshots identified before continuing. |
| `rg -n "Open Merlin\|open-chat\|Provider Connectors\|Model Library\|Memory Controls\|Privacy & Sovereignty\|Startup & APIs\|Backup & Recovery\|Open Merlin Local Chat\|Open Merlin Chat Workspace" dashboard/index.html tests docs/product docs/release/evidence` | PASS; found stale test expectations for the old chat label. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS after test update; verifies tab shell, chat bridge boundary, richer Settings cards, no unsafe controls. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS after test update; verifies first-run chat bridge copy and read-only setup boundary. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS after test update; verifies Wizard HQ status markers and chat workspace link. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS; readiness surface remains honest and read-only. |
| `bash tests/beta-readiness-evidence-smoke.sh` | PASS; trusted local beta evidence pack remains complete. |
| `bash tests/master-prompt-smoke.sh` | PASS; master prompt/context remain current. |
| `rg -n "Wizard AI\|Primary chat interface\|Open WebUI.*Primary\|Chat UI \\(your ChatGPT\|Wizard HQ service dashboard\|Open WebUI → create admin account\|Buy \\$99\|Developer ID.*This Week\|Windows is v3\\.1" README.md docs/product docs/CANONICAL_PROJECT_STATE.md` | PASS after doc updates; no stale identity or premature Developer ID priority language remains in current product docs. |
| `bash -n install.sh` | PASS; installer syntax unchanged and valid. |
| `bash install.sh --help` | PASS; install help still renders. |
| `bash tests/installer-branding-smoke.sh` | PASS; #94 branding surface remains protected. |
| `bash tests/pkg-readiness-smoke.sh` | PASS; package readiness checks remain valid. |
| `bash tests/uninstall-smoke.sh` | PASS; uninstaller remains guarded and testable. |
| `gh run watch 25553630396 --exit-status` | FAIL; CI static smoke job failed because `tests/control-plane-strategy-smoke.sh` still required closed issue #102 in the active canonical queue. |
| `gh run view 25553630396 --job 75007196708 --log` | PASS; failure log captured and root cause identified. |
| `bash tests/control-plane-strategy-smoke.sh` | PASS after updating the smoke to require #101, #113, and #114 instead of closed #102. |
| `git diff --check` | PASS; no whitespace errors. |

### Tests Skipped And Why

No live service tests were required for this slice because runtime service
behavior did not change. Installer/package tests are still required before
Local Trusted Beta signoff, but not for this read-only dashboard/doc polish
commit.

### Failures Found

- Static dashboard tests still expected the old `Open Merlin Local Chat` label
  after the UI was changed to `Open Merlin Chat Workspace`.
- Product docs still had stale `Wizard AI` naming and Open WebUI-first wording.
- Two screenshot artifacts captured the terminal/Open WebUI state instead of
  clean Wizard HQ evidence and were removed before commit.
- CI failed because `tests/control-plane-strategy-smoke.sh` encoded stale
  canonical queue expectations for #102 after that issue was closed.

### Failure Category

- Wizard HQ/dashboard
- Documentation mismatch
- Test design gap
- UX/readiness confusion
- Roadmap/governance drift

### Root Cause Or Current Hypothesis

The implementation had moved Wizard HQ toward a Merlin product shell, but tests
and current docs still reflected the older "dashboard plus Open WebUI" mental
model. That mismatch made it easier for a first-time user to believe Llama/Open
WebUI was the product and Merlin was just a status panel.

The CI failure had the same shape: the canonical queue was correctly advanced
past #102, but the control-plane strategy smoke test still treated #102 as
active.

### Fix Applied

- Added a stable `open-chat-workspace` link and clearer copy that Open WebUI is
  today's local chat bridge while Merlin owns routing, policy, memory, status,
  and audit around it.
- Expanded Settings into six read-only cards: Provider Connectors, Model
  Library, Memory Controls, Privacy & Sovereignty, Startup & APIs, and Backup &
  Recovery.
- Updated dashboard static smokes to verify the richer hub UX and safe CLI
  handoffs.
- Updated current product docs and README so Wizard HQ is the product hub and
  Open WebUI is the bridge, not the product identity.
- Updated the GTM doc to use Merlin AI naming and to keep Developer ID deferred
  until the product surface and clean install evidence are complete.
- Updated `tests/control-plane-strategy-smoke.sh` so it checks the current
  active Wizard HQ queue: #101, #113, and #114.

### Retest Result

Dashboard, docs, and control-plane strategy smokes passed after the updates
listed above.

### Regression Tests Added

- `tests/dashboard-first-run-smoke.sh` now checks the stable chat workspace link
  and honest Merlin/Open WebUI boundary copy.
- `tests/dashboard-tabs-smoke.sh` now checks the richer Settings surfaces, safe
  CLI handoffs, memory issue pointers, cloud escalation state, and no unsafe
  browser actions.
- `tests/dashboard-merlin-status-smoke.sh` now checks the updated chat workspace
  label and link id.
- `tests/control-plane-strategy-smoke.sh` now catches the current #101/#113/#114
  Wizard HQ queue instead of requiring the closed #102 issue.

### Follow-Up Issues Created Or Recommended

- Created #113: native Merlin Chat inside Wizard HQ, routed through `POST /task`
  on port 8766 with visible route/staff/model/approval metadata and designed
  approval UX.
- Created #114: policy-gated Settings backend for provider connectors, model
  library, memory review/delete, backup/restore, and API persistence.

### Lesson Learned

Visual evidence is not just cosmetic. Seeing the running chat page branded as
Llama/Open WebUI exposed a product identity gap that static architecture docs
did not make obvious enough.

### What Not To Repeat Next Time

Do not describe Open WebUI as the primary product experience in current docs.
It is a bridge behind Merlin until native Wizard HQ chat exists.

### Local Trusted Beta Impact

Improved. A trusted user now has clearer first-run guidance: open Wizard HQ
first, understand Merlin as the hub, use Open WebUI as the current local chat
bridge, and treat Settings as locked until policy-gated flows are built.

### Public Beta Impact

Improved but still blocked. Public Beta still needs native Wizard HQ chat or an
intentional bridge/onboarding design, complete memory review/delete UX,
installer retest evidence, and final release packaging guidance.

## Issue #113 Native Merlin Chat Slice

### Date/Time

2026-05-08 07:56:43 EDT

### Branch

`main`

### Starting Commit SHA

`86cdd395d4fae7f91d46b3631c568f71ff138e0b`

### Target Issues

- #113: Native Merlin Chat inside Wizard HQ
- #106: Wizard HQ Product Shell parent
- #95: product push audit / release readiness evidence

### Scope

Add the first native Merlin Chat surface inside Wizard HQ. The browser may now
submit exactly one policy-gated request path: `POST http://localhost:8766/task`.
The browser still must not call Ollama, LiteLLM, cloud APIs, approval endpoints,
shell/file operations, model downloads, or memory writes directly.

### Files Changed

- `dashboard/index.html`
- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/product/DASHBOARD_UI_SPEC.md`
- `docs/product/MERLIN_BRAND_UX_SPEC.md`
- `.github/workflows/ci.yml`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/dashboard-readiness-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `.github/workflows/ci.yml` was touched only to add the new static dashboard
  native-chat smoke to CI.

Runtime protected files were not changed: installer, package scripts, router,
policy engine, memory manager, task endpoint, status API, Docker defaults, and
launchd behavior remain untouched.

### Commands Run

| Command | Result |
| --- | --- |
| `gh issue view 113 --json number,title,state,body,labels,milestone` | PASS; confirmed #113 scope and acceptance criteria. |
| `sed -n '1,260p' merlin/task_endpoint.py` | PASS; verified existing `/task` endpoint, response shape, approval-required 403, degraded fallback, and route metadata. |
| `rg -n "app\\.|@app|/task|status/routes|TaskRequest|TaskResponse|POST|class .*Request|class .*Response" merlin/task_endpoint.py merlin/router.py dashboard/index.html tests` | PASS; confirmed the backend contract and existing dashboard POST bans that needed updating. |
| `bash tests/dashboard-native-chat-smoke.sh` | PASS; verifies native Merlin Chat routes through Task API `/task`, renders route/staff/model metadata, and avoids direct model/backend action calls. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS; tab shell remains Merlin-native with the narrowed safe POST boundary. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS; first-run product clarity remains safe. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS; status panel contract remains intact. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS; readiness surface remains honest. |
| `bash tests/dashboard-security-center-smoke.sh` | PASS; no approval controls exposed. |
| `bash tests/control-plane-strategy-smoke.sh` | PASS; strategy/canonical queue still scoped to current/future boundaries. |
| `bash tests/master-prompt-smoke.sh` | PASS; master prompt/context remain current. |
| `bash -n install.sh` | PASS; installer syntax unchanged and valid. |
| `bash install.sh --help` | PASS; install help still renders. |
| `bash tests/installer-branding-smoke.sh` | PASS; #94 installer branding remains protected. |
| `bash tests/pkg-readiness-smoke.sh` | PASS; package readiness checks remain valid. |
| `bash tests/uninstall-smoke.sh` | PASS; uninstaller remains guarded and testable. |
| `bash tests/release-readiness-readme-smoke.sh` | PASS; README release-readiness positioning remains conservative. |
| Full CI static smoke sequence from `.github/workflows/ci.yml` | PASS overall; surfaced one local sandbox bind failure in `tests/merlin-status-api-smoke.sh`, documented below. |
| `bash tests/merlin-status-api-smoke.sh` with host-level permission | PASS; confirmed the prior bind failure was environment/sandbox-specific, not a product regression. |
| `curl -sS --max-time 5 http://127.0.0.1:8766/status/routes` | PASS; Task API route status is available. |
| `curl -sS --max-time 5 http://127.0.0.1:8766/status/approvals` | PASS; Task API approval status is available and all 15 gates fail closed. |
| `curl -sS --max-time 5 http://127.0.0.1:8765/healthz` | PASS; read-only status API health endpoint is available. |
| `curl -sS --max-time 25 -X POST http://127.0.0.1:8766/task -H 'Content-Type: application/json' -d '{"input":"explain what Merlin is in one short paragraph"}'` | DEGRADED; Task API accepted the request and returned a safe degraded response: `Merlin is starting up. Try again in 30 seconds.` |
| `curl -sS --max-time 5 http://127.0.0.1:4000/health/readiness` | PASS; LiteLLM is healthy. |
| `curl -sS --max-time 5 http://127.0.0.1:11434/api/tags` | PASS; Ollama is healthy but only `nomic-embed-text:latest` is installed. |
| `bash scripts/status.sh` | PASS; Dashboard, Open WebUI, LiteLLM, Qdrant, and Ollama running; Ollama model list confirms only the embedding model is loaded. |
| `git diff --check` | PASS; no whitespace errors. |

### Tests Skipped And Why

Live browser/manual chat test is still pending. This implementation is static
and API-contract aligned, but it still needs a running Task API + LiteLLM +
local model validation pass before #113 can be closed.

### Failures Found

- Full static smoke sequence printed a `PermissionError: [Errno 1] Operation
  not permitted` while `tests/merlin-status-api-smoke.sh` tried to bind its
  local test server from the sandbox.
- Live `/task` call returned a degraded response instead of model content
  because no chat-capable Ollama model is currently installed.
- A boundary change was identified before testing: older dashboard smokes
  banned all POSTs. Those tests were updated to allow exactly one safe POST to
  Merlin Task API `/task` and continue blocking direct model backend calls.

### Failure Category

- Test design gap
- Wizard HQ/dashboard
- Release tooling/operator environment
- LiteLLM/model router runtime readiness

### Root Cause Or Current Hypothesis

The dashboard had correctly been read-only until #113. Native chat changes the
contract from "no browser POSTs" to "exactly one policy-gated browser POST to
Merlin Task API." The tests needed to encode that more precise boundary.

The status API bind failure was environment-specific: rerunning
`tests/merlin-status-api-smoke.sh` with host-level permission passed.

The live `/task` degraded result means the new Wizard HQ chat panel is wired to
the correct backend boundary, but the end-to-end response path still needs a
chat-capable local model before #113 can be closed.

### Fix Applied

- Added a premium native Merlin Chat panel inside Wizard HQ.
- Added a single submit path to `POST ${TASK_API}/task`.
- Rendered response, degraded state, route id, staff mode, selected model alias,
  and approval gates.
- Added approval-required handling for 403 responses without approving or
  executing anything in the browser.
- Updated product docs to reflect the new boundary: status is read-only, native
  chat is policy-gated through `/task`.
- Added `tests/dashboard-native-chat-smoke.sh` and wired it into CI.
- Reran the status API smoke with host-level permission to prove the bind error
  was not a product regression.
- Kept #113 open because live `/task` returned degraded rather than a routed
  model response.
- Did not auto-download a model. This preserves the no-surprise-model-download
  rule.

### Retest Result

Focused static dashboard, security, governance, docs, and whitespace checks
passed locally. The full static smoke sequence completed, and the one sandbox
bind failure was retested successfully with host-level permission.

Live Task API validation reached `/task` but returned degraded because only the
embedding model is installed. This is safe behavior, not completion evidence.

### Regression Tests Added

- `tests/dashboard-native-chat-smoke.sh`
- Existing dashboard smokes now require exactly one Task API `/task` POST and
  reject direct model backend calls such as Ollama generation or LiteLLM chat
  completion paths.

### Follow-Up Issues Created Or Recommended

No new issue required yet. Keep #113 open until a live browser/API validation
proves the native chat panel returns non-degraded model content against running
core services with a chat-capable local model installed.

### Lesson Learned

"Read-only dashboard" was too broad once native chat became the main product
surface. The stronger rule is more specific: browser status panels are read-only
and chat may only go through Merlin's policy-gated Task API.

### What Not To Repeat Next Time

Do not loosen browser security by allowing generic POSTs. Any future browser
action must name its exact endpoint, backend gate, response shape, and tests.

### Local Trusted Beta Impact

Improved. Wizard HQ now starts becoming the actual user workspace instead of a
status shell plus external chat link, but the live model response path still
needs validation.

### Public Beta Impact

Improved but still not complete. Public Beta still requires live browser
validation, memory review/delete UX, policy-gated Settings, installer retest
evidence, and final onboarding/release docs.

## Issue #113 Live Merlin Chat Validation Update

### Date/Time

2026-05-08 08:15 EDT

### Branch

`main`

### Starting Commit SHA

`0dc09dc8a01a33ae6542114c0304d31e255ffe09`

### Target Issues

- #113: Native Merlin Chat inside Wizard HQ

### Scope

Validate the previously blocked live Merlin Chat path by installing the
configured local default chat model and retesting Merlin Task API routing.

### Files Changed

- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

| Command | Result |
| --- | --- |
| `curl -sS --max-time 5 http://127.0.0.1:11434/api/tags` | PASS before model install; confirmed only `nomic-embed-text:latest` was installed. |
| `sed -n '1,240p' configs/merlin/routes.yaml` | PASS; confirmed general route uses `qwen7b` and low-memory fallback alias is `mistral`. |
| `sed -n '1,120p' configs/litellm/config.yaml` | PASS; confirmed `qwen7b` and `mistral` both route to Ollama `qwen2.5:7b`. |
| `sed -n '1,120p' configs/merlin/models.yaml` | PASS; confirmed `qwen2.5:7b` is the enabled local default chat model and model downloads require approval. |
| `bash scripts/add-model.sh qwen2.5:7b` | PASS; intentionally downloaded the configured local chat model, 4.7 GB. |
| `curl -sS --max-time 5 http://127.0.0.1:11434/api/tags` | PASS after model install; confirmed `qwen2.5:7b` and `nomic-embed-text:latest` are present. |
| `curl -sS --max-time 5 http://127.0.0.1:4000/health/readiness` | PASS; LiteLLM healthy. |
| `curl -sS --max-time 5 http://127.0.0.1:8765/healthz` | PASS; status API read-only health endpoint healthy. |
| `curl -sS --max-time 5 http://127.0.0.1:8766/status/routes` | PASS; Task API route metadata available. |
| `curl -sS --max-time 90 -X POST http://127.0.0.1:8766/task -H 'Content-Type: application/json' -d '{"input":"explain what Merlin is in one short paragraph"}'` | PASS; returned non-degraded Merlin response with `approved: true`, route `general`, selected model alias `mistral`, and `audit_written: true`. |
| `bash tests/dashboard-native-chat-smoke.sh` | PASS; native chat remains policy-gated through Task API. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS; tab shell remains Merlin-native with the narrowed Task API POST boundary. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS; first-run clarity remains safe. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS; dashboard status contract remains intact. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS; readiness surface remains honest. |
| `bash scripts/status.sh` | PASS; Dashboard, Open WebUI, LiteLLM, Qdrant, and Ollama running; `qwen2.5:7b` listed in Ollama models. |
| `gh issue create ...` for model-readiness UX follow-up | FAIL first attempt; shell interpreted Markdown backticks in the body before `gh` ran, and sandboxed network access blocked GitHub. |
| `gh issue create ...` retried with safer body quoting and escalated network permission | PASS; created #115. |
| `open -a "Google Chrome" http://localhost:8888` | FAIL; Chrome application name not found on this machine. |
| `open -a Safari http://localhost:8888` | PASS; Wizard HQ opened in Safari for browser-level manual validation. |

### Tests Skipped And Why

Manual browser typing/screenshot capture is still not recorded in this update.
The backend path that Wizard HQ calls is live and non-degraded, and static
dashboard tests cover the browser safety boundary. A final browser screenshot
can be captured before closing #113 if needed for release evidence.

### Failures Found

The prior live `/task` degraded response was caused by missing local chat model
state. After `qwen2.5:7b` was installed intentionally, `/task` returned
non-degraded model output.

The first `gh issue create` attempt failed because the body used Markdown
backticks inside a double-quoted shell argument. `zsh` treated those as command
substitution and attempted to execute model names and endpoint text. The command
was retried with safer quoting and no Markdown backticks in the shell argument.

The first browser-open attempt failed because Google Chrome is not installed or
not registered under that application name on this machine. Safari opened Wizard
HQ successfully.

### Failure Category

- LiteLLM/model router runtime readiness
- Wizard HQ/dashboard live validation
- No-surprise-model-download release safety
- Test design gap
- Wizard HQ/dashboard browser validation

### Root Cause Or Current Hypothesis

The stack was running, but Ollama only had an embedding model. The configured
Merlin/LiteLLM general chat aliases resolve to `qwen2.5:7b`, so the router could
select a valid alias while the backend had no corresponding chat-capable model
loaded.

### Fix Applied

Installed `qwen2.5:7b` via `bash scripts/add-model.sh qwen2.5:7b` after
explicitly verifying it is the configured local default chat model. No installer
defaults were changed and no automatic model download behavior was added.

### Retest Result

PASS. Merlin Task API returned a non-degraded response:

- `approved: true`
- `degraded: false`
- `route.route_id: general`
- `route.selected_model_alias: mistral`
- `route.audit_written: true`

### Regression Tests Added

No new regression test was needed in this update because
`tests/dashboard-native-chat-smoke.sh` already enforces the browser boundary.
This was a runtime environment/model-availability validation, not a code defect.

### Follow-Up Issues Created Or Recommended

Recommend a focused follow-up for v3.1 Brains/System UX if not already tracked:
Wizard HQ should make the missing-chat-model state obvious and offer a safe,
approval-gated next step instead of leaving the user to infer it from degraded
Task API output.

Created #115: Wizard HQ model readiness empty state and safe install guidance.

### Lesson Learned

Service health is not enough. Merlin Chat readiness requires all three:
Task API healthy, LiteLLM healthy, and at least one configured local chat model
installed.

### What Not To Repeat Next Time

Do not treat "Ollama running" as equivalent to "Merlin can chat." Always inspect
Ollama model inventory against Merlin/LiteLLM aliases.

Do not pass Markdown backticks inside double-quoted `gh --body` shell arguments.
Use safe quoting, a body file, or remove shell-sensitive Markdown when creating
issues from the command line.

Do not assume Chrome is installed for browser evidence on this machine. Use the
available default/Safari path unless a specific browser is verified first.

### Local Trusted Beta Impact

Improved. Merlin now has a working live local chat path through the Task API on
this machine.

### Public Beta Impact

Improved, but still not complete. Public Beta still needs browser screenshot
evidence, first-run model readiness UX, memory review/delete UX, policy-gated
Settings, and clean installer retest evidence.

---

## v3.1 Wizard HQ Chat Home And Browser CORS Hardening

### Date/Time

2026-05-08 09:00 EDT

### Branch

`main`

### Starting Commit SHA

`beb2a08bd4e765dee94c7eb47febd55b93cf516d`

### Ending Commit SHA

Pending commit.

### Target Issue(s)

- #113 — Wizard HQ Product Shell / Merlin-native chat path
- #115 — Wizard HQ model readiness empty state follow-up

### Scope

Fix the live browser Task API failure and reshape the Chat tab into the primary
Merlin product home: Merlin face first, Ask Merlin directly underneath, and
engineer/status detail moved out of the visible Chat page.

### Files Changed

- `dashboard/index.html`
- `merlin/task_endpoint.py`
- `tests/test_task_endpoint.py`
- `tests/test_status_extension.py`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/dashboard-readiness-smoke.sh`

### Protected Files Touched

- `merlin/task_endpoint.py` — touched narrowly to allow Wizard HQ browser CORS
  from localhost origins and to include safe route metadata in approval-required
  responses.

### Commands Run

| Command | Result |
| --- | --- |
| `curl -i -sS --max-time 5 -X OPTIONS http://127.0.0.1:8766/task -H 'Origin: http://localhost:8888' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: Content-Type'` | PASS; Task API returns `200 OK` and `access-control-allow-origin: http://localhost:8888`. |
| `curl -i -sS --max-time 5 -X OPTIONS http://127.0.0.1:8766/task -H 'Origin: http://untrusted.example' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: Content-Type'` | PASS; Task API rejects the untrusted origin and does not return an allow-origin header. |
| `.venv-test/bin/python -m pytest tests/test_task_endpoint.py tests/test_status_extension.py -v --tb=short` | PASS; 27 tests passed. |
| `bash tests/dashboard-native-chat-smoke.sh` | PASS; native Merlin Chat still routes only through Task API `/task`. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS; tabs remain Merlin-native and safe. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS after test update; now verifies the clean Chat home product surface instead of the old first-run diagnostic panel. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS after test update; verifies product identity, safe API wiring, and hidden diagnostic hooks. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS after test update; readiness logic remains present through hidden runtime hooks and System surfaces. |
| `git diff --check` | PASS; no whitespace errors. |
| `open -a Safari http://localhost:8888` | PASS earlier in session; Safari opened Wizard HQ. |
| `osascript ... do JavaScript ... in Safari` | FAIL; Safari requires the Develop setting `Allow JavaScript from Apple Events`. |
| `osascript ... System Events click Allow ...` | FAIL; this sandbox is not allowed assistive access. |
| `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-face-chat-first-viewport.png` | PASS; captured browser evidence showing Merlin face followed by Ask Merlin on the Chat home. |

### Test Output Summary

Focused backend and dashboard regression checks passed. Browser evidence now
shows the Chat tab as a product home rather than a service dashboard.

### Tests Skipped And Why

Full installer retest was skipped because this slice changed browser UX and Task
API CORS only. A full clean install/uninstall/reinstall pass remains required
before Local Trusted Beta signoff.

### Failures Found

1. Browser chat previously showed `task api unavailable` / `Load failed` even
   while curl to `/task` worked.
2. Safari browser automation was blocked by macOS privacy settings.
3. Existing dashboard static smokes failed after the product decision to remove
   first-run/startup engineering panels from the visible Chat page.
4. First browser visual pass still placed status metrics between the Merlin face
   and Ask Merlin, which contradicted the desired first-page flow.

### Failure Category

- Wizard HQ/dashboard
- Status API 8765 / Task API 8766 boundary
- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

The browser failure was caused by missing CORS middleware on the execution-aware
Task API. The test failures were caused by stale static-smoke expectations that
treated diagnostic panels as required on the Chat page even after the product
direction changed to a cleaner Merlin-first chat surface.

### Fix Applied

- Added narrow FastAPI CORS middleware for `http://localhost:8888` and
  `http://127.0.0.1:8888` only.
- Added regression tests for allowed and rejected CORS origins.
- Included full safe route metadata in approval-required Task API responses.
- Updated Wizard HQ Chat tab to show Merlin face first and Ask Merlin directly
  underneath.
- Moved engineering/status detail out of the visible Chat surface while keeping
  hidden runtime hooks so existing live status JavaScript remains stable.
- Updated dashboard smoke tests to enforce the new product rule.

### Retest Result

PASS. Backend tests, dashboard smokes, CORS checks, and whitespace checks passed.
Browser screenshot evidence captured the new Chat home.

### Regression Tests Added

- `test_task_endpoint_allows_wizard_hq_cors_origin`
- `test_task_endpoint_rejects_untrusted_cors_origin`
- `test_post_task_route_requiring_approval_returns_403_with_gates` now verifies
  route, staff mode, and selected model metadata on blocked routes.
- Dashboard static smokes now assert the Merlin face + Ask Merlin home pattern.

### Follow-Up Issues Created Or Recommended

Recommended follow-up: replace the CSS-only Merlin face with a polished product
mark asset or SVG system once the logo direction is finalized. This is visual
quality work, not a runtime blocker.

### Lesson Learned

A green API health chip is not enough browser proof. Browser fetch needs CORS,
and product UX tests must encode the intended user experience, not the old
engineering layout.

### What Not To Repeat Next Time

Do not let the Chat tab become a service dashboard again. Keep diagnostics in
System/Brains/Security, and keep the first page focused on Merlin as the product
and assistant.

### Next Recommended Step

Commit and push the CORS + Chat home polish, watch CI, then use the browser
screenshot and test output to update #113.

### Local Trusted Beta Impact

Improved. Wizard HQ now has a cleaner first-use product surface and the browser
Task API path has a regression-tested CORS fix.

### Public Beta Impact

Improved, but Public Beta still needs broader first-run onboarding, clean
installer retest evidence, model readiness empty state, and final visual polish.

### CI Retest Update

GitHub Actions run `25558697777` failed after the first push. The failing static
gate was reproduced locally with `bash tests/dashboard-security-center-smoke.sh`.
Root cause: the smoke still required old visible Chat-page labels
`Sovereignty Status` and `Agent Control` after those diagnostics were moved out
of the visible Chat page. The test was updated to verify the current Security tab
contract instead: `Sovereignty is visible`, `Approval Gates`, `Approve buttons`,
and `not present`.

Retest:

- `bash tests/dashboard-security-center-smoke.sh` — PASS
- `bash tests/dashboard-readiness-smoke.sh` — PASS
- `bash tests/dashboard-first-run-smoke.sh` — PASS
- `git diff --check` — PASS

Lesson: when a product UX decision moves engineering detail out of the primary
page, every static smoke that encodes the old layout must be audited, not only
the first failing one.

---

## #115 Wizard HQ Model Readiness Empty State

### Date / Time

2026-05-08T14:01:10Z

### Branch

`main`

### Starting Commit SHA

`deaa0b27c3457dd87199465b7b6a24dfc7f0a409`

### Target Issue(s)

- #115 Wizard HQ model readiness empty state and safe install guidance
- Supports #95 product push audit evidence

### Scope

Add an honest, read-only model readiness path so Wizard HQ can explain the
difference between an installed embedding model and an installed chat-capable
local model. Preserve no-surprise-download and local-first defaults.

### Files Changed

- `.github/workflows/ci.yml`
- `dashboard/index.html`
- `merlin/status_extension.py`
- `tests/dashboard-model-readiness-smoke.sh`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/test_status_extension.py`

### Protected Files Touched

- `.github/workflows/ci.yml`: CI gate only; added one focused static smoke.
- `merlin/status_extension.py`: read-only status endpoint only; no execution,
  memory write, cloud call, or model download behavior added.

### Commands Run

| Command | Result |
| --- | --- |
| `.venv-test/bin/python -m pytest tests/test_status_extension.py -v --tb=short` | PASS; 20 passed. |
| `bash tests/dashboard-model-readiness-smoke.sh` | PASS after regex cleanup. |
| `bash tests/dashboard-native-chat-smoke.sh` | PASS. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-readiness-smoke.sh` | PASS. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS. |
| `bash tests/dashboard-merlin-status-smoke.sh` | PASS. |
| `bash tests/dashboard-security-center-smoke.sh` | PASS. |
| `bash tests/ci-actions-node-runtime-smoke.sh` | PASS. |
| `git diff --check` | PASS. |
| `bash scripts/merlin-task-api.sh restart` | FAIL; script supports `start`, `stop`, `status`, and `run`, not `restart`. |
| `bash scripts/merlin-task-api.sh stop` then `bash scripts/merlin-task-api.sh start` | PARTIAL; old manual foreground process held port first, then start succeeded after killing old PID, but sandboxed direct curl still needed approved localhost access. |
| `bash launchd/install-launchd.sh` | PASS; launchd agents registered, including Merlin task API. |
| `/bin/zsh -lc "curl -fsS --max-time 5 http://localhost:8766/status/models \| jq '{state,chat_ready,embedding_ready,embedding_only_installed,safe_install_guidance,downloads}'"` | PASS with local-only escalation; returned `state=ready`, `chat_ready=true`, `embedding_ready=true`, `downloads=manual_only`. |

### Test Output Summary

The new `/status/models` endpoint reports local Ollama model readiness without
pulling models. Static dashboard smokes verify that Wizard HQ explains
embedding-only state, shows the safe manual install command, and does not expose
browser model pull/download controls.

### Tests Skipped And Why

Full installer retest was skipped because this slice does not change installer,
package, uninstall, launchd, startup order, or model-pull defaults. A clean
installer retest is still required before Local Trusted Beta signoff.

Live browser re-screenshot was skipped for this sub-slice because the change is
a status/readiness copy and endpoint slice covered by static dashboard smokes
and backend unit tests. Existing browser screenshot evidence for the Chat home
remains valid.

### Failures Found

1. The new static smoke initially failed because it looked for literal
   `/status/models` inside `status_extension.py`, but the endpoint is correctly
   registered under the `/status` router as `@router.get("/models")`.
2. The first regex version printed a BSD grep warning from function-call
   parentheses in the unsafe-control check.
3. `bash scripts/merlin-task-api.sh restart` failed because restart is not a
   supported subcommand.
4. A manually started old Task API process held port 8766 and confused the
   script status/start path until that PID was killed.

### Failure Category

- Test design gap
- CI/static smoke gap
- Launchd/autostart
- Status API 8765 / Task API 8766 boundary

### Root Cause Or Current Hypothesis

The smoke test encoded implementation text too literally instead of matching the
FastAPI router pattern. The regex warning came from a shell portability issue in
BSD grep extended regular expressions.

The local service restart issue was operational: the task API had been started
manually earlier in the session, outside the manager's PID file, so the manager
could not fully own the lifecycle until that old PID was removed. The manager
also does not expose a `restart` command.

### Fix Applied

- Changed the endpoint check to detect `@router.get("/models")`.
- Simplified the unsafe-control regex to avoid shell-specific parenthesis
  handling.
- Reran the smoke cleanly.
- Used the supported launchd registration path for persistent local startup.
- Verified the live `/status/models` endpoint after approving a local-only curl
  check.

### Retest Result

PASS. Backend tests and dashboard smokes pass cleanly with no grep warning. Live
`/status/models` returned `chat_ready=true`, `embedding_ready=true`, and
`downloads=manual_only` on the current machine after launchd registration.

### Regression Tests Added

- `test_status_models_reports_embedding_only_as_missing_chat_model`
- `test_status_models_reports_default_chat_model_ready`
- `test_status_models_degrades_without_ollama_tags`
- `tests/dashboard-model-readiness-smoke.sh`

### Follow-Up Issues Created Or Recommended

No new issue required. #115 covers this model-readiness slice.

Recommended follow-up issue: add `restart` support or clearer restart guidance
to `scripts/merlin-task-api.sh` so operators do not guess unsupported lifecycle
commands.

### Lesson Learned

Model readiness needs to be a first-class UX state, not inferred from generic
service health. Ollama can be up while Merlin still lacks a chat-capable model.

### What Not To Repeat Next Time

Do not equate `Ollama ready` with `Merlin Chat ready`. Treat embedding-only
installations as a clear missing-chat-model state.

Do not manually run long-lived Task API processes and then expect the manager
PID file to own them. Use launchd or the manager consistently.

### Next Recommended Step

Commit and push #115, watch CI, then close #115 if GitHub Actions passes.

### Local Trusted Beta Impact

Improved. A trusted local tester can now understand why Merlin Chat cannot
answer when only `nomic-embed-text` is installed, without dashboard downloads or
cloud fallback.

### Public Beta Impact

Improved but not sufficient for Public Beta. Public Beta still needs full clean
installer retest evidence, onboarding polish, and broader browser/manual UAT.

---

## #116 Task API Restart Lifecycle Hardening

### Date / Time

2026-05-08T14:15:06Z

### Branch

`main`

### Starting Commit SHA

`672598c353c6cd251f75047976cdb9a6581402f9`

### Target Issue(s)

- #116 Task API restart command or restart runbook
- Supports #95 product push audit evidence

### Scope

Add a supported `restart` command to the Merlin Task API lifecycle manager so
operators do not guess unsupported commands during local testing.

### Files Changed

- `scripts/merlin-task-api.sh`
- `tests/merlin-task-api-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `scripts/merlin-task-api.sh`: lifecycle manager only. No installer, model
  download, cloud, memory write, routing, or API behavior changes.

### Commands Run

| Command | Result |
| --- | --- |
| `bash -n scripts/merlin-task-api.sh` | PASS. |
| `bash scripts/merlin-task-api.sh --help` | PASS; help lists `restart`. |
| `bash tests/merlin-task-api-smoke.sh` | PASS. |
| `bash tests/launchd-core-smoke.sh` | PASS. |
| `git diff --check` | PASS. |
| `/bin/zsh -lc "bash scripts/merlin-task-api.sh restart && curl -fsS --max-time 5 http://localhost:8766/status/routes >/dev/null && curl -fsS --max-time 5 http://localhost:8766/status/models >/dev/null && echo task-api-restart-ok"` | PASS; returned `task-api-restart-ok`. |

### Test Output Summary

The Task API manager now accepts `restart`, stops the managed API, starts it
again, and preserves the expected status endpoints on port 8766.

### Tests Skipped And Why

Full installer retest was skipped because this slice only changes a local API
lifecycle helper and its smoke coverage. Installer behavior, uninstall behavior,
postinstall, package resources, and model-pull defaults were not changed.

### Failures Found

None in the #116 implementation. The issue was created from the #115 failure
learning where `restart` was not supported.

### Failure Category

- Launchd/autostart
- Test design gap
- Runbook/operator friction

### Root Cause Or Current Hypothesis

The lifecycle manager had start/stop/status/run support but no restart command,
even though restart is the natural operator action after code changes.

### Fix Applied

- Added `restart` to the command parser and help text.
- Implemented `restart_api()` as stop-then-start.
- Extended the lifecycle smoke to assert restart support and behavior shape.

### Retest Result

PASS. Static lifecycle smokes passed and the live local restart check verified
both `/status/routes` and `/status/models` after restart.

### Regression Tests Added

- Extended `tests/merlin-task-api-smoke.sh` to cover restart help, parser, and
  stop/start behavior shape.

### Follow-Up Issues Created Or Recommended

None.

### Lesson Learned

If a developer naturally tries a command during validation, the lifecycle helper
should either support it or clearly document the supported alternative.

### What Not To Repeat Next Time

Do not leave obvious lifecycle verbs unsupported after they show up in real
validation. Add the narrow command and smoke it.

### Next Recommended Step

Commit, push, watch CI, then close #116 if GitHub Actions passes.

### Local Trusted Beta Impact

Improved. Local testers and operators can refresh the Task API without manually
stopping processes or guessing launchd behavior.

### Public Beta Impact

Small improvement. Public Beta still requires full installer retest evidence and
broader onboarding polish.
