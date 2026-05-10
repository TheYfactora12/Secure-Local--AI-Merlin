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

`4753ded` (`feat(dashboard): add Merlin M browser mark`)

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
| `gh run watch 25565691603 --exit-status` | FAIL; static smoke caught stale control-plane strategy test expectations. |
| `gh run view 25565691603 --job 75048400974 --log` | PASS; failure identified as `canonical queue must include Wizard HQ product shell issue`. |
| `bash tests/control-plane-strategy-smoke.sh` | FAIL before fix; test still required closed #101 and #113 in canonical queue. |
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

### #116 Retest Correction During #114

During #114 live validation, `bash scripts/merlin-task-api.sh restart` initially
returned `status: running` but did not replace the stale Task API listener on
port 8766. The new `/status/settings` endpoint returned 404 because the old
process was still serving code from before the #114 changes.

Failure classification:

- Launchd/autostart
- Task API 8766 lifecycle
- Test design gap

Root cause:

The first restart implementation stopped only the PID-file-managed process. A
launchd/manual process can hold port 8766 without being in the manager PID file,
so `start_api` saw `/status/routes` as healthy and did not start a fresh server.

Fix:

- Reopened #116.
- Added stale port-listener detection with `lsof`.
- Hardened `restart` to stop any listener on the configured Task API port before
  starting the fresh server.
- Extended `tests/merlin-task-api-smoke.sh` so static coverage checks stale
  listener handling.

Retest:

- `bash -n scripts/merlin-task-api.sh` — PASS
- `bash tests/merlin-task-api-smoke.sh` — PASS
- `git diff --check` — PASS
- Live command:
  `/bin/zsh -lc "bash scripts/merlin-task-api.sh restart && curl -fsS --max-time 5 http://localhost:8766/status/settings | jq '{mode,settings_writes_enabled,browser_actions_enabled,cloud_default,secrets_displayed,model_downloads,total}'"`
  — PASS; returned `mode=policy_manifest`, writes disabled, browser actions
  disabled, cloud default false, secrets hidden, model downloads manual-only,
  total actions 6.

Lesson:

Do not accept "endpoint A is healthy" as proof that the running process is the
current code. Lifecycle restart must prove the old listener was actually
replaced when validating new backend routes.

---

## #114 Policy-Gated Wizard HQ Settings Backend

### Date / Time

2026-05-08T14:38:46Z

### Branch

`main`

### Starting Commit SHA

`35c9f27ec08debe0a99c75e3db4e6df42c0402b7`

### Target Issue(s)

- #114 Policy-gated Wizard HQ Settings backend
- Supports #106 Wizard HQ Product Shell
- Supports #95 product push audit evidence

### Scope

Add a read-only Settings backend manifest so Wizard HQ Settings can show which
configuration areas are locked, guidance-only, blocked by existing issues, or
future policy-gated. No browser setting writes are enabled in this slice.

### Files Changed

- `.github/workflows/ci.yml`
- `dashboard/index.html`
- `merlin/status_extension.py`
- `tests/dashboard-settings-policy-smoke.sh`
- `tests/test_status_extension.py`

### Protected Files Touched

- `.github/workflows/ci.yml`: added a focused static smoke gate.
- `merlin/status_extension.py`: added read-only status endpoint only.

### Commands Run

| Command | Result |
| --- | --- |
| `.venv-test/bin/python -m pytest tests/test_status_extension.py -q` | PASS; 23 passed. |
| `bash tests/dashboard-settings-policy-smoke.sh` | PASS. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-security-center-smoke.sh` | PASS. |
| `bash tests/merlin-task-api-smoke.sh` | PASS. |
| `git diff --check` | PASS. |
| Live `/status/settings` check after hardened Task API restart | PASS; policy manifest returned writes disabled, browser actions disabled, cloud default false, secrets hidden, model downloads manual-only, total actions 6. |

### Test Output Summary

The backend manifest and dashboard Settings panel are covered by unit tests,
static dashboard safety tests, and a live localhost endpoint check.

### Tests Skipped And Why

Full installer retest was skipped because this slice does not change installer,
package, postinstall, uninstall, model-pull defaults, or startup order. It adds a
read-only Task API status endpoint and dashboard display logic.

### Failures Found

The #114 implementation itself passed focused tests. Live validation exposed the
#116 restart bug described above; that was fixed before continuing.

### Failure Category

- Task API 8766 lifecycle
- Dashboard/Settings backend
- Test design gap

### Root Cause Or Current Hypothesis

Settings needed a backend contract before any action controls could be trusted.
The missing contract was a product readiness gap; not a runtime bug.

### Fix Applied

- Added `GET /status/settings`.
- Added an explicit settings action manifest with six Settings areas:
  Provider Connectors, Model Library, Memory Controls, Privacy & Sovereignty,
  Startup & APIs, Backup & Recovery.
- Every action declares state, approval gates, tracked issue, manual guidance,
  and that dashboard actions/secrets/cloud defaults remain disabled.
- Wizard HQ Settings now loads and renders the manifest.
- Added backend and dashboard static tests.

### Retest Result

PASS. Focused unit/static tests and live `/status/settings` check passed.

### Regression Tests Added

- `test_status_settings_returns_policy_gated_manifest`
- `test_status_settings_provider_connectors_are_locked_and_gate_secrets`
- `test_status_settings_never_exposes_secret_values`
- `tests/dashboard-settings-policy-smoke.sh`

### Follow-Up Issues Created Or Recommended

Created focused child issues for the write-capable Settings work so #114 can
remain the parent without becoming a broad mixed implementation:

- #117 `v3.1 settings: provider connector setup with secret presence-only storage`
- #118 `v3.1 settings: model library manual download confirmations`
- #119 `v3.1 settings: startup and API service controls with rollback guidance`
- #120 `v3.1 settings: memory review and delete controls after memory governance gates`

Issue creation initially failed when using a non-existent `security` label.
The repo's current labels were checked with `gh label list --limit 100`, and
the issues were recreated with existing labels only.

Posting the final #114 tracking comment also hit a transient
`error connecting to api.github.com` failure. The same comment command was
retried after network escalation and succeeded:
`https://github.com/TheYfactora12/home-ai-elite/issues/114#issuecomment-4407340308`.

### Lesson Learned

Settings should become useful through a backend policy manifest before any
write-capable UI exists. This gives users clarity without accidentally creating
a browser control plane.

### What Not To Repeat Next Time

Do not add Settings buttons before the backend action contract, approval gates,
and rollback path exist.

### Next Recommended Step

Keep #114 open as the parent for policy-gated Settings flows. Implement #117
first because provider connectors are the clearest next user-facing Settings
path, but keep secrets presence-only and cloud disabled by default.

### Local Trusted Beta Impact

Improved. Wizard HQ Settings can now explain locked/gated configuration paths
from a backend contract without exposing secrets or unsafe controls.

### Public Beta Impact

Improved but still not complete. Public Beta still needs full clean installer
retest, onboarding polish, and later policy-gated write flows.

## #117 Provider Connector Capability Map

### Date/Time

2026-05-08T10:50:00-04:00

### Branch

`main`

### Starting Commit SHA

`005435f`

### Target Issues

- #117
- #114

### Scope

Add a safer provider connector capability map before any write-capable key entry
or cloud enablement flow. This is a read-only product/engineering slice.

### Files Changed

- `merlin/provider_registry.py`
- `merlin/status_extension.py`
- `dashboard/index.html`
- `tests/test_status_extension.py`
- `tests/dashboard-tabs-smoke.sh`
- `docs/product/PROVIDER_CONNECTOR_CAPABILITIES.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

No installer, package, policy engine, router, memory manager, or task execution
behavior changed. `merlin/status_extension.py` remains read-only status surface
work.

### Commands Run

| Command | Result |
| --- | --- |
| `.venv-test/bin/python -m pytest tests/test_status_extension.py -q` | PASS; 24 passed. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-settings-policy-smoke.sh` | PASS. |
| `/bin/zsh -lc "bash scripts/merlin-task-api.sh restart >/dev/null && curl -fsS --max-time 5 http://localhost:8766/status/providers \| jq '{mode,allow_policy,cloud_enabled,external_providers_enabled,total,providers:[.providers[] \| {provider_id,api_family,user_allowed,api_key_present,setup_state}]}'"` | FAIL; exited with no visible output, command design did not preserve diagnostic detail. |
| `/bin/zsh -lc "bash scripts/merlin-task-api.sh restart; curl -v --max-time 5 http://localhost:8766/status/providers"` | PASS; HTTP 200 returned read-only provider catalog. |
| `gh run watch 25562866832 --exit-status` | FAIL due GitHub API HTTP 504 after static smokes had passed; follow-up status query was required. |
| `gh run view 25562866832 --json status,conclusion,url,headSha` | PASS; run completed with `conclusion=success` for `f41f6bb`. |

### Test Output Summary

The provider registry now returns local Ollama, LiteLLM gateway, and six
external provider families with explicit allow state, API family, auth scheme,
capabilities, key presence booleans, and known model examples. External
providers remain `not_allowed`.

### Tests Skipped And Why

Live provider calls were skipped. This slice must not call external APIs or
validate real provider keys. Full installer retest was skipped because no
installer/package behavior changed.

### Failures Found

No product test failures after implementation. The first live check command
failed with no useful output because it suppressed restart output and piped the
response through a compact `jq` filter. The rerun used visible restart output
and `curl -v`, which confirmed `/status/providers` returned HTTP 200.

The design risk identified was that a generic API key field would be wrong
because providers use different API families and auth shapes.

The final CI watch command hit a GitHub API HTTP 504 while the run was still
being queried. A direct `gh run view` query confirmed the amended run passed.

### Failure Category

- UX/readiness confusion
- Documentation mismatch risk
- CI/static smoke gap avoided
- Test design gap
- GitHub API/transient CI status query

### Root Cause Or Current Hypothesis

Provider setup needs capability metadata before UI controls exist. Without it,
Wizard HQ would likely create one generic connector flow that cannot correctly
handle OpenAI Responses, Anthropic Messages, Gemini generateContent,
Perplexity/Sonar, OpenRouter, Mistral, and local Ollama behavior.

The live-check failure was a command-observability problem, not a product
defect. The command hid useful diagnostic output.

The CI watch failure was a GitHub API availability issue, not a repo failure.

### Fix Applied

- Added provider `display_name`, `api_family`, `auth_scheme`,
  `user_allow_required`, `user_allowed`, `known_model_examples`,
  `capabilities`, and `setup_state` fields.
- Added external provider catalog entries for ChatGPT/OpenAI, Claude/Anthropic,
  Perplexity Sonar, Gemini/Google AI, Mistral AI, and OpenRouter.
- Dashboard Brains tab now loads `/status/providers` and renders connector
  allow/not-allow state with a non-clickable toggle visual.
- Added provider capability documentation with official source links.
- Retested live provider status with verbose curl after the first live command
  failed without useful diagnostics.

### Retest Result

PASS. Focused backend and dashboard static tests passed. Live
`/status/providers` returned `mode=local_only`, `cloud_enabled=false`,
`external_providers_enabled=false`, `allow_policy=explicit_user_allow_required_for_external`,
and eight providers with external providers locked/not allowed.

CI then caught an additional dashboard first-run smoke failure:
`FAIL: dashboard first-run must not expose secret-like fields`. Root cause was
the browser code referencing the backend field name `api_key_present`. The fix
keeps the backend presence-only field for API consumers, adds a neutral
`credential_present` alias, and updates Wizard HQ to render only credential
language.

### Regression Tests Added

- Provider registry tests now assert external providers are present, not
  allowed, locked until policy flow, and never expose secret values.
- Dashboard tab smoke now asserts `/status/providers`, provider loader,
  API-family rendering, and toggle-state visual.
- Existing dashboard first-run smoke caught secret-shaped browser field names;
  the browser now uses `credential_present`.

### Follow-Up Issues Created Or Recommended

#117 remains open for the write-capable provider setup flow: key submission,
secret storage, explicit allow toggle, audit event, and cloud-disabled default
must still be implemented behind backend policy gates.

### Lesson Learned

The setup screen should be provider-aware before it becomes interactive. A good
toggle UI is not enough; each provider needs the correct backend adapter family.

### What Not To Repeat Next Time

Do not add a universal API key box or a live browser toggle that enables cloud.
Build provider-specific setup contracts first.

Do not hide live-check diagnostics behind suppressed command output when
validating new endpoints.

Do not put secret-shaped field names in browser code when a neutral display
alias can carry the same presence-only state.

Do not treat a `gh run watch` transport failure as CI truth; confirm with
`gh run view` before classifying release impact.

### Next Recommended Step

Finish #117 by adding the backend-gated secret submission and explicit provider
allow flow, still presence-only and disabled by default.

### Local Trusted Beta Impact

Improved. Wizard HQ can now explain known provider options without enabling
external providers or exposing secrets.

### Public Beta Impact

Improved but incomplete. Public Beta still needs the real setup flow, manual
provider-key tests with dummy values, and full installer retest after UI/setup
changes settle.

## v3.1 Drift Review After Provider Catalog

### Date/Time

2026-05-08T11:10:00-04:00

### Branch

`main`

### Starting Commit SHA

`5fa35e9`

### Target Issues

- #106
- #114
- #117
- #118
- #119
- #120

### Scope

Review current Markdown direction against GitHub issue state before moving to
the next implementation slice.

### Files Changed

- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Commands Run

| Command | Result |
| --- | --- |
| `git status --short --branch` | PASS; clean before docs edit. |
| `gh issue list --state open --milestone "v3.1 — Wizard HQ Product Shell" --limit 30` | PASS; showed #106, #114, #117, #118, #119, #120 open. |
| `gh run list --branch main --limit 3` | PASS; latest run for `5fa35e9` green, older superseded failure retained as evidence. |
| `rg -n "#101 and #102 are open|#113 and #114|#101: continue|Active Execution Queue" docs/CANONICAL_PROJECT_STATE.md docs/MERLIN_IMPLEMENTATION_ROADMAP.md -S` | PASS after update; stale issue references removed. |
| `git diff --check` | PASS. |

### Failures Found

Documentation drift: `docs/CANONICAL_PROJECT_STATE.md` still listed #101 and
#113 in the active queue even though GitHub shows #101, #102, #113, #115, and
#116 closed. `docs/MERLIN_IMPLEMENTATION_ROADMAP.md` also still said #101/#102
were open under v3.0.

CI then exposed a matching test drift: `tests/control-plane-strategy-smoke.sh`
still required #101 and #113 in the canonical queue.

### Failure Category

- Documentation mismatch
- Roadmap/governance drift
- Test design gap

### Root Cause Or Current Hypothesis

The Wizard HQ work moved quickly through #101, #113, #115, #116, and #117. The
implementation and issue comments were updated faster than the canonical queue
and roadmap status notes. The static smoke carried the same stale queue
assumption.

### Fix Applied

- Updated the canonical active queue to #106, #114, #117, #118, #119, #120,
  #37/#95, #64, and #92.
- Added the v3.1 milestone row to the canonical milestone snapshot.
- Updated the current architecture diagram so Wizard HQ correctly points at
  both the read-only Status API and the Task API.
- Added the provider capability catalog to canonical docs.
- Updated the roadmap status note to mark #101/#102 closed and #106/#114/#117
  through #120 active.
- Updated `tests/control-plane-strategy-smoke.sh` to assert #106, #114, and
  #117 instead of closed #101 and #113.

### Retest Result

PASS after test update. The current docs and the static smoke now match GitHub
issue state for the v3.1 queue.

### Regression Test Added Or Reason Not Added

Updated existing `tests/control-plane-strategy-smoke.sh` so stale active-queue
references are caught against the current #106/#114/#117 direction.

### Lesson Learned

After fast issue closeout, update the canonical active queue before selecting
the next slice. Otherwise older docs can steer work back to closed issues.

### What Not To Repeat Next Time

Do not start implementation from an old roadmap queue without checking live
GitHub milestone state first.

### Next Recommended Step

Continue #117 only if implementing backend-gated credential setup is the next
approved slice. Otherwise move to #118 model library confirmations because it
is safer and remains read-only/manual-first.

### Local Trusted Beta Impact

Improved. The working queue is clearer and less likely to drift back to closed
Wizard HQ issues.

### Public Beta Impact

Improved governance clarity, but Public Beta still depends on later installer
retest, onboarding polish, and policy-gated settings flows.

## #118 Model Library Manual Download Confirmations

### Date/Time

2026-05-08T11:35:00-04:00

### Branch

`main`

### Starting Commit SHA

`5e185f0`

### Target Issues

- #118
- #114

### Scope

Improve Wizard HQ model readiness and manual download guidance so the product
can explain safe local model setup without implying any browser-side pull or
automatic download behavior.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-model-readiness-smoke.sh`
- `tests/control-plane-strategy-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

No installer, package, router, policy engine, or memory manager behavior
changed. This is dashboard copy plus static smoke coverage.

### Commands Run

| Command | Result |
| --- | --- |
| `.venv-test/bin/python -m pytest tests/test_status_extension.py -q` | PASS; 24 passed. |
| `bash tests/dashboard-model-readiness-smoke.sh` | PASS after adding the safe-install guidance slot. |
| `bash tests/control-plane-strategy-smoke.sh` | PASS after updating the canonical queue expectations. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-settings-policy-smoke.sh` | PASS. |
| `git diff --check` | PASS. |

### Test Output Summary

Wizard HQ model readiness now renders safe install guidance through a dedicated
slot, still reports embedding-only vs chat-ready status honestly, and keeps
downloads manual-only. The control-plane smoke now matches the live v3.1 queue.

### Tests Skipped And Why

No live model pulls were run. This slice is explicitly about manual guidance and
must not perform downloads or cloud routing. Full installer retest was not
required because installer/package behavior was untouched.

### Failures Found

The first pass exposed a stale dashboard assumption: the model readiness panel
had a hardcoded safe-install string instead of a dedicated slot for model
guidance. The control-plane smoke also still carried closed issue references
until updated.

### Failure Category

- UX/readiness confusion
- Documentation mismatch
- Test design gap

### Root Cause Or Current Hypothesis

Model guidance needs a dedicated rendering slot so future copy or instructions
can be updated without touching the rest of the readiness wording. The control
plane smoke was still enforcing older issue numbers after the queue moved.

### Fix Applied

- Added a `brains-safe-install` slot to the model readiness panel.
- Wired the model readiness renderer to use `safe_install_guidance`.
- Updated `tests/dashboard-model-readiness-smoke.sh` to require the guidance
  slot in addition to the safe manual install command.
- Updated `tests/control-plane-strategy-smoke.sh` so the canonical queue
  expects #106, #114, #117, #118, #119, and #120.

### Retest Result

PASS. Backend tests, dashboard model readiness, dashboard tabs, settings smoke,
and control-plane strategy smoke all passed.

### Regression Tests Added

- `brains-safe-install` model guidance slot check in
  `tests/dashboard-model-readiness-smoke.sh`
- current v3.1 queue checks in `tests/control-plane-strategy-smoke.sh`

### Lesson Learned

When a readiness panel already teaches the difference between chat models and
embedding models, give the safe install guidance its own slot instead of hiding
it in a generic label.

### What Not To Repeat Next Time

Do not leave hardcoded install guidance in the dashboard if the panel is meant
to evolve into a richer model library view.

### Next Recommended Step

Move to the next read-only/manual-first Settings slice only after this model
library view is reviewed in-browser. If it still feels too generic, create a
small follow-up for the richer model library browser view before any credential
flow work.

### Local Trusted Beta Impact

Improved. The model readiness screen now has a clearer place for safe manual
install guidance and does not imply browser-driven downloads.

### Public Beta Impact

Improved, but Public Beta still needs the final installer retest, onboarding
polish, and whatever write-capable settings flows remain after #118 is reviewed
in the browser.

## #118 Richer Model Library Browser And Live API Pass

### Date/Time

2026-05-08T17:57:00-04:00

### Branch

`main`

### Starting Commit SHA

`57d85e8`

### Target Issues

- #118
- #114
- #106

### Scope

Expand Wizard HQ from a single safe-install line into a richer read-only model
library view that shows installed/missing local models, requires warning review
before showing manual commands, and keeps downloads manual-only.

### Files Changed

- `merlin/status_extension.py`
- `dashboard/index.html`
- `tests/test_status_extension.py`
- `tests/dashboard-model-readiness-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `docs/release/evidence/assets/2026-05-08-wizard-hq/model-library-browser-open.png`
- `docs/release/evidence/assets/2026-05-08-wizard-hq/model-library-brains-tab.png`

### Protected Files Touched

No installer, package script, router, policy engine, task execution behavior, or
memory manager behavior changed. The Task API status extension was touched only
to add read-only model-library metadata.

### Commands Run

| Command | Result |
| --- | --- |
| `curl -fsS --max-time 5 http://localhost:3000 >/dev/null` | FAIL; wrong target for Wizard HQ. Port 3000 is Open WebUI. |
| `curl -fsS --max-time 5 http://localhost:8766/status/models` | FAIL initially; Task API was down before this validation pass. |
| `bash scripts/status.sh` | PASS; showed Wizard HQ on port 8888 and Open WebUI on port 3000. |
| `bash scripts/merlin-status-api.sh start` | PASS; status API running on 8765 with execution disabled. |
| `bash scripts/merlin-task-api.sh start` | PASS; task API started for validation. |
| `curl -fsS --max-time 5 http://127.0.0.1:8888 \| rg ...` | PASS; live Wizard HQ served the new model-library markup. |
| `curl -fsS --max-time 5 http://127.0.0.1:8766/status/models \| jq ...` | FAIL before restart; live API still served old fields with `manual_confirmation_required: null`. |
| `bash scripts/merlin-task-api.sh restart` | PASS; restarted the stale listener. |
| `/bin/zsh -lc "PYTHONPATH=. .venv-test/bin/python -m merlin.task_endpoint"` | PASS for foreground browser validation; later replaced by script-managed background service. |
| `curl -fsS --max-time 5 http://127.0.0.1:8766/status/models \| jq ...` | PASS after restart; returned `manual_confirmation_required: true`, `downloads: manual_only`, and low-memory warning. |
| `open -a Safari http://127.0.0.1:8888` | PASS; Wizard HQ opened in Safari. |
| `osascript -e 'tell application "Safari" to do JavaScript ...'` | FAIL; Safari requires "Allow JavaScript from Apple Events" for scripted tab switching. |
| `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/model-library-browser-open.png` | PASS; captured live Wizard HQ browser evidence. |
| `open -a Safari http://127.0.0.1:8888/#brains` | PASS after adding hash-based tab routing; opened Wizard HQ directly on Brains. |
| `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/model-library-brains-tab.png` | PASS; captured Brains tab and Local Model Library start. |
| `.venv-test/bin/python -m pytest tests/test_status_extension.py -q` | PASS; 24 passed. |
| `bash tests/dashboard-model-readiness-smoke.sh` | PASS. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-settings-policy-smoke.sh` | PASS. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS. |
| `git diff --check` | PASS. |
| combined static tests plus immediate live curl | FAIL once; localhost probe hit a transient Task API startup/race window. |
| separated static tests and live `/status/models` curl | PASS; static tests passed and live endpoint returned the expected model-library fields. |

### Test Output Summary

The live status endpoint now exposes model-library metadata:
`manual_confirmation_required: true`, `downloads: manual_only`, and an
8GB/core low-memory warning. Wizard HQ serves the richer model-library markup
and the static smokes enforce that no browser model pull/download controls were
introduced.

### Tests Skipped And Why

No model download was run. The purpose of #118 is manual confirmation and
guidance, not pulling models from the browser or installer.

No full installer retest was run because installer/package behavior was not
changed.

### Failures Found

1. The first validation check used port 3000 for Wizard HQ, but 3000 is Open
   WebUI. Wizard HQ is port 8888.
2. Task API was initially down before validation and then served stale
   `/status/models` fields until restarted.
3. Safari refused scripted tab switching because JavaScript from Apple Events is
   disabled.
4. A combined static-test-plus-live-curl command failed once because the live
   localhost probe hit the Task API during a short service lifecycle window.

### Failure Category

- Wizard HQ/dashboard live validation
- Status API / Task API service lifecycle
- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

Port confusion came from the product split: Wizard HQ is the Merlin product hub
on 8888, while Open WebUI remains the optional chat bridge on 3000.

The stale API field behavior matches the known Task API listener pattern: code
changes require an explicit restart before live browser validation.

Safari Apple Events failure is a local browser-control limitation, not a Merlin
runtime defect.

The final live curl race is a #119 service lifecycle hardening concern. The
service was reachable immediately afterward and the separated final validation
passed.

### Fix Applied

- Added read-only model-library metadata to `/status/models`.
- Added a rendered Local Model Library in Brains and Settings.
- Required a warning review disclosure before manual model commands are shown.
- Added backend/unit and dashboard static smoke assertions for manual-only
  downloads, confirmation requirement, and low-memory warning.
- Added hash-based tab routing so `#brains` can be opened directly for manual
  review and evidence capture.
- Restarted Task API and converted it back to script-managed background service
  after the foreground validation pass.

### Retest Result

PASS. The script-managed Task API reports running and returns the new fields.
Focused backend and dashboard smoke tests pass.

### Regression Tests Added

- `tests/test_status_extension.py` now checks `manual_confirmation_required`,
  `low_memory_warning`, `download_policy`, and `confirmation_required`.
- `tests/dashboard-model-readiness-smoke.sh` now checks the model-library render
  targets, warning disclosure, backend confirmation field, and low-memory field.
- `tests/dashboard-tabs-smoke.sh` now checks the Local Model Library and warning
  review language, plus hash-based tab routing.

### Follow-Up Issues Created Or Recommended

No new issue was created. Existing #119 covers startup/API controls and remains
the right place to harden stale listener handling further.

### Lesson Learned

Live browser validation needs the product-port split called out every time:
Wizard HQ is 8888; Open WebUI is 3000. Also restart Task API before validating
new status fields in the browser.

### What Not To Repeat Next Time

Do not validate Wizard HQ against port 3000. Do not trust a live status endpoint
to reflect code changes until the owning service has been restarted and
rechecked.

### Next Recommended Step

Review the Brains tab manually in Safari. If the model library feels right,
finish #118 with the current read-only/manual-only implementation; otherwise
make a small visual polish slice before moving to #119 startup/API controls.

### Local Trusted Beta Impact

Improved. Users now get a clearer local model library without surprise downloads
or browser execution controls.

### Public Beta Impact

Improved, but Public Beta still depends on full installer retest, richer
onboarding validation, and remaining write-capable Settings flows.

## #119 Startup And API Service Visibility

### Date/Time

2026-05-08T18:18:00-04:00

### Branch

`main`

### Starting Commit SHA

`9ccffcf`

### Target Issues

- #119
- #114
- #106

### Scope

Add read-only Wizard HQ Startup & APIs visibility with clear service state,
manual recovery guidance, rollback guidance, and explicit 8765/8766 boundaries.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-settings-policy-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

No installer, package script, launchd plist, router, policy engine, task
endpoint, memory manager, or service manager behavior changed.

### Commands Run

| Command | Result |
| --- | --- |
| `gh issue view 119 --json number,title,state,body,labels,milestone,comments` | PASS; confirmed #119 scope and acceptance criteria. |
| `gh issue list --state open --milestone "v3.1 — Wizard HQ Product Shell" --limit 30 --json number,title,state,labels` | PASS; open queue remains #106, #114, #117, #119, #120. |
| `rg -n "#119\|Startup & APIs\|startup\|API service\|service controls\|Wizard HQ\|v3.1\|active queue\|Task API\|Status API" ...` | PASS; plan check supports read-only visibility and no browser service execution. |
| `bash tests/dashboard-settings-policy-smoke.sh` | PASS. |
| `bash tests/dashboard-tabs-smoke.sh` | PASS. |
| `bash tests/dashboard-first-run-smoke.sh` | PASS. |
| `bash tests/merlin-task-api-smoke.sh` | PASS. |
| `git diff --check` | PASS. |

### Test Output Summary

Wizard HQ Settings now shows Startup & APIs state slots for Status API 8765 and
Task API 8766, manual recovery commands, rollback guidance, and an explicit
boundary statement. Static tests verify no service start/stop/restart browser
controls were added and that the dashboard still has exactly one POST path:
Merlin Chat through `/task`.

### Tests Skipped And Why

No live restart test was run in this slice. #119 currently adds dashboard
visibility/guidance only and does not change service manager behavior. Live
service lifecycle hardening remains covered by existing task API smoke and the
prior #116/#118 evidence.

No full installer retest was run because installer/package/launchd behavior was
not changed.

### Failures Found

No new test failure in this slice.

### Failure Category

- Documentation/governance drift noted: `docs/MASTER_PROMPT.md` still reflects
  older v3.0 release-readiness queue language while canonical state now governs
  v3.1 Wizard HQ work.

### Root Cause Or Current Hypothesis

The master prompt is lower priority than GitHub issue state and
`docs/CANONICAL_PROJECT_STATE.md`; it needs a separate governance update to
avoid stale prompts steering future work.

### Fix Applied

- Added a wider Startup & APIs Settings card.
- Added live state slots for Status API 8765 and Task API 8766.
- Added manual recovery commands:
  - `bash scripts/merlin-status-api.sh start`
  - `bash scripts/merlin-task-api.sh restart`
  - `bash launchd/install-launchd.sh`
  - `bash scripts/merlin-task-api.sh stop`
- Added static smoke checks for API boundaries, recovery guidance, rollback
  guidance, and absence of browser service controls.

### Regression Tests Added

- `tests/dashboard-settings-policy-smoke.sh` now verifies startup/API service
  visibility, 8765/8766 boundary language, and no browser service controls.
- `tests/dashboard-tabs-smoke.sh` now verifies the Task API restart CLI handoff.

### Long-Term Platform Note

The finished product must install and run on both macOS and Linux. Launchd is
macOS-specific; scripts, Docker profiles, status surfaces, and service recovery
language must remain portable or clearly label platform-specific steps. Future
installer/readiness work should validate both macOS and Linux paths before
public release claims.

### Follow-Up Issues Created Or Recommended

Recommended governance follow-up: align `docs/MASTER_PROMPT.md` with canonical
v3.1 issue order so stale v3.0 queue text does not pull future sessions backward.

### Lesson Learned

Startup controls are high-risk product surface. Showing exact state, recovery,
and rollback guidance gives the user confidence without turning the browser into
a shell.

### What Not To Repeat Next Time

Do not add service control buttons until a backend policy gate, audit trail, and
rollback design exist. Do not treat macOS launchd guidance as a Linux solution.

### Next Recommended Step

Commit this read-only #119 slice, update #119 with evidence, and keep actual
backend-gated service controls deferred until they have policy/audit design.

### Local Trusted Beta Impact

Improved. Users can see what to do when 8765/8766 are warming or stale without
unsafe browser execution.

### Public Beta Impact

Improved, but Public Beta still needs cross-platform installer/readiness
validation on macOS and Linux.

## ClosClaw / Policy-Gated Web Comprehension Triage

### Date/Time

2026-05-08, late session.

### Starting Commit SHA

`b85140f8e2e0f6b8d53e8171e037329c63ca6385`

### Target Issues

- #106
- #108
- #117
- #119
- #121

### Scope

Validated the ClosClaw/OpenClaw product idea from the external planning note
against the current repo, sprint board, canonical state, and live GitHub issue
queue.

### Commands Run

- `git status --short && git rev-parse HEAD`
- `rg -n "ClosClaw|OpenClaw|web_fetch|web comprehension|Consent-Gated Web|PATENT_CLAIM_5|SPRINT_BOARD|SCRUM_MANAGEMENT|#118|#82|#83" docs merlin tests`
- `ls docs/ip && rg -n "\[YOUR FULL LEGAL NAME|PATENT_CLAIM_5|MerlinFlow|Element 6|Consent-Gated|ClosClaw" docs/ip docs/CANONICAL_PROJECT_STATE.md docs/scrum`
- `sed -n '1,220p' docs/CANONICAL_PROJECT_STATE.md`
- `gh issue list --state open --limit 80 --json number,title,state,milestone,labels`
- `gh issue view 106 --json number,title,state,milestone,labels,body`
- `gh issue view 117 --json number,title,state,milestone,labels,body`
- `gh issue view 119 --json number,title,state,milestone,labels,body`
- `gh label list --limit 100`
- `gh issue view 108 --json number,title,state,milestone,labels,body`
- `gh issue view 107 --json number,title,state,milestone,labels,body`
- `gh issue view 104 --json number,title,state,milestone,labels,body`
- `gh issue create --title "v3.7 design: policy-gated web comprehension connector" ...`

### Test Output Summary

- Worktree was clean at `b85140f8e2e0f6b8d53e8171e037329c63ca6385` before this
  evidence note update.
- No existing `ClosClaw`, `OpenClaw`, `web_fetch`, or `Consent-Gated Web`
  implementation was found in repo code/docs/tests.
- Live GitHub issue queue confirmed #106, #114, #117, #119, and #120 remain the
  v3.1 Wizard HQ Product Shell / Settings work.
- #108 is the closest existing parent area for local fallback/degraded behavior.
- Created #121 as the design-only tracking issue for policy-gated web
  comprehension.

### Failures Found

No command failure. Product drift risk found: the ClosClaw idea is valid, but it
would introduce external network access if implemented inside the current v3.1
Settings work.

### Failure Category

- Roadmap/governance drift
- No-cloud/default privacy
- UX/readiness confusion risk

### Root Cause Or Current Hypothesis

The idea came from an external planning note and was not yet represented in
GitHub issues or canonical execution order. Without triage, it could be
mistakenly pulled into #117 provider setup or #119 service controls.

### Fix Applied

Created GitHub issue #121:
`v3.7 design: policy-gated web comprehension connector`.

The issue keeps this as future design work, with explicit constraints:

- no default web access,
- no browser automation,
- no silent memory writes,
- no routing confidence changes,
- no public patent/IP claim language,
- backend policy gate and local audit required before any network fetch.

### Regression Test Added Or Reason Not Added

No code regression test added because this was governance triage only. Future
implementation child issues must add static tests for no-default-network,
no-secret-logging, redaction, offline/degraded behavior, and no browser shell
execution.

### Follow-Up Issues Created Or Recommended

- Created #121.

### Lesson Learned

Network-capable features need to enter through a design issue first. Even a
useful web comprehension layer can weaken Merlin's local-first promise if it is
added before policy gates, redaction, audit payloads, and offline behavior are
specified.

### What Not To Repeat Next Time

Do not add web fetch, crawler, browser automation, or "current info" features to
Wizard HQ just because the UX would benefit. First define the policy gate,
redaction boundary, and degraded/offline state.

### Next Recommended Step

Return to the active v3.1 queue: #117 provider connector setup or #120 memory
review/delete controls, with #119 backend service controls left open until a
policy-gated service action design exists.

### Local Trusted Beta Impact

Improved governance. The future web-comprehension idea is now tracked without
changing local-first runtime behavior.

### Public Beta Impact

Improved risk control. Public Beta should not claim web comprehension until
#121 design and child implementation issues are complete and tested.

## #121 ClosClaw Design Slice

### Date/Time

2026-05-08, late session.

### Starting Commit SHA

`8e7fbcb43093c2857a1add9cb0935ff7825c655e`

### Target Issues

- #121
- #108
- #106
- #95

### Scope

Advanced #121 as design-only work. No runtime web fetch, browser automation,
external network call, memory write, routing change, or dashboard action control
was added.

### Files Changed

- `.github/workflows/ci.yml`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/architecture/CLOSCLAW_WEB_COMPREHENSION.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `tests/closclaw-design-smoke.sh`

### Protected Files Touched

- `.github/workflows/ci.yml` was touched only to add the new static smoke test
  to CI. No CI gate was removed or weakened.

### Commands Run

- `git status --short && git rev-parse HEAD`
- `gh issue view 121 --json number,title,state,milestone,labels,body`
- `sed -n '1,180p' docs/CANONICAL_PROJECT_STATE.md`
- `rg -n "no browser|external network|cloud|telemetry|provider connector|Settings|web" docs/security docs/architecture docs/product tests dashboard merlin | head -120`
- `sed -n '1,220p' tests/dashboard-settings-policy-smoke.sh`
- `sed -n '1,180p' tests/control-plane-strategy-smoke.sh`
- `sed -n '1,170p' docs/product/PROVIDER_CONNECTOR_CAPABILITIES.md`
- `sed -n '1,140p' docs/security/SECURITY_MODEL.md`
- `bash -n tests/closclaw-design-smoke.sh`
- `bash tests/closclaw-design-smoke.sh`
- `bash tests/control-plane-strategy-smoke.sh`
- `git diff --check`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"'`

### Test Output Summary

- `bash -n tests/closclaw-design-smoke.sh`: PASS.
- `bash tests/closclaw-design-smoke.sh`: PASS; design is policy-gated and
  no-default-network.
- `bash tests/control-plane-strategy-smoke.sh`: PASS.
- `git diff --check`: PASS.
- Workflow YAML parse: PASS; `workflow-yaml-ok`.

### Tests Skipped And Why

- No live browser, Docker, Ollama, Qdrant, or network fetch tests were run
  because #121 is design-only and must not add runtime web access yet.
- No full installer retest was run because installer/package behavior did not
  change.

### Failures Found

No command failure. The original risk remains product-scope risk: web
comprehension is valuable but unsafe to implement before policy gate, redaction,
audit, offline/degraded state, and no-default-network tests exist.

### Failure Category

- Roadmap/governance drift avoided.
- No-cloud/default privacy protected.
- Test design gap closed with a static smoke test.

### Root Cause Or Current Hypothesis

External-source features can be mistaken for ordinary provider setup. They are
actually a separate network-capable connector class and need their own security
contract.

### Fix Applied

- Added `docs/architecture/CLOSCLAW_WEB_COMPREHENSION.md`.
- Added `tests/closclaw-design-smoke.sh`.
- Added the smoke test to CI.
- Linked the design doc from canonical state.

### Regression Test Added

`tests/closclaw-design-smoke.sh` verifies:

- #121 remains design/future scoped,
- external network is denied by default,
- `external_network` is named as the required gate,
- redaction and metadata-only audit are required,
- 8765/8766 boundaries remain explicit,
- default-enabled network, browser automation, silent memory writes, routing
  confidence changes, cloud telemetry, and browser-side fetch controls are
  forbidden.

### Follow-Up Issues Created Or Recommended

Use #121 to split future child issues:

1. Status-only Wizard HQ copy for disabled/offline source reading.
2. Backend policy contract and audit payload.
3. Redaction test corpus and metadata-only logging.
4. URL-only approved fetch prototype.
5. Search-result fetch prototype behind the same policy gate.

### Lesson Learned

ClosClaw is a strong product direction, but only if it preserves Merlin's trust
model. The correct first step is a security contract and smoke test, not a
fetcher.

### What Not To Repeat Next Time

Do not add source-reading, web search, URL fetch, or "current info" behavior as
a dashboard convenience. Any external source read belongs behind a backend
policy gate and redaction/audit boundary.

### Next Recommended Step

Finish the current v3.1 Wizard HQ product shell work first. If #121 is pulled
forward, implement only child issue 1 first: disabled/offline Wizard HQ copy with
no network access.

### Local Trusted Beta Impact

Improved. The future external-source surface is now constrained before runtime
code exists.

### Public Beta Impact

Improved. Public Beta claims must continue to avoid web comprehension until
#121 child implementation issues are complete and tested.

## #117 Provider Connector Presence-Only Backend Slice

### Date/Time

2026-05-09, early session.

### Starting Commit SHA

`6c92d6a1e0ed6e7d6c29273e3bdb1e3188e98514`

### Target Issues

- #117
- #114
- #106
- #95

### Scope

Added the smallest backend-only provider connector setup contract. This slice
does not add Wizard HQ key-entry forms, does not call external providers, does
not enable cloud routing, and does not persist raw API keys.

### Files Changed

- `.github/workflows/ci.yml`
- `docs/product/PROVIDER_CONNECTOR_CAPABILITIES.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `merlin/provider_connector_store.py`
- `merlin/provider_registry.py`
- `merlin/status_extension.py`
- `tests/provider-connector-policy-smoke.sh`
- `tests/test_provider_connector_store.py`
- `tests/test_status_extension.py`

### Protected Files Touched

- `.github/workflows/ci.yml`: added the new static smoke test to CI.
- `merlin/status_extension.py`: added execution-aware backend setup routes under
  the existing Task API status extension; 8765 read-only status API is unchanged.

### Commands Run

- `git status --short && git rev-parse HEAD`
- `gh issue list --state open --limit 40 --json number,title,state,milestone,labels`
- `sed -n '1,190p' docs/CANONICAL_PROJECT_STATE.md`
- `sed -n '1,120p' docs/scrum/SPRINT_BOARD.md`
- `gh issue view 114 --json number,title,state,milestone,labels,body`
- `gh issue view 117 --json number,title,state,milestone,labels,body`
- `sed -n '1,460p' merlin/status_extension.py`
- `sed -n '1,340p' merlin/provider_registry.py`
- `sed -n '1,280p' merlin/policy_engine.py`
- `sed -n '1,320p' merlin/memory_manager.py`
- `sed -n '1,260p' merlin/task_endpoint.py`
- `rg -n "audit|write_audit|approval|secret_access|api_key_use|cloud_model_call|external_network" merlin tests configs docs | head -160`
- `bash -n tests/provider-connector-policy-smoke.sh && bash tests/provider-connector-policy-smoke.sh`
- `.venv-test/bin/python -m pytest tests/test_provider_connector_store.py tests/test_status_extension.py tests/test_task_endpoint.py -q`
- `bash tests/dashboard-settings-policy-smoke.sh && bash tests/dashboard-tabs-smoke.sh`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"' && git diff --check`

### Test Output Summary

- `bash tests/provider-connector-policy-smoke.sh`: PASS; provider connector
  setup is approval-gated and presence-only.
- Python focused suite: PASS; `41 passed`.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- Workflow YAML parse: PASS; `workflow-yaml-ok`.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No live external provider/API test was run because #117 must not call cloud
  providers or use API keys in this slice.
- No browser form/manual screenshot was captured because no Wizard HQ input
  control was added yet.
- No full installer retest was run because installer/package behavior did not
  change.

### Failures Found

No command failure. A design risk was identified and contained: accepting API
keys before a real vault could accidentally become raw secret persistence.

### Failure Category

- Secret/log redaction risk avoided.
- No-cloud/default privacy protected.
- CI/static smoke gap closed.

### Root Cause Or Current Hypothesis

Provider setup is useful UX, but raw provider credentials require a stronger
vault/keychain design than this slice should introduce. The safest first step is
presence-only metadata plus explicit approval and tests.

### Fix Applied

- Added `merlin/provider_connector_store.py` for presence-only connector
  metadata.
- Added backend routes on the execution-aware Task API:
  - `POST /status/settings/provider-connectors`
  - `POST /status/settings/provider-connectors/{provider_id}/disable`
- Required `approval_id` for writes.
- Returned only public presence/status fields.
- Attempted metadata-only `provider_connector` audit events.
- Updated provider registry to reflect configured/allowed state without
  returning secrets.
- Updated provider connector docs and added CI smoke coverage.

### Regression Tests Added

- `tests/test_provider_connector_store.py`
- New provider-connector cases in `tests/test_status_extension.py`
- `tests/provider-connector-policy-smoke.sh`

### Follow-Up Issues Created Or Recommended

Recommended next #117 child slice: Wizard HQ provider setup UI that calls the
backend route only after explicit user confirmation, with no raw value returned
or rendered after submission.

Recommended future issue before real provider calls: encrypted/OS-keychain
secret vault plus explicit routing policy for external provider use.

### Lesson Learned

Connector setup and cloud usage are separate controls. A provider can be
configured/allowed in Wizard HQ while cloud routing still remains disabled until
a later policy slice explicitly enables model calls.

### What Not To Repeat Next Time

Do not treat environment key presence or provider setup as permission to route
to cloud. Do not store raw keys in repo-local JSON. Do not add browser key forms
without no-secret-render tests.

### Next Recommended Step

Commit this backend-only #117 slice, watch CI, then implement the Wizard HQ UI
surface only if it can keep the same presence-only/no-cloud contract.

### Local Trusted Beta Impact

Improved. Merlin now has a tested backend contract for provider setup metadata
without weakening local-first defaults.

### Public Beta Impact

Improved foundation. Public Beta still requires real secret vault/keychain
design before external providers should be considered usable.

## #135 Product Soul / Rooms Roadmap Alignment

### Date/Time

2026-05-09, early session.

### Starting Commit SHA

`d2e57f581d381ee890800e9362ddaccd5bf2e408`

### Target Issues

- #135
- #106
- #117
- #120
- #95

### Scope

Aligned the Markdown roadmap and product docs around the clarified product
focus: Merlin Chat, Rooms, local chat history, scoped context, and
approval-gated memory extraction. This pass explicitly defers features that do
not directly support that loop.

### Files Changed

- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md`
- `docs/README.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

No runtime protected files touched in this docs-only alignment pass.

### Commands Run

- `rg -n "Room|Rooms|chat history|transcript|conversation history|local chat|project memory|workspace memory" docs merlin dashboard tests .github | head -160`
- `gh issue list --state open --limit 80 --json number,title,state,milestone,labels ...`
- `gh issue create --title "v3.1: Merlin Rooms for local chat history and scoped context" ...`
- `git status --short && git rev-parse HEAD`
- `sed -n '1,220p' docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `sed -n '1,220p' docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `sed -n '1,220p' docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md`
- `gh run list --limit 3 --json databaseId,headSha,status,conclusion,workflowName,url`
- `gh issue view 135 --json number,title,state,milestone,labels,body`

### Test Output Summary

- GitHub issue lookup initially failed due API/network connectivity, then
  succeeded on retry.
- Existing issue search found #120 as related memory review/delete work but no
  existing Rooms/chat-history issue.
- Created #135 under `v3.1 — Wizard HQ Product Shell`.
- CI for the preceding #117 backend commit passed on run `25600208322`.
- First `bash tests/control-plane-strategy-smoke.sh` run failed because the
  edited strategy doc no longer contained the exact required phrase
  `cloud providers`.
- Retest passed after restoring explicit `cloud providers` wording.
- `bash tests/release-readiness-readme-smoke.sh`: PASS.
- `bash tests/provider-connector-policy-smoke.sh`: PASS.
- `git diff --check`: PASS.

### Tests Skipped And Why

No runtime test was run for this docs-only alignment before editing. Static
docs/roadmap checks are run after the final diff.

### Failures Found

1. GitHub issue lookup initially failed with `error connecting to api.github.com`.
2. Push for the #117 backend commit was rejected because remote `main` advanced
   with product north-star docs.
3. Control-plane strategy smoke failed after a wording change removed a phrase
   the smoke test intentionally checks.

### Failure Category

- GitHub/network availability.
- Roadmap/governance drift risk.
- Collaboration race on `main`.

### Root Cause Or Current Hypothesis

The session was active while new product-direction commits landed remotely. The
first issue lookup also hit a transient GitHub/API connection failure.

### Fix Applied

- Retried GitHub issue lookup with network access.
- Created #135 only after confirming no existing Rooms issue.
- Fetched and rebased the #117 backend commit on top of remote `main`.
- Re-ran focused #117 tests after rebase before pushing.
- Updated roadmap and product docs to make `PRODUCT_NORTH_STAR.md` the product
  decision filter.
- Restored the explicit `cloud providers` wording in the strategy doc while
  preserving the new rule that they remain optional connectors, never defaults.

### Regression Test Added Or Reason Not Added

No new automated test added for the GitHub connectivity failure because it was
environment/network-specific. The process improvement is documented here:
always fetch/rebase and re-check product-direction docs before roadmap edits.
For doc smokes, preserve exact safety phrases unless the smoke is intentionally
updated in the same slice.

### Follow-Up Issues Created Or Recommended

- Created #135: `v3.1: Merlin Rooms for local chat history and scoped context`.

Recommended next child issue after #135 design:

- `v3.1: Room data model and local transcript boundary`
- `v3.1: Wizard HQ Room picker and reference policy copy`
- `v3.1: Save chat to Room flow, no memory extraction by default`

### Lesson Learned

The product direction is now sharper: Merlin wins by becoming the user's
private chat/history/Rooms/memory system. Provider connectors, ClosClaw,
automation, and governance are supporting layers, not the center.

### What Not To Repeat Next Time

Do not keep building peripheral connector surfaces if Merlin Chat, Rooms,
memory review, and export/import brain are not moving forward. Do not edit
roadmaps from stale local state after a push rejection; fetch and read the new
product docs first.

### Next Recommended Step

Run docs/static checks, commit the roadmap alignment, push, and then start #135
design before adding any new peripheral feature.

### Local Trusted Beta Impact

Improved focus. Local Trusted Beta should demonstrate a user-owned Merlin
conversation and memory path, not a broad unfinished control panel.

### Public Beta Impact

Improved positioning. Public Beta claims should center on Merlin Chat, Rooms,
local memory, and export/import brain once evidence exists.

## Coding Master Prompt v2 Alignment

### Date/Time

2026-05-09, early session.

### Starting Commit SHA

`8e928e127f0fc8dbb09ff4a33de3b9e608ecaff0`

### Target Issues

- #122
- #123
- #134
- #135
- #106
- #31
- #32

### Scope

Added a current Merlin AI coding master prompt v2 as a repo documentation
artifact and CI-covered focus contract. The prompt encodes the clarified product
direction: Merlin Chat, Rooms, user-owned local context, approved memory,
Export/Import Brain, and governed actions.

### Files Changed

- `.github/workflows/ci.yml`
- `docs/CODEX_MASTER_PROMPT_V2.md`
- `docs/README.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `tests/codex-master-prompt-v2-smoke.sh`

### Protected Files Touched

- `.github/workflows/ci.yml`: added the new prompt smoke to existing static
  smoke gates. No CI gate was removed or weakened.

### Commands Run

- `git status --short && git rev-parse HEAD`
- `gh issue list --state open --limit 120 --json number,title,state,milestone,labels ...`
- `sed -n '1,260p' docs/product/PRODUCT_NORTH_STAR.md`
- `rg -n "Sovereignty|Rooms|Round Table|Product Value|#134|#123|#130|#135|Fast|Smart|CODEX_MASTER_PROMPT_V2|Governed Intelligence" docs README.md dashboard tests merlin | head -200`
- `sed -n '1,160p' tests/master-prompt-smoke.sh`
- `sed -n '1,120p' CODEX_MASTER_PROMPT.md 2>/dev/null || true && sed -n '1,120p' docs/engineering/CODEX_MASTER_PROMPT.md`
- `sed -n '1,80p' docs/README.md`
- `rg --files merlin | rg 'workflow_synthesizer|preference_extractor|router|session_reflector'`
- `rg -n "PATENT CLAIM ANCHOR|negation_suppressed_confidence|NO_RETRAINING_CONSTRAINT|blend_route_confidence|time_decay_weight" merlin docs/ip | head -80`
- `bash -n tests/codex-master-prompt-v2-smoke.sh && bash tests/codex-master-prompt-v2-smoke.sh`
- `bash tests/master-prompt-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"' && git diff --check`

### Test Output Summary

- Live issue validation confirmed #122 through #135 exist, including #122,
  #123, #134, and #135.
- `bash tests/master-prompt-smoke.sh`: PASS.
- `bash tests/release-readiness-readme-smoke.sh`: PASS.
- `bash -n tests/codex-master-prompt-v2-smoke.sh && bash tests/codex-master-prompt-v2-smoke.sh`: PASS after fixing the docs-index link expectation.
- Workflow YAML parse: PASS; `workflow-yaml-ok`.
- `git diff --check`: PASS.
- First run of `tests/codex-master-prompt-v2-smoke.sh` failed because the smoke
  expected `docs/CODEX_MASTER_PROMPT_V2.md` while `docs/README.md` correctly
  links the file relative to the docs directory as `CODEX_MASTER_PROMPT_V2.md`.

### Tests Skipped And Why

- No runtime tests were run because this is docs/CI-smoke alignment only.
- No browser screenshot was captured because no Wizard HQ UI changed.

### Failures Found

The new v2 prompt smoke test had an incorrect docs-index path expectation.

### Failure Category

- Test design gap.

### Root Cause Or Current Hypothesis

The smoke test used a repo-root path while the docs index uses docs-relative
Markdown links.

### Fix Applied

Updated `tests/codex-master-prompt-v2-smoke.sh` to check
`CODEX_MASTER_PROMPT_V2.md`, matching the real docs index link.

### Retest Result

Passed after the smoke expectation was corrected:

- `bash -n tests/codex-master-prompt-v2-smoke.sh && bash tests/codex-master-prompt-v2-smoke.sh`
- `bash tests/master-prompt-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"'`
- `git diff --check`

### Regression Test Added

`tests/codex-master-prompt-v2-smoke.sh` verifies the v2 prompt includes:

- product soul,
- architecture constraints,
- issue priorities,
- 8765/8766 boundary,
- no silent memory writes,
- no secret display,
- Sovereignty Indicator,
- Round Table Approval Card,
- first-run flow,
- next concrete build steps,
- deferral of web browsing/peripheral systems until the core loop is useful.

### Follow-Up Issues Created Or Recommended

No new issue created in this slice. Existing #122, #123, #134, and #135 now
govern the next product work.

### Lesson Learned

The prompt is useful only if it is enforced by tests and grounded in live issue
state. Prompt files should not become another stale roadmap.

### What Not To Repeat Next Time

Do not paste a broad master prompt into repo docs without validating live issue
numbers, checking current implementation truth, and adding a smoke test.

### Next Recommended Step

Commit, push, and watch CI. Then start #130 or #135 depending on which most
directly advances the product value demo.

### Local Trusted Beta Impact

Improved. Future sessions now have a CI-covered focus contract centered on the
Merlin Chat/Rooms/memory loop.

### Public Beta Impact

Improved governance. Public Beta claims remain blocked until the product value
demo and local context flow are evidenced.

## #130 Read-Only Brain Storage Location Slice

### Date/Time

2026-05-09 08:00:28 EDT.

### Starting Commit SHA

`53a9dc7bf53a176344955af2e035d78088b41af3`

### Target Issues

- #130
- #123
- #135
- #106

### Scope

Added a read-only Wizard HQ Settings surface showing where Merlin keeps local
brain/context-related data today. This is visibility only: changing the storage
location remains locked until backend policy gates, migration validation,
rollback, and audit tests exist.

### Files Changed

- `dashboard/index.html`
- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `merlin/status_extension.py`
- `tests/dashboard-settings-policy-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `tests/test_status_extension.py`

### Protected Files Touched

- `dashboard/index.html`: Settings UI only; no new browser write controls.
- `merlin/status_extension.py`: read-only `/status/settings` manifest only; no
  execution path or setting mutation added.

### Commands Run

- `git status --short`
- `git rev-parse HEAD`
- `gh issue view 130 --json number,title,state,milestone,labels,body`
- `sed -n '1,260p' dashboard/index.html`
- `sed -n '620,1040p' dashboard/index.html`
- `sed -n '1040,1500p' dashboard/index.html`
- `sed -n '240,470p' merlin/status_extension.py`
- `sed -n '260,460p' tests/test_status_extension.py`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `.venv-test/bin/python -m pytest tests/test_status_extension.py -q`
- `git diff --check`

### Test Output Summary

- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- `.venv-test/bin/python -m pytest tests/test_status_extension.py -q`: PASS,
  29 passed.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No live browser screenshot yet; the user asked to keep coding and check in a
  few minutes. Static dashboard tests cover this read-only slice.
- No installer/package tests because installer/package behavior did not change.
- No live Qdrant/Ollama/Docker tests because `/status/settings` storage
  manifest is static/read-only and does not require live services.

### Failures Found

No failures in this slice.

### Failure Category

None.

### Root Cause Or Current Hypothesis

No failure observed.

### Fix Applied

Implemented #130 read-only visibility:

- `status_settings()` now includes a `storage` manifest with data root, optional
  dedicated brain root, optional Rooms root, local Qdrant vector store, audit
  paths, backup/export root, and locked migration state.
- Wizard HQ Settings renders a Brain Storage Location card.
- Static tests verify storage/inference distinction, default/not-configured
  copy, locked migration copy, and no unsafe browser controls.

### Regression Test Added

- `tests/dashboard-settings-policy-smoke.sh` now checks the storage card and
  locked migration copy.
- `tests/dashboard-tabs-smoke.sh` now requires the Brain Storage Location
  Settings card.
- `tests/test_status_extension.py` now verifies the read-only storage manifest
  and environment-reflected local paths.

### Follow-Up Issues Created Or Recommended

No new issue required. Future writable storage migration remains in existing
#130 / #123 / #135 scope.

### Lesson Learned

The user trust signal can be improved without adding risky controls. Showing the
brain path is useful now; moving it must wait for migration and rollback tests.

### What Not To Repeat Next Time

Do not add browser folder pickers, file moves, or storage mutation controls
before the backend policy-gated migration path exists.

### Next Recommended Step

Run broader dashboard/static tests, commit this #130 slice, push, and watch CI.
Then proceed to the #135 Rooms design/runtime slice.

### Local Trusted Beta Impact

Improved. A first-time user can now answer where Merlin's local brain/context
data is rooted and see that changing it is not yet available.

### Public Beta Impact

Improved, but Public Beta remains blocked until the product value demo, Rooms,
memory review/delete, and clean installer retest evidence are complete.

## #135 Rooms Design Surface Slice

### Date/Time

2026-05-09 08:03:16 EDT.

### Starting Commit SHA

`53a9dc7bf53a176344955af2e035d78088b41af3`

### Target Issues

- #135
- #106
- #123
- #31
- #32

### Scope

Added a read-only Wizard HQ Rooms tab and a Rooms architecture contract. This
slice defines the user/product boundary before runtime file writes: Rooms are
local chat/project containers, saved transcripts are not approved memory, and
Room context is not used until the user chooses a visible reference policy.

### Files Changed

- `.github/workflows/ci.yml`
- `dashboard/index.html`
- `docs/README.md`
- `docs/architecture/MERLIN_ROOMS.md`
- `docs/product/DASHBOARD_PRODUCT_SPEC.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`

### Protected Files Touched

- `.github/workflows/ci.yml`: added a static Rooms smoke to existing CI gates.
- `dashboard/index.html`: added read-only UI copy only; no Room write, delete,
  approval, filesystem, or shell controls.

### Commands Run

- `gh issue view 135 --json number,title,state,milestone,labels,body`
- `rg -n "Rooms|Room|Project Realm|reference policy|transcript|chat history" dashboard/index.html docs tests merlin | head -200`
- `sed -n '240,360p' docs/product/PRODUCT_NORTH_STAR.md`
- `sed -n '1,220p' tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"'`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `git diff --check`

### Test Output Summary

- First `bash tests/dashboard-rooms-smoke.sh`: FAIL due to grep regex behavior
  on the Markdown phrase `**No Room context**`.
- Retest `bash tests/dashboard-rooms-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- `bash tests/dashboard-native-chat-smoke.sh`: PASS.
- Workflow YAML parse: PASS; `workflow-yaml-ok`.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No live Room save/delete tests because writable Room runtime does not exist in
  this slice and should not be implied.
- No installer/package tests because installer/package behavior did not change.
- No browser screenshot yet; this is a static UI/design contract pass.

### Failures Found

The first Rooms smoke failed with `grep: repetition-operator operand invalid`.

### Failure Category

- Test design gap.

### Root Cause Or Current Hypothesis

The test used regex `grep -q` against a Markdown string containing `**`, which
can be interpreted as an invalid repetition pattern.

### Fix Applied

Changed the Rooms doc phrase checks to `grep -Fq` so Markdown emphasis is
matched as a fixed string.

### Retest Result

Passed after the test fix:

- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `git diff --check`

### Regression Test Added

`tests/dashboard-rooms-smoke.sh` now verifies:

- Rooms tab/page exists,
- chat surface shows Room context state,
- no silent transcript-to-memory implication,
- reference policies are visible,
- save-to-Room and memory extraction are locked/separate,
- Room deletion must account for linked memory,
- no unsafe browser controls,
- no secret-like values.

### Follow-Up Issues Created Or Recommended

Existing #135 should be split before writable runtime work:

- Room data model and local file schema.
- Save chat transcript to Room through Task API policy gate.
- Room picker and reference policy persistence.
- Local index rebuild from Room Markdown files.
- Memory proposal flow from transcript/summary.
- Delete/archive Room with linked-memory warning.

### Lesson Learned

Rooms can be made visible before they become writable. That helps product
clarity while keeping the local memory approval boundary intact.

### What Not To Repeat Next Time

Do not jump from a Rooms concept directly to browser file writes. The product
needs backend policy gates and rollback before any local transcript mutation.

### Next Recommended Step

Run the broader static suite for the combined #130/#135 working set, then
commit/push/watch CI when the user is back or after final local validation.

### Local Trusted Beta Impact

Improved. Wizard HQ now shows the intended Rooms mental model: local history,
visible storage, visible reference policy, and separate approved memory.

### Public Beta Impact

Improved UX direction, but Public Beta remains blocked until Rooms can actually
save/reload local chat history with evidence and memory review/delete is
complete.

## Wizard HQ Sovereignty Indicator Slice

### Date/Time

2026-05-09 08:04:40 EDT.

### Starting Commit SHA

`53a9dc7bf53a176344955af2e035d78088b41af3`

### Target Issues

- #106
- #122
- #130

### Scope

Added a named persistent Sovereignty Indicator to the Wizard HQ top bar. The
existing local/cloud chips already exposed raw state; this slice makes the user
trust signal explicit with Local Mode, Cloud Bridge Active, and Offline /
Warming states.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `dashboard/index.html`: visual/read-only state indicator only.

### Commands Run

- `date '+%Y-%m-%d %H:%M:%S %Z'`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `.venv-test/bin/python -m pytest tests/test_status_extension.py -q`
- `bash tests/codex-master-prompt-v2-smoke.sh`
- `bash tests/provider-connector-policy-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "workflow-yaml-ok"'`
- `git diff --check`

### Test Output Summary

- `bash tests/dashboard-first-run-smoke.sh`: PASS.
- `bash tests/dashboard-rooms-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `bash tests/dashboard-native-chat-smoke.sh`: PASS.
- `bash tests/dashboard-readiness-smoke.sh`: PASS.
- `bash tests/dashboard-model-readiness-smoke.sh`: PASS.
- `bash tests/dashboard-security-center-smoke.sh`: PASS.
- `.venv-test/bin/python -m pytest tests/test_status_extension.py -q`: PASS,
  29 passed.
- `bash tests/codex-master-prompt-v2-smoke.sh`: PASS.
- `bash tests/provider-connector-policy-smoke.sh`: PASS.
- `bash tests/release-readiness-readme-smoke.sh`: PASS.
- Workflow YAML parse: PASS; `workflow-yaml-ok`.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No installer/package tests because installer/package behavior did not change.
- No live service tests because this was a static UI/read-only status manifest
  slice.

### Failures Found

No additional failures in the combined retest.

### Failure Category

None for this slice.

### Root Cause Or Current Hypothesis

No failure observed for this slice.

### Fix Applied

Added:

- `#sovereignty-indicator` in the top bar,
- `setSovereignty()` state renderer,
- Local Mode default,
- Cloud Bridge Active state when cloud is allowed,
- Offline / Warming state when status cannot be verified,
- static first-run smoke assertions.

### Regression Test Added

`tests/dashboard-first-run-smoke.sh` now verifies the persistent Sovereignty
Indicator and all three user-facing states.

### Follow-Up Issues Created Or Recommended

No new issue. This supports the #106 Wizard HQ shell and #122 focus contract.

### Lesson Learned

Raw local/cloud chips are technically useful, but the product needs a named
trust primitive that a normal user can recognize immediately.

### What Not To Repeat Next Time

Do not bury sovereignty/local-cloud state inside engineering-only labels.

### Next Recommended Step

Commit or continue with the next tightly related product-shell slice. Writable
Room history should wait for a smaller dedicated backend task.

### Local Trusted Beta Impact

Improved first-run trust. The user can see the local/cloud mode without opening
Settings.

### Public Beta Impact

Improved UX clarity, but Public Beta remains blocked by runtime Room history,
memory review/delete, installer retest evidence, and broader onboarding polish.

## #135 Read-Only Rooms Manifest Runtime Slice

### Date/Time

2026-05-09 08:09:26 EDT.

### Starting Commit SHA

`eee78a233510846efc830985a3b99e582163f5b8`

### Target Issues

- #135
- #106
- #123

### Scope

Added the first backend-safe Rooms runtime foundation: a read-only Room manifest
module and Task API status endpoint. This lets Wizard HQ discover existing local
Room metadata without creating folders, saving transcripts, indexing content,
extracting memory, or exposing browser file controls.

### Files Changed

- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `merlin/room_store.py`
- `merlin/status_extension.py`
- `tests/dashboard-rooms-smoke.sh`
- `tests/test_room_store.py`
- `tests/test_status_extension.py`

### Protected Files Touched

- `dashboard/index.html`: read-only manifest display only.
- `merlin/status_extension.py`: added `GET /status/rooms`; no writes or
  execution actions.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py -q`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `git diff --check`

### Test Output Summary

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py -q`: PASS,
  34 passed.
- `bash tests/dashboard-rooms-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- `bash tests/dashboard-native-chat-smoke.sh`: PASS.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `bash tests/dashboard-first-run-smoke.sh`: PASS.
- `bash tests/dashboard-readiness-smoke.sh`: PASS.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No live browser screenshot yet; this is backend/static runtime plumbing.
- No save-to-Room live test because writable Room storage is intentionally out
  of scope for this slice.
- No installer/package tests because installer/package behavior did not change.

### Failures Found

No failures in this slice.

### Failure Category

None.

### Root Cause Or Current Hypothesis

No failure observed.

### Fix Applied

Added:

- `merlin/room_store.py` read-only Room manifest helper,
- `GET /status/rooms`,
- Wizard HQ Rooms manifest panel,
- unit tests for default no-context manifest and metadata discovery,
- static smoke checks that the dashboard loads `/status/rooms` while remaining
  non-writing.

### Regression Test Added

- `tests/test_room_store.py`
- `tests/test_status_extension.py::test_status_rooms_returns_read_only_manifest`
- expanded `tests/dashboard-rooms-smoke.sh`

### Follow-Up Issues Created Or Recommended

No new issue created yet. The next #135 implementation issue should be:

**Title:** `v3.1 Rooms: save Merlin Chat transcript through Task API gate`

Scope should include local transcript file write, explicit user action, audit
record, rollback/error handling, and no memory extraction by default.

### Lesson Learned

Rooms can become real incrementally. A read-only manifest creates a stable
contract for UI and tests before any file mutation exists.

### What Not To Repeat Next Time

Do not implement transcript writes in the browser. The save path must be a
backend Task API action with policy/audit coverage.

### Next Recommended Step

Commit/push/watch CI for the read-only manifest slice. Then split writable
save-to-Room into a focused issue before coding it.

### Local Trusted Beta Impact

Improved. Merlin can now expose an honest, test-covered Room runtime state
instead of only static product copy.

### Public Beta Impact

Improved foundation, but Public Beta remains blocked until users can actually
save/reload Rooms, review/delete memory, and pass clean install evidence.

## #135 Save Room Transcript Through Task API Gate

### Date/Time

2026-05-09 08:16:25 EDT.

### Starting Commit SHA

`74c8edacc14b158c1f95b1f2e5566d70b161849a`

### Target Issues

- #135
- #106
- #123
- #31
- #32

### Scope

Added a backend-only save-to-Room transcript path:

```text
POST /rooms/transcripts
```

The endpoint requires `approval_id`, validates a safe Room slug, writes a local
Markdown transcript, and writes audit metadata without raw transcript text. It
does not extract memory, write Qdrant memory, add browser file controls, or
enable cloud sync.

### Files Changed

- `docs/architecture/MERLIN_ROOMS.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `dashboard/index.html`
- `merlin/room_store.py`
- `merlin/task_endpoint.py`
- `tests/dashboard-rooms-smoke.sh`
- `tests/test_room_store.py`
- `tests/test_status_extension.py`
- `tests/test_task_endpoint.py`

### Protected Files Touched

- `merlin/task_endpoint.py`: added policy-bound Room transcript endpoint on
  execution-aware port 8766.
- `dashboard/index.html`: copy only; still no browser save/delete controls.

### Commands Run

- `sed -n '1,220p' docs/CODEX_MASTER_PROMPT_V2.md`
- `sed -n '1,180p' docs/operations/FAILURE_LEARNING_LOOP.md`
- `sed -n '1,180p' docs/security/PRIVACY_AND_MEMORY_MODEL.md`
- `sed -n '1,160p' docs/architecture/MERLIN_ROOMS.md`
- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_task_endpoint.py -q`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `git diff --check`
- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py tests/test_task_endpoint.py -q`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/provider-connector-policy-smoke.sh`
- `bash tests/codex-master-prompt-v2-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`

### Test Output Summary

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_task_endpoint.py -q`: PASS,
  20 passed.
- First `bash tests/dashboard-rooms-smoke.sh`: FAIL due to stale doc-smoke
  expectation after moving save-to-Room from future work to current backend
  endpoint.
- Retest `bash tests/dashboard-rooms-smoke.sh`: PASS.
- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py tests/test_task_endpoint.py -q`: PASS,
  50 passed.
- `bash tests/dashboard-native-chat-smoke.sh`: PASS.
- `bash tests/dashboard-tabs-smoke.sh`: PASS.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS.
- `bash tests/dashboard-first-run-smoke.sh`: PASS.
- `bash tests/dashboard-readiness-smoke.sh`: PASS.
- `bash tests/provider-connector-policy-smoke.sh`: PASS.
- `bash tests/codex-master-prompt-v2-smoke.sh`: PASS.
- `bash tests/release-readiness-readme-smoke.sh`: PASS.
- `bash tests/dashboard-security-center-smoke.sh`: PASS.
- `git diff --check`: PASS.

### Tests Skipped And Why

- No live browser test because the dashboard still has no save-to-Room control.
- No installer/package tests because installer/package behavior did not change.
- No live Qdrant test because audit writes are best-effort and mocked in unit
  tests for this endpoint.

### Failures Found

The Rooms smoke expected `Save chat transcript to Room through Task API policy
gate` in the future-work section after the endpoint had moved into the current
implementation section.

### Failure Category

- Documentation mismatch.
- Test design gap.

### Root Cause Or Current Hypothesis

The architecture doc was correctly updated to describe the current endpoint,
but the static smoke still checked the old future-work phrase.

### Fix Applied

Updated `tests/dashboard-rooms-smoke.sh` to assert the current endpoint contract:

- `POST http://localhost:8766/rooms/transcripts`
- endpoint requires `approval_id`

### Retest Result

Passed after the smoke update:

- `bash tests/dashboard-rooms-smoke.sh`
- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py tests/test_task_endpoint.py -q`
- all related dashboard/static smokes listed above

### Regression Test Added

- `tests/test_room_store.py` now covers local transcript Markdown writes,
  approval requirement, unsafe Room ID rejection, and no memory extraction.
- `tests/test_task_endpoint.py` now covers `POST /rooms/transcripts` approval
  failure, local file write, audit metadata without raw transcript text, no
  memory write, and unsafe Room ID rejection.
- `tests/dashboard-rooms-smoke.sh` now checks the current backend endpoint
  contract and keeps browser controls absent.

### Follow-Up Issues Created Or Recommended

Next focused #135 child issue:

**Title:** `v3.1 Rooms: Wizard HQ save-to-Room approval card`

Scope:

- UI card after a Merlin Chat response.
- User explicitly chooses Save to Room.
- Calls `POST /rooms/transcripts` only after approval id exists.
- Shows transcript saved, memory extraction not performed.
- No memory write and no cloud sync.

### Lesson Learned

When a design item becomes implemented, static smokes must move from future
language checks to current endpoint checks in the same patch.

### What Not To Repeat Next Time

Do not leave tests asserting old roadmap copy after promoting a capability into
current implementation.

### Next Recommended Step

Commit/push/watch CI. Then build the Wizard HQ save-to-Room approval card as a
separate UI slice, still without memory extraction by default.

### Local Trusted Beta Impact

Improved. Merlin can now persist a local chat transcript to a Room through a
backend approval boundary while keeping reusable memory separate.

### Public Beta Impact

Improved foundation, but Public Beta remains blocked until the UI flow,
Room reload/history display, memory review/delete, and clean installer evidence
are complete.

## #106/#135 Merlin Chat Product Shell Polish

### Date/Time

2026-05-09 EDT

### Branch

`main`

### Starting Commit SHA

`1c8295ab8f58073b4ac901aa8694e6ba3ef051bc`

### Ending Commit SHA

Pending commit for this UI slice.

### Target Issues

- #106 Wizard HQ Product Shell
- #135 Merlin Rooms
- #122 Product Focus Cut

### Scope

Apply the safe parts of the local Merlin chat concept reference to Wizard HQ:
cleaner centered Merlin chat, starter prompts, message-thread layout, and local
source/proof chips. This is UI-only. It does not add browser writes, direct model
calls, external UI dependencies, cloud behavior, or a second POST.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, policy engine, router, memory manager, status API, or Task
API behavior changed in this slice.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `git diff --check`

### Test Output Summary

- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `Dashboard Merlin status smoke test passed`
- `PASS: Wizard HQ readiness surface is honest and read-only`
- `PASS: Merlin Rooms surface is local, explicit, and non-writing`
- `PASS: Wizard HQ tab shell is Merlin-native and read-only`
- `PASS: Wizard HQ Settings is backend-manifested and policy-gated`
- `PASS: Wizard HQ Chat home product clarity is safe and read-only`
- `git diff --check` returned clean.

### Tests Skipped And Why

Live browser and live service checks are not required for this static UI-only
slice. They remain appropriate before a clean local beta installer pass.

### Failures Found

None in this UI slice.

### Failure Category

No failure observed.

### Root Cause Or Current Hypothesis

No current failure observed in this slice yet.

### Fix Applied

No failure fix required.

### Retest Result

All focused dashboard/static smokes passed after the UI changes.

### Regression Test Added

`tests/dashboard-native-chat-smoke.sh` now checks for:

- safe starter prompts,
- message-thread layout,
- local/source proof line,
- memory approval copy,
- no external UI CDNs,
- still exactly one browser POST to Merlin Task API `/task`.

### Follow-Up Issues Created Or Recommended

Create a focused child issue for the next functional step:

**Title:** `v3.1 Wizard HQ: save current Merlin Chat response to Room`

Acceptance criteria:

- User sees a Save to Room card only after a Merlin response.
- UI does not create an approval id itself.
- Backend call remains `POST /rooms/transcripts`.
- Memory extraction remains separate and requires approve/edit/deny.
- Static smoke confirms no direct browser file controls and no second unsafe
  execution path.

### Lesson Learned

Use design references as product direction, not as source code. Keep the parts
that strengthen the local-first chat experience and reject anything that adds
external dependencies, fake actions, or browser-side authority.

### What Not To Repeat Next Time

Do not copy demo chat controls such as web search, share, live agents, or memory
toggles until Merlin has real policy-gated backend support for each action.

### Next Recommended Step

Validate this UI slice, commit it, push it, and watch CI. Then proceed to the
explicit save-to-Room approval card.

### Local Trusted Beta Impact

Improves first-use trust and product clarity: Wizard HQ reads more like Merlin's
own chat surface instead of a technical status page with a prompt box.

### Public Beta Impact

Positive but not sufficient. Public Beta still requires clean installer evidence,
Room history reload, approved memory review/delete, and release/onboarding proof.

## #135 Room History Metadata Visibility

### Date/Time

2026-05-09 EDT

### Branch

`main`

### Starting Commit SHA

`ae52cea654c0434a01fb8b82cc0cdfd53ac47680`

### Ending Commit SHA

Pending commit for this Room metadata slice.

### Target Issues

- #135 Merlin Rooms
- #106 Wizard HQ Product Shell
- #122 Product Focus Cut

### Scope

Expose already-saved Room transcript metadata through the read-only Rooms
manifest and render it in Wizard HQ. Metadata includes transcript id, local path,
file size, and modified timestamp only. Raw transcript text remains local and is
not loaded into the manifest.

### Files Changed

- `merlin/room_store.py`
- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `tests/test_room_store.py`
- `tests/test_status_extension.py`
- `tests/dashboard-rooms-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/room_store.py`: read-only manifest helper extended with transcript
  metadata. No policy, router, installer, or execution boundary changed.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_status_extension.py -q`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `git diff --check`

### Test Output Summary

- `38 passed in 3.02s`
- `PASS: Merlin Rooms surface is local, explicit, and non-writing`
- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `git diff --check` returned clean.

### Tests Skipped And Why

Live service checks are not required for this offline metadata/static slice.

### Failures Found

None.

### Failure Category

No failure observed.

### Root Cause Or Current Hypothesis

No failure observed yet.

### Fix Applied

No failure fix required.

### Retest Result

All focused Room metadata/static checks passed.

### Regression Test Added

- transcript metadata is returned without raw content,
- status endpoint includes transcript metadata,
- dashboard renders "Latest transcripts" and "raw hidden",
- browser still has only one Task API POST.

### Follow-Up Issues Created Or Recommended

Next issue remains the real approval-card flow:

**Title:** `v3.1 Wizard HQ: save current Merlin Chat response to Room`

This should wait for a real approval id / approve-edit-deny flow rather than
inventing browser authority.

### Lesson Learned

When a write path exists but the UI approval flow is not ready, show read-only
evidence of saved local state first. That improves product clarity without
weakening governance.

### What Not To Repeat Next Time

Do not create a browser Save button until the policy-gated approval lifecycle is
real and testable.

### Next Recommended Step

Validate and commit this metadata visibility slice.

### Local Trusted Beta Impact

Improves: users can see that local Room history exists without exposing raw
transcripts or implying approved memory.

### Public Beta Impact

Positive foundation. Public Beta remains blocked on the full save/reload/review
Room flow and clean install evidence.

## #135 Room Transcript Approval Lifecycle

### Date/Time

2026-05-09 EDT

### Branch

`main`

### Starting Commit SHA

`e2e04a44ff3e5fff2b99dbac8e84db2ed785a2a6`

### Ending Commit SHA

Pending commit for this approval lifecycle slice.

### Target Issues

- #135 Merlin Rooms
- #31 Memory Approval Flow boundary
- #122 Product Focus Cut

### Scope

Add a real backend approval lifecycle for Room transcript saves before exposing
browser controls. The lifecycle creates a redacted approval request, records an
approve/deny decision, and requires the final save request to match the approved
payload hash exactly.

### Files Changed

- `merlin/approval_store.py`
- `merlin/task_endpoint.py`
- `docs/architecture/MERLIN_ROOMS.md`
- `tests/test_task_endpoint.py`
- `tests/dashboard-rooms-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/task_endpoint.py`: adds Task API approval endpoints and strengthens
  `POST /rooms/transcripts`.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_task_endpoint.py tests/test_room_store.py tests/test_status_extension.py -q`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `git diff --check`

### Test Output Summary

- `52 passed in 3.29s`
- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `PASS: Merlin Rooms surface is local, explicit, and non-writing`
- `git diff --check` returned clean.

### Tests Skipped And Why

No live service or browser test was required for this backend/offline approval
slice. Full UI/browser validation belongs to the later approval-card slice.

### Failures Found

None.

### Failure Category

No failure observed.

### Root Cause Or Current Hypothesis

No failure observed.

### Fix Applied

No failure fix required.

### Retest Result

All focused endpoint, Room, status, and dashboard static tests passed.

### Regression Test Added

- Room transcript save now requires an approved approval id.
- Pending approval cannot write a Room transcript.
- Approved but payload-mismatched approval cannot write a Room transcript.
- Approval proposal response does not contain raw user input.
- Rooms architecture smoke checks the approval lifecycle endpoints.

### Follow-Up Issues Created Or Recommended

Next focused issue:

**Title:** `v3.1 Wizard HQ: Room transcript approval card`

Acceptance criteria:

- UI proposes a Room transcript save after a Merlin response.
- User can approve or deny through Task API approval endpoints.
- UI calls `POST /rooms/transcripts` only after an approved matching approval id.
- No raw transcript appears in approval logs.
- Static smokes allow only these specific Task API approval/save POST paths.

### Lesson Learned

The approval id alone was not enough. It must be bound to the exact transcript
payload hash so a stale or generic approval cannot authorize a different local
file write.

### What Not To Repeat Next Time

Do not add browser save controls until the backend can prove the approval
matches the action payload.

### Next Recommended Step

Commit and push this backend approval lifecycle, then build the narrow Wizard HQ
approval card against these endpoints.

### Local Trusted Beta Impact

Improves. Merlin now has a stronger save-to-Room trust boundary: local history
can be saved only after a specific approved payload.

### Public Beta Impact

Positive foundation. Public Beta still needs the complete user-facing approval
card, Room reload/history UX, memory review/delete, and clean installer evidence.

## #106 Merlin Chat Front Page Orb Shell

### Date/Time

2026-05-09 EDT

### Branch

`main`

### Starting Commit SHA

`3f590f067b03c54e49213ae7700466f3a1476741`

### Ending Commit SHA

Pending commit for this front-page UI slice.

### Target Issues

- #106 Wizard HQ Product Shell
- #122 Product Focus Cut
- #135 Merlin Rooms

### Scope

Adapt the safe parts of `/Users/kevinmedeiros/Downloads/merlin-chat-2.html`
into Wizard HQ:

- local Merlin orb center mark,
- premium chat workspace shell,
- local sidebar/context rail,
- mode/readiness strip,
- safe starter prompts,
- premium composer framing.

Rejected from the reference:

- Google Fonts / external font calls,
- external S3 image dependency,
- fake demo responses,
- web search, file attach, memory toggle, share, and Round Table buttons,
- direct model backend calls,
- browser-side save/write controls.

### Files Changed

- `dashboard/index.html`
- `dashboard/assets/merlin-orb.png`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, policy, memory, router, status API, or Task API behavior
changed in this UI slice.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`

### Test Output Summary

Initial pass:

- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `PASS: Wizard HQ Chat home product clarity is safe and read-only`
- `PASS: Wizard HQ tab shell is Merlin-native and read-only`
- `git diff --check` returned clean.
- `PASS: Merlin Rooms surface is local, explicit, and non-writing`
- `PASS: Wizard HQ Settings is backend-manifested and policy-gated`
- `PASS: Wizard HQ model readiness UX is explicit and no-download`

One failure was found and fixed:

- `bash tests/dashboard-readiness-smoke.sh` failed with
  `FAIL: dashboard contains fake/static readiness language`

### Tests Skipped And Why

Live browser screenshot is not required for this static UI slice, but should be
run before installer/local beta evidence signoff.

### Failures Found

The new local "New conversation" helper copy said:

`Merlin is ready for a fresh local question.`

### Failure Category

- UX/readiness confusion.
- CI/static smoke gap caught successfully.

### Root Cause Or Current Hypothesis

The copy used the word `ready` as conversational language, but the dashboard
readiness contract reserves readiness claims for verified service state.

### Fix Applied

Changed the copy to:

`Start a fresh local question here. Nothing was saved, deleted, or written to memory.`

### Retest Result

Passed after copy fix:

- `PASS: Wizard HQ readiness surface is honest and read-only`
- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `PASS: Wizard HQ Chat home product clarity is safe and read-only`
- `PASS: Wizard HQ tab shell is Merlin-native and read-only`
- `PASS: Merlin Rooms surface is local, explicit, and non-writing`
- `PASS: Wizard HQ Settings is backend-manifested and policy-gated`
- `PASS: Wizard HQ model readiness UX is explicit and no-download`
- `git diff --check` returned clean.

### Regression Test Added

Existing `tests/dashboard-readiness-smoke.sh` already caught this pattern. New
chat/front-page smoke checks verify:

- local orb asset is referenced and exists,
- premium Merlin front shell exists,
- no external UI dependencies,
- browser still has exactly one Task API POST.

### Follow-Up Issues Created Or Recommended

Next focused issue:

**Title:** `v3.1 Wizard HQ: browser-validated Merlin Chat screenshots`

Scope:

- launch Wizard HQ locally,
- capture desktop/mobile screenshots,
- verify orb, sidebar, composer, and tab layout do not overlap,
- verify no browser console errors,
- keep screenshots in release evidence assets.

### Lesson Learned

Readiness language is a protected product contract. Even friendly chat copy
must not use "Merlin is ready" unless the runtime readiness state proves it.

### What Not To Repeat Next Time

Do not use static "ready" wording in UI helper copy. Use neutral action copy
unless it is bound to live service checks.

### Next Recommended Step

Retest the dashboard smokes, commit, push, and watch CI.

### Local Trusted Beta Impact

Improves first impression: Wizard HQ now presents Merlin as the primary chat
product surface with a local identity asset and cleaner user path.

### Public Beta Impact

Positive UI foundation. Public Beta still needs browser screenshot evidence,
Room approval-card UX, memory review/delete, and clean installer evidence.

---

## 2026-05-09 — Wizard HQ Merlin M Browser Mark

### Date/Time

2026-05-09 morning, America/New_York.

### Branch

`main`

### Starting Commit SHA

`876d217` (`feat(dashboard): add Merlin orb front page shell`)

### Ending Commit SHA

Pending commit.

### Target Issues

- #106 Wizard HQ Product Shell
- #122 Product Focus Cut
- #134 Product Value Checkpoint

### Scope

Add the finalized Merlin M sigil as a local browser/corner identity asset for
Wizard HQ. The center Merlin orb remains the chat identity; the M sigil becomes
the favicon, Apple touch icon, and top-left dashboard brand mark.

### Files Changed

- `dashboard/assets/merlin-m-sigil.png`
- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package script, policy, memory, router, status API, or Task
API behavior changed.

### Asset Source

Local user-provided image:

`/Users/kevinmedeiros/Downloads/Merlin_M_sigil_—_teal_plasma_trademark_mark_on_black.png`

Copied into the repo as:

`dashboard/assets/merlin-m-sigil.png`

### Commands Run

- `shasum -a 256 dashboard/assets/merlin-m-sigil.png`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `git diff --check`

### Test Output Summary

- `5acd0c17c10c78e3b9c8466d9fa36acb3b68bbd82f512a599ebefc2c634468f3  dashboard/assets/merlin-m-sigil.png`
- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `PASS: Wizard HQ Chat home product clarity is safe and read-only`
- `PASS: Wizard HQ tab shell is Merlin-native and read-only`
- `PASS: Wizard HQ readiness surface is honest and read-only`
- `git diff --check` returned clean.

### Tests Skipped And Why

Live browser screenshot retest skipped for this static asset wiring slice. It
should be captured with the broader Wizard HQ visual QA pass after the next
front-page polish round.

### Failures Found

None in this slice.

### Failure Category

None.

### Root Cause Or Current Hypothesis

No failure diagnosed.

### Fix Applied

No failure fix required.

### Retest Result

All focused dashboard smokes passed on first run after the asset wiring.

### Regression Test Added

Static dashboard smokes now assert:

- `assets/merlin-m-sigil.png` exists locally,
- Wizard HQ declares the M sigil as browser favicon,
- Wizard HQ declares the M sigil as Apple touch icon,
- Wizard HQ uses the M sigil as the top-left corner mark.

### Follow-Up Issues Created Or Recommended

Recommended follow-up:

**Title:** `v3.1 Wizard HQ: make Merlin orb feel alive without fake readiness`

Scope:

- add subtle orb motion/pulse on the Merlin Chat front page,
- bind motion/state language to actual readiness or chat activity where possible,
- respect `prefers-reduced-motion`,
- keep center orb as the Merlin chat identity and M sigil as the browser/corner
  product mark,
- capture browser screenshots after implementation.

Browser screenshot validation remains part of the broader Wizard HQ visual QA
follow-up.

### Lesson Learned

Brand identity has two distinct jobs in the dashboard: the M sigil identifies
the product/browser shell, while the orb/face identifies the Merlin chat brain.

### What Not To Repeat Next Time

Do not replace the central chat face with the corner logo. They serve different
UX roles.

### Next Recommended Step

Run focused dashboard smokes, commit, push, and watch CI.

### Local Trusted Beta Impact

Improves first-run product ownership: browser chrome and dashboard header now
look like Merlin AI instead of a generic local dashboard.

### Public Beta Impact

Positive visual identity foundation. Public Beta still requires full clean
installer retest and browser screenshot evidence after UI polish stabilizes.

---

## 2026-05-09 — Wizard HQ Living Merlin Orb

### Date/Time

2026-05-09 morning, America/New_York.

### Branch

`main`

### Starting Commit SHA

`4753ded` (`feat(dashboard): add Merlin M browser mark`)

### Ending Commit SHA

Pending commit.

### Target Issues

- #106 Wizard HQ Product Shell
- #122 Product Focus Cut
- #134 Product Value Checkpoint

### Scope

Make the central Merlin Chat orb feel alive with subtle local CSS motion while
preserving the readiness contract. The animation is a visual presence layer,
not a service-ready signal.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package script, policy, memory, router, status API, or Task
API behavior changed.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `git diff --check`

### Test Output Summary

- `PASS: Wizard HQ native Merlin Chat is policy-gated through Task API`
- `PASS: Wizard HQ Chat home product clarity is safe and read-only`
- `PASS: Wizard HQ tab shell is Merlin-native and read-only`
- `PASS: Wizard HQ readiness surface is honest and read-only`
- `git diff --check` returned clean.

### Tests Skipped And Why

Live browser screenshot retest skipped for this static CSS motion slice. It
should be captured with the broader Wizard HQ visual QA pass after the next
front-page polish round.

### Failures Found

None in this slice.

### Failure Category

None.

### Root Cause Or Current Hypothesis

No failure diagnosed.

### Fix Applied

No failure fix required.

### Retest Result

All focused dashboard smokes passed on first run after the motion wiring.

### Regression Test Added

Static dashboard smokes now assert:

- the Merlin orb has a dedicated `merlin-orb-stage`,
- the subtle breathe/halo animation keyframes exist,
- the animation respects `prefers-reduced-motion: reduce`.

### Follow-Up Issues Created Or Recommended

No separate follow-up needed for the CSS motion slice. Browser screenshot
validation remains required before Local Trusted Beta visual signoff.

### Lesson Learned

Motion is part of product trust. It can make Merlin feel alive, but it must not
claim readiness, imply hidden work, or ignore accessibility preferences.

### What Not To Repeat Next Time

Do not use animation as a substitute for real status. Readiness still comes
from the status/task API checks and documented service state.

### Next Recommended Step

Run focused dashboard smokes, commit, push, and watch CI.

### Local Trusted Beta Impact

Improves first impression and makes the Merlin Chat page feel more like a
premium product while staying local-only and read-only.

### Public Beta Impact

Positive UI polish foundation. Public Beta still requires live browser
screenshots, installer retest, and memory/Room approval UX evidence.

---

## 2026-05-09 — Merlin Chat UI Direction Integration

### Date/Time

2026-05-09 morning, America/New_York.

### Branch

`main`

### Starting Commit SHA

`fd872f3` (`feat(dashboard): animate Merlin orb safely`)

### Ending Commit SHA

Pending commit.

### Target Issues

- #106 Wizard HQ Product Shell
- #122 Product Focus Cut
- #134 Product Value Checkpoint

### Scope

Adapt the user-provided Merlin Chat standalone HTML direction into the existing
Wizard HQ Chat tab without turning it into a separate product page yet.

Integrated now:

- cleaner conversation rail,
- compact Merlin brand treatment,
- premium composer tool rail,
- Fast / Smart / Deep mode selector,
- selected UI mode shown in response metadata,
- first-load scroll reset so Chat opens on the Merlin face/orb instead of a
  retained previous scroll position,
- local-only safety copy preserved.

Preserved constraints:

- no Google Fonts or external UI dependencies,
- no fake canned Merlin replies,
- no direct LiteLLM/Ollama browser calls,
- no browser approval/write/shell controls,
- exactly one browser POST path: Merlin Task API `/task`.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `docs/product/DASHBOARD_UI_SPEC.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package script, policy, memory, router, status API, or Task
API behavior changed.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `git diff --check`
- `curl -fsS --max-time 5 http://127.0.0.1:8888/ -o docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-chat-ui-integration-snapshot.html`
- `open -a Safari 'http://127.0.0.1:8888/?chat-ui=20260509#chat'`
- `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-chat-ui-integration-top.png`

Earlier browser QA commands in this pass:

- `lsof -nP -iTCP:8888 -sTCP:LISTEN`
- `curl -fsS --max-time 5 http://127.0.0.1:8888/`
- `docker compose ps`
- `docker compose logs --tail=80 dashboard`
- `bash scripts/status.sh`
- `open -a Safari http://127.0.0.1:8888`
- `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-living-orb-browser.png`
- Safari automation attempts with `osascript`

### Test Output Summary

- `bash tests/dashboard-native-chat-smoke.sh`: PASS — Wizard HQ native Merlin
  Chat remains policy-gated through Task API.
- `bash tests/dashboard-first-run-smoke.sh`: PASS — Chat home product clarity is
  safe and read-only.
- `bash tests/dashboard-tabs-smoke.sh`: PASS — tab shell remains Merlin-native
  and read-only.
- `bash tests/dashboard-readiness-smoke.sh`: PASS — readiness surface remains
  honest and read-only.
- `git diff --check`: PASS — no whitespace errors.
- Live HTTP snapshot: PASS — dashboard served from `127.0.0.1:8888`.
- Browser screenshot: captured
  `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-chat-ui-integration-top.png`.

### Tests Skipped And Why

No live browser DOM-click automation was run. Safari JavaScript automation is
blocked in this local environment, so this slice used static smokes, live HTTP
checks, and screenshot evidence instead.

### Failures Found

Two browser-QA failures were found before this UI integration:

1. Initial `curl` to `127.0.0.1:8888` failed even though `lsof` showed Docker
   listening. Follow-up `docker compose ps`, dashboard logs, `scripts/status.sh`,
   and later `curl` checks confirmed Wizard HQ was reachable. Current hypothesis:
   transient Docker/port readiness timing.
2. Safari could not run JavaScript from Apple Events or from Smart Search field,
   even after enabling developer features through preferences. Safari page DOM
   automation is not reliable in this local test environment.

### Failure Category

- Wizard HQ/dashboard
- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

The transient `curl` failure was likely local Docker port readiness timing. The
Safari automation failure appears to be a browser configuration / macOS
automation limitation, not a Merlin defect.

### Fix Applied

No product fix applied for the Safari automation limitation. The QA approach
shifted to static smoke tests, direct HTTP checks, and screenshots.

Product-side UI fix applied from screenshot review:

- disabled browser scroll restoration for Wizard HQ,
- reset page and Chat scroller position when tabs are selected.

### Retest Result

PASS for the UI integration slice. Focused dashboard smokes passed after the
scroll reset and mode selector integration.

### Regression Test Added

Static dashboard smokes now assert:

- composer tool rail exists,
- mode selector exists in the composer,
- Fast / Smart / Deep choices exist,
- selected mode state is tracked,
- response metadata shows the selected UI mode,
- honest mode-to-router copy explains that Merlin router still chooses the
  actual local model.

### Follow-Up Issues Created Or Recommended

Recommended:

**Title:** `v3.1 QA: add reliable browser automation path for Wizard HQ`

Scope:

- choose one supported local browser automation path,
- avoid Safari-only Apple Events blockers,
- capture Chat / Rooms / Brains / Settings screenshots,
- verify no overlap at split-screen, desktop, and mobile widths.

### Lesson Learned

The standalone chat concept is the correct product direction, but it must be
integrated into Wizard HQ through the existing Task API and safety contracts.
Mode controls should not pretend to select models until the backend supports an
audited mode hint.

### What Not To Repeat Next Time

Do not rely on Safari JavaScript automation for Wizard HQ QA unless the required
Safari Developer settings are confirmed first.

### Next Recommended Step

Commit, push, and watch CI. Next product slice should wire the same Chat shell
into Room-backed local transcript storage only after the memory approval/delete
contracts stay intact.

### Local Trusted Beta Impact

Improves the first usable Merlin Chat impression while preserving local-first
and approval-gated boundaries.

### Public Beta Impact

Positive UX foundation. Public Beta still requires clean installer retest,
reliable browser visual QA, and memory/Room approval UX evidence.

---

## 2026-05-09 — Room-Aware Chat Save UX

### Date/Time

2026-05-09 10:29:29 EDT.

### Branch

`main`

### Starting Commit SHA

`7c21c75` (`feat(dashboard): integrate Merlin chat shell direction`)

### Ending Commit SHA

Pending commit.

### Target Issues

- #135 Merlin Rooms for local chat history and scoped context
- #106 Wizard HQ Product Shell
- #122 Product Focus Cut
- #134 Product Value Checkpoint

### Scope

Wire the Merlin Chat surface to the existing Room transcript approval/save
backend for the latest completed Merlin response.

Implemented:

- "Save latest chat to Room" panel in Merlin Chat,
- explicit prepare step through `POST /approvals/room-transcript`,
- explicit allow step through `POST /approvals/{approval_id}/approve`,
- approved local transcript write through `POST /rooms/transcripts`,
- default Room target `merlin-build` / `Merlin Build`,
- UI copy that saved transcripts are local Markdown history, not approved
  memory,
- Room manifest refresh after a save,
- duplicated local brain / Room context status moved into the side panel,
- pre-response "Merlin standing by" bubble removed so the chat center starts
  clean with Merlin image, suggestion options, and composer.

Not implemented:

- arbitrary Room picker,
- user-selected filesystem path changes,
- Room indexing or context injection,
- memory extraction from transcripts,
- delete/archive Room.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-tabs-smoke.sh`
- `tests/dashboard-readiness-smoke.sh`
- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-model-readiness-smoke.sh`
- `tests/dashboard-settings-policy-smoke.sh`
- `docs/product/DASHBOARD_UI_SPEC.md`
- `docs/architecture/MERLIN_ROOMS.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package script, router, memory manager, policy engine, or
Task API backend behavior changed.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `.venv-test/bin/python -m pytest tests/test_task_endpoint.py`
- `git diff --check`
- `curl -fsS --max-time 5 http://127.0.0.1:8888/ -o docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-room-save-ux-snapshot.html`
- `open -a Safari 'http://127.0.0.1:8888/?room-save=20260509#chat'`
- `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-room-save-ux.png`
- `curl -fsS --max-time 5 http://127.0.0.1:8888/ -o docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-clean-chat-center-snapshot.html`
- `open -a Safari 'http://127.0.0.1:8888/?clean-center=20260509#chat'`
- `screencapture -x docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-clean-chat-center.png`

### Test Output Summary

- `bash tests/dashboard-native-chat-smoke.sh`: PASS — Wizard HQ native Merlin
  Chat is policy-gated through Task API.
- `bash tests/dashboard-first-run-smoke.sh`: PASS — Chat home product clarity
  remains safe and read-only for startup/setup surfaces.
- `bash tests/dashboard-tabs-smoke.sh`: PASS after test contract update.
- `bash tests/dashboard-readiness-smoke.sh`: PASS after test contract update.
- `bash tests/dashboard-rooms-smoke.sh`: PASS after test contract update.
- `bash tests/dashboard-model-readiness-smoke.sh`: PASS after test contract update.
- `bash tests/dashboard-settings-policy-smoke.sh`: PASS after test contract update.
- `.venv-test/bin/python -m pytest tests/test_task_endpoint.py`: PASS, 14 passed
  in 1.84 seconds on final run.
- `git diff --check`: PASS.
- Live dashboard HTTP snapshot: PASS.
- Browser screenshot captured:
  `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-room-save-ux.png`.
- Clean-center browser screenshot captured:
  `docs/release/evidence/assets/2026-05-08-wizard-hq/wizard-hq-clean-chat-center.png`.

### Tests Skipped And Why

Live browser click automation was skipped because Safari JavaScript automation
is still blocked in this local environment. The screenshot captures the Chat
surface, but not the post-response save panel because that requires a successful
Merlin response and click sequence. Backend Room approval/save behavior was
covered by `tests/test_task_endpoint.py`; dashboard wiring was covered by static
smokes.

### Failures Found

Five static smokes failed across the local and CI validation pass:

- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`

Both failed with:

```text
FAIL: dashboard must have exactly one POST: Merlin Task API /task
```

CI run `25603682306` failed in `Static smoke tests — profiles, memory,
release safety` for the same stale dashboard smoke contract after commit
`aaf8a42`.

### Failure Category

- Test design gap
- Roadmap/governance drift

### Root Cause Or Current Hypothesis

The old dashboard test contract assumed Merlin Chat would have exactly one
browser POST forever. #135 already has audited backend Room transcript approval
and save endpoints, so the correct contract is now narrower and more accurate:
the browser may only use the Task API chat POST plus approved Room transcript
POSTs. It still must not call model backends, cloud APIs, shell routes, model
downloads, or memory writes directly.

### Fix Applied

Updated the dashboard smoke tests to allow:

- `POST /task`,
- `POST /approvals/room-transcript`,
- `POST /approvals/{approval_id}/approve`,
- `POST /approvals/{approval_id}/deny`,
- `POST /rooms/transcripts`.

The tests still assert:

- no direct model backend calls,
- no external UI dependencies,
- no browser shell controls,
- no model downloads,
- no approved memory write from Room save,
- Room transcript save copy remains explicit.

### Retest Result

PASS after test contract update.

Follow-up UI retest also moved duplicated readiness/Room status into the side
panel and removed the empty pre-response artifact between the starter options
and composer.

### Regression Tests Added

Static dashboard smokes now assert:

- Room transcript save surface exists,
- Room approval request flow exists,
- explicit local Room save flow exists,
- approved Room transcript endpoint is referenced,
- Room save reports `memory not written`,
- broader tab/readiness tests allow only the policy-gated Room save expansion.
- Merlin Chat starts with an empty response area instead of a duplicate
  pre-response status bubble between the image and composer.

Existing backend tests continue to assert:

- transcript save requires approval id,
- pending/mismatched approvals are rejected,
- unsafe Room ids are rejected,
- local transcript save writes Markdown without writing memory,
- audit metadata does not include raw transcript text.

### Follow-Up Issues Created Or Recommended

Recommended:

**Title:** `v3.1 Rooms: add Room picker and local storage path migration tests`

Scope:

- replace default-only `merlin-build` save target with a Room picker,
- keep reference policy default at no Room context,
- test local path migration before allowing user-selected path changes,
- keep memory extraction as a separate approve/edit/deny flow.

### Lesson Learned

Guardrails should encode allowed boundaries, not stale implementation counts.
The old "one POST" rule was useful while Chat only talked to `/task`; after #135
backend approval endpoints existed, it became a false blocker. The safer rule is
an explicit allowlist of policy-gated local Task API paths.

### What Not To Repeat Next Time

Do not add new browser POSTs without updating the static tests to name the exact
allowed endpoints and the forbidden behaviors that remain blocked.

### Next Recommended Step

Run final focused tests, `git diff --check`, capture a browser screenshot if the
visual state changed enough, then commit/push/watch CI.

### Local Trusted Beta Impact

Improves the core product loop: Merlin can now offer user-owned local transcript
history without converting chat into approved memory.

### Public Beta Impact

Positive progress, but Public Beta still requires Room picker UX, delete/export
behavior, reliable browser automation, clean installer retest, and complete
memory review/delete evidence.

---

## CI Smoke Repair Follow-Up — 2026-05-09

### Date / Time

2026-05-09 EDT.

### Branch

`main`

### Starting Commit SHA

`053307b` — `fix(dashboard): align room save smokes and clean chat center`

### Target Issues

- #95: release-readiness evidence and CI guardrail repair.
- #106/#135: Wizard HQ Chat and Rooms smoke coverage.

### Scope

Repair the remaining stale CI dashboard guardrail after Room transcript save was
added through the existing Task API approval lifecycle.

### Files Changed

- `tests/dashboard-merlin-status-smoke.sh`

### Protected Files Touched

None.

### Commands Run

- `bash -x tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `git diff --check`
- `.venv-test/bin/python -m pytest tests/test_task_endpoint.py`

### Test Output Summary

- Dashboard smoke sequence passed after the guardrail update.
- `git diff --check` passed.
- `tests/test_task_endpoint.py` passed: 14 tests.

### Failures Found

CI run `25604096871` still failed after the first smoke alignment because
`tests/dashboard-merlin-status-smoke.sh` retained the old "one POST" contract.
The local failure initially exited with no `FAIL:` message.

### Failure Category

- Test design gap
- CI/static smoke gap

### Root Cause Or Current Hypothesis

The dashboard status smoke had two stale assumptions:

- it still expected the old exact copy `Chat uses one policy-gated POST`;
- it still required exactly one browser POST instead of the current explicit
  allowlist: Task API chat POST plus approved Room transcript save flow.

Because the script used raw `grep -q` under `set -e`, the missing copy failed
silently and slowed diagnosis.

### Fix Applied

- Converted the smoke to use `fail()` and `require()` helpers so missing
  dashboard contracts print a clear reason.
- Updated the allowed browser POST contract to require the Task API chat route
  and Room transcript approval/save endpoints.
- Kept the forbidden behavior checks for direct model backends and browser
  execution controls.

### Retest Result

PASS locally for the dashboard smoke sequence and backend Room transcript tests.

### Regression Test Added Or Reason Not Added

Updated the existing regression smoke instead of adding a duplicate test. The
same CI gate now catches missing Room transcript approval/save wiring with a
clear failure message.

### Follow-Up Issues Created Or Recommended

Continue the existing recommended follow-up:

**Title:** `v3.1 Rooms: add Room picker and local storage path migration tests`

### Lesson Learned

Every static smoke that protects a user trust boundary should print an explicit
failure reason. Silent `grep` failures are acceptable only for exploratory
commands, not release gates.

### What Not To Repeat Next Time

Do not leave raw `grep -q` checks in CI-critical smoke tests when a failure would
not explain the missing product contract.

### Local Trusted Beta Impact

Positive. This improves CI reliability without changing runtime behavior.

### Public Beta Impact

Positive, but Public Beta still requires full manual installer/browser evidence.

---

## v3.1 Product Shell Safe UI Slice — 2026-05-09

### Date / Time

2026-05-09 EDT.

### Branch

`main`

### Starting Commit SHA

`7e36488` — `fix(dashboard): repair Merlin status smoke for room saves`

### Target Issues

- #106: Wizard HQ Product Shell.
- #135: Merlin Rooms for local chat history and scoped context.
- #130: brain/context storage location visibility.
- #129: Fast/Smart offline model selection UI.
- #117/#126 support: provider connector setup preview without secret display or
  cloud enablement.

### Scope

Advance the next three milestone-aligned UI tasks without adding risky runtime
behavior:

1. Room picker preview and local Room storage explanation.
2. Fast/Smart/Cloud Bridge model selection preview.
3. AI connector setup preview with presence-only secret language.
4. Cleaner Chat center: removed the old "Ask Merlin / Talk to Merlin first"
   intro block and kept the orb, suggestions, and composer as the focus.
5. Collapsible Chat context side panel for desktop and narrow/mobile layouts.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-model-readiness-smoke.sh`
- `tests/dashboard-settings-policy-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

All commands above passed locally.

### Tests Skipped And Why

- Full installer retest: not triggered by this dashboard-only static UI slice.
- Live model/provider setup: intentionally not run because this slice does not
  enable model downloads, API-key entry, cloud routing, or connector writes.

### Failures Found

None in this slice.

### Failure Category

No new failure.

### Root Cause Or Current Hypothesis

Not applicable.

### Fix Applied

- Added a disabled Room picker preview in Chat and Rooms so the user can see the
  intended local workspace model before writable Room creation ships.
- Added explicit "storage is not inference" copy to prevent OneDrive/iCloud/local
  folder confusion.
- Added Fast/Smart/Cloud Bridge selection previews in Brains while keeping cloud
  locked and model downloads manual-only.
- Added AI connector setup preview in Settings with secret presence-only copy and
  a clear rule that saving a key does not enable cloud routing.
- Removed the duplicate Chat intro block so the Chat center stays focused on the
  Merlin orb, starter prompts, and composer.
- Added desktop collapsed and narrow-layout expanded states for the Chat context
  side panel.
- Extended static dashboard smokes to protect these trust boundaries.

### Retest Result

PASS locally for Rooms, model readiness, Settings, first-run Chat, Merlin status
smoke, native Chat, tab shell, and diff whitespace checks.

### Regression Test Added Or Reason Not Added

Updated existing static smokes instead of adding duplicate files:

- Rooms smoke now asserts read-only Room picker preview and storage/inference
  separation.
- Model readiness smoke now asserts Fast/Smart/Cloud Bridge preview language and
  cloud remains off until allowed.
- Settings smoke now asserts AI connector setup preview, secret presence-only
  language, and separation between stored credential presence and cloud routing.
- First-run/native Chat/Merlin status smokes now assert the removed intro block
  stays removed and the side panel remains collapsible/expandable.

### Follow-Up Issues Created Or Recommended

Existing follow-ups remain:

- #135 child: Room picker and reference-policy persistence.
- #130 child: storage migration validation, rollback, and audit tests.
- #129 child: real model mode switching after safe local model availability is
  proven.
- #117 child: provider setup write flow through backend policy gate and OS
  secret storage.

### Lesson Learned

The dashboard can communicate the future product shape without turning previews
into unsafe controls. Disabled previews are useful only when the copy clearly
states what is locked and which backend gate must exist first.

### What Not To Repeat Next Time

Do not add visual toggles that look live before their backend policy gate,
rollback, audit, and tests exist.

### Local Trusted Beta Impact

Positive. A trusted tester can now see where Rooms, Fast/Smart models, storage
location, and provider setup are going without being misled into thinking those
unsafe writes are already enabled.

### Public Beta Impact

Positive, but Public Beta still needs real Room picker persistence, memory
review/delete, export/import, clean installer evidence, and polished browser
validation screenshots.

---

## Wizard HQ Header Cleanup — 2026-05-09

### Date / Time

2026-05-09 EDT.

### Branch

`main`

### Starting Commit SHA

`b84d26d` — `feat(dashboard): polish Merlin chat shell controls`

### Target Issues

- #106: Wizard HQ Product Shell.
- #135: Merlin Rooms / local chat context clarity.
- #129/#130 support: model mode and storage trust signals.

### Scope

Clean the global header and reduce duplicated diagnostics in the Chat page:

- move local mode, cloud-disabled, hardware tier, readiness, and Task API state
  out of the global header and into the collapsible Chat side panel;
- add hover explanations for product tabs and status chips;
- keep product tabs sticky while scrolling;
- preserve side-panel collapse/expand behavior.
- record the future talk-mode direction: the central Merlin presence is the
  voice/listening surface once local audio consent and privacy checks exist.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-merlin-status-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`
- `gh run list --branch main --limit 2 --json databaseId,headSha,status,conclusion,name,createdAt,url`

### Test Output Summary

All local static dashboard smokes passed. GitHub Actions run `25618439525` for
commit `b84d26d` completed successfully before this cleanup commit.

### Tests Skipped And Why

- Full installer retest: not triggered by this dashboard-only layout cleanup.
- Live browser screenshot: not captured in this sub-slice; recommended before
  closing #106/#135 UI work.

### Failures Found

`tests/dashboard-native-chat-smoke.sh` initially failed because removing the old
Trust card also removed the exact phrase `Memory writes require approval`.

### Failure Category

- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

The old Trust card mixed several concepts. Moving status into the side panel was
correct, but the memory approval warning is still a required user trust signal
and test contract.

### Fix Applied

Added a side-panel status chip:

`memory_approval_required`

with hover copy explaining that memory writes require approval and local
transcripts do not automatically become reusable memory.

Added a future talk-mode note under the central Merlin presence. It explicitly
does not claim voice is implemented; it says listening and reply pulses stay
disabled until voice capture, consent, and local audio privacy checks exist.

### Retest Result

PASS after restoring the memory approval signal in the side panel.

### Regression Test Added Or Reason Not Added

Updated first-run and Merlin status smokes to assert:

- status chips live in the side panel,
- status chips have hover explanations,
- top product tabs have hover explanations,
- sticky tab bar styles remain.
- future talk-mode presence is documented without claiming voice support.

### Follow-Up Issues Created Or Recommended

Recommended under #106/#135:

- capture desktop and narrow-layout screenshots after the side-panel move;
- add Playwright or static DOM checks for collapsed/expanded visual states once
  browser automation is stable.

### Lesson Learned

Reducing dashboard noise is good, but trust signals should be relocated, not
deleted. If a phrase is part of a safety contract, preserve the concept even
when the visual layout changes.

### What Not To Repeat Next Time

Do not remove status or approval language as "redundant" until the replacement
surface carries the same user-facing trust guarantee.

### Local Trusted Beta Impact

Positive. The Chat surface is cleaner while local-only, cloud-disabled,
readiness, Task API, and memory-approval states remain visible in the side
panel.

### Public Beta Impact

Positive, pending visual screenshot evidence and continued UI polish.

---

## Wizard HQ Locked Header Navigation — 2026-05-09

### Date / Time

2026-05-09 EDT.

### Branch

`main`

### Starting Commit SHA

`ade51a2` — `feat(dashboard): move chat status into side panel`

### Target Issues

- #106: Wizard HQ Product Shell.

### Scope

Move the Chat, Rooms, Brains, Memory, Agents, Security, System, and Settings
navigation into the locked top header beside the refresh action. Remove the
separate second-row tab strip so navigation and refresh stay together while the
page scrolls.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

All commands above passed locally.

### Tests Skipped And Why

- Full installer retest: not triggered by this dashboard-only navigation layout
  change.
- Live screenshot: recommended after the next visual pass, but not required for
  this static layout move.

### Failures Found

None.

### Failure Category

No new failure.

### Fix Applied

- Moved product tabs into the sticky `topbar`, beside Refresh.
- Removed the redundant second-row tab wrapper.
- Kept hover explanations on each top navigation item.
- Updated the first-run smoke so it asserts the product tabs live in the locked
  header.

### Retest Result

PASS locally for the dashboard static smoke set.

### Regression Test Added Or Reason Not Added

Updated the existing first-run smoke instead of adding a duplicate test.

### Lesson Learned

The navigation belongs with the persistent product chrome. Status diagnostics
belong in the side panel; primary product areas belong in the locked header.

### What Not To Repeat Next Time

Do not reintroduce a separate sticky tab row unless the header runs out of
responsive space and the fallback is explicitly tested.

### Local Trusted Beta Impact

Positive. The navigation is easier to understand and stays available while
scrolling.

### Public Beta Impact

Positive, pending screenshot evidence and further visual polish.

---

## v3.1 Rooms Active Picker Slice — 2026-05-09

### Date / Time

2026-05-09 EDT.

### Branch

`main`

### Starting Commit SHA

`02f2e87` — `feat(dashboard): lock product tabs in header`

### Target Issues

- #135: Merlin Rooms for local chat history and scoped context.
- #106: Wizard HQ Product Shell.

### Scope

Add a client-side active Room picker backed by the read-only Rooms manifest.
The selected Room is session-local in Wizard HQ and becomes the explicit target
for an approved transcript save. It does not persist reference policy, index
Room context, write memory, or create Rooms.

### Files Changed

- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `tests/dashboard-rooms-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

- `git status --short && git rev-parse HEAD`
- `curl -fsS --max-time 3 http://localhost:8888 >/dev/null && echo wizard-hq-ok || echo wizard-hq-unavailable`
- `curl -fsS --max-time 3 http://localhost:8766/status/rooms || true`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

Static dashboard smoke set passed locally. Live Wizard HQ and Task API curls did
not connect because services were not running in the current environment.

### Tests Skipped And Why

- Live browser screenshot / click-through: skipped because `localhost:8888` was
  unavailable.
- Live `/status/rooms` validation: skipped because `localhost:8766` was
  unavailable.
- Full installer retest: not triggered by this dashboard/architecture/static
  test slice.

### Failures Found

Live service checks failed:

- `curl -fsS --max-time 3 http://localhost:8888`
- `curl -fsS --max-time 3 http://localhost:8766/status/rooms`

### Failure Category

- Wizard HQ/dashboard environment unavailable
- Task API 8766 environment unavailable
- UX/readiness validation blocked

### Root Cause Or Current Hypothesis

The local Merlin services were not running in this shell session. This is not a
product defect proven by this pass, but it blocks visual/browser evidence.

### Fix Applied

No runtime fix applied. Continued with static implementation and documented the
live-check blocker.

### Retest Result

PASS for static dashboard smokes after implementation.

### Regression Test Added Or Reason Not Added

Updated `tests/dashboard-rooms-smoke.sh` to assert:

- active Room picker exists,
- `selectActiveRoom()` exists,
- session-only selection state is visible,
- selected target Room appears in save flow,
- reference policy persistence remains locked.

### Follow-Up Issues Created Or Recommended

Recommended under #135/#106:

- Run live Wizard HQ visual QA after starting the local stack.
- Capture desktop and narrow-layout screenshots for Chat and Rooms.
- Add browser automation for Room picker collapsed/expanded/selected states once
  Playwright or equivalent is stable in the repo.

### Lesson Learned

Room selection can improve the product loop without crossing the memory boundary
if it is explicitly labeled as session-local and reference policy remains
locked.

### What Not To Repeat Next Time

Do not call Room selection "context enabled" until backend reference policy,
indexing, and approval tests exist.

### Local Trusted Beta Impact

Positive. Merlin now shows a clearer path from Chat to a selected local Room
while preserving no-context and no-memory-write defaults.

### Public Beta Impact

Positive, but live browser evidence is still required.

---

## 2026-05-09 23:35 EDT - Room Save Button UX Fix

### Branch

`main`

### Starting Commit SHA

`4c5420202880cb4e296295342c4451d61ddde22b`

### Ending Commit SHA If Changed

Recorded in the session closeout and `git log`. The commit cannot embed its own
final SHA without changing that SHA.

### Target Issue(s)

#106 Wizard HQ Product Shell, #135 Merlin Rooms, #95 release-readiness evidence.

### Scope

Fix the Merlin Chat Room save surface so unavailable Room save actions are not
shown as inert buttons before Merlin has produced a safe local response.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. Installer, runtime APIs, policy engine, memory manager, router, and patent
files were not changed.

### Commands Run

- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

- `bash tests/dashboard-rooms-smoke.sh` - PASS: Merlin Rooms surface is local,
  explicit, and non-writing.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS: Wizard HQ native Merlin
  Chat is policy-gated through Task API.
- `bash tests/dashboard-first-run-smoke.sh` - PASS: Wizard HQ Chat home product
  clarity is safe and read-only.
- `bash tests/dashboard-merlin-status-smoke.sh` - PASS: Dashboard Merlin status
  smoke test passed.
- `bash tests/dashboard-model-readiness-smoke.sh` - PASS: Wizard HQ model
  readiness UX is explicit and no-download.
- `bash tests/dashboard-settings-policy-smoke.sh` - PASS: Wizard HQ Settings is
  backend-manifested and policy-gated.
- `bash tests/dashboard-tabs-smoke.sh` - PASS: Wizard HQ tab shell is
  Merlin-native and read-only.
- `git diff --check` - PASS, no whitespace errors.

### Tests Skipped And Why

- Live browser click-through: not run in this pass. Previous evidence shows
  `localhost:8888` and `localhost:8766` were unavailable in this shell session.
- Full installer retest: not triggered. This change touches only dashboard
  rendering and static smoke tests.

### Failures Found

User-reported UI failure: after asking Merlin, the Room save panel showed
`Prepare Room save`, `Allow local save`, and `Cancel save`, but the buttons did
not work in the visible state.

### Failure Category

- UX/readiness confusion
- Wizard HQ/dashboard
- Test design gap

### Root Cause Or Current Hypothesis

The Room save panel rendered all three actions in every state and relied on
`disabled` button attributes to block unavailable actions. When the latest
Merlin exchange was not eligible for save, or backend approval had not been
prepared yet, the UI looked actionable but behaved inertly.

### Fix Applied

Changed the Room save surface to a staged flow:

- `waiting`: no action buttons; plain-language hint says to ask Merlin and wait
  for a safe local response.
- `response-ready`: only `Prepare Room save` is shown.
- `approval-prepared`: only `Allow local save` and `Cancel save` are shown.

After a successful transcript save, the latest exchange is cleared so the same
response is not offered for duplicate save.

### Retest Result

PASS for all focused static dashboard smoke tests listed above.

### Regression Test Added Or Reason Not Added

Updated:

- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-native-chat-smoke.sh`

The tests now assert the three explicit Room save stages and fail if the old
pattern of rendering unavailable actions as disabled buttons returns.

### Follow-Up Issues Created Or Recommended

Recommended under #135/#106:

- Add live browser automation for the staged Room save flow once the local stack
  is running in the test environment.
- Verify visually that Room save transitions from waiting to prepare to
  allow/cancel after a real Task API response.

### Lesson Learned

Approval-gated controls must not look clickable before the backend has created
the state required for them to work. For trust UX, unavailable actions should be
replaced with the next true step, not shown as dead controls.

### What Not To Repeat Next Time

Do not render every future approval action upfront with disabled attributes when
the user has not reached that stage. Stage the action surface around the real
backend lifecycle.

### Local Trusted Beta Impact

Positive. This removes a confusing first-use Room save failure from the Merlin
Chat path while preserving transcript-only local save and separate memory
approval.

### Public Beta Impact

Positive, but live browser click-through evidence remains required before any
public-beta readiness claim.

---

## 2026-05-09 23:39 EDT - Chat Approval Card And Metadata Cleanup

### Branch

`main`

### Starting Commit SHA

`dbf8a0a4d55c933edf211779a3b2922a8863eae9`

### Ending Commit SHA If Changed

Recorded in the session closeout and `git log`. The commit cannot embed its own
final SHA without changing that SHA.

### Target Issue(s)

#106 Wizard HQ Product Shell, #135 Merlin Rooms, #95 release-readiness evidence.

### Scope

Tighten the blocked-route chat experience after user review showed the main chat
felt clunky and exposed too much route telemetry.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. The Task API, policy engine, router, installer, memory manager, and patent
files were not changed.

### Commands Run

- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

- `bash tests/dashboard-native-chat-smoke.sh` - PASS: Wizard HQ native Merlin
  Chat is policy-gated through Task API.
- `bash tests/dashboard-first-run-smoke.sh` - PASS: Wizard HQ Chat home product
  clarity is safe and read-only.
- `bash tests/dashboard-rooms-smoke.sh` - PASS: Merlin Rooms surface is local,
  explicit, and non-writing.
- `bash tests/dashboard-merlin-status-smoke.sh` - PASS: Dashboard Merlin status
  smoke test passed.
- `bash tests/dashboard-model-readiness-smoke.sh` - PASS: Wizard HQ model
  readiness UX is explicit and no-download.
- `bash tests/dashboard-settings-policy-smoke.sh` - PASS: Wizard HQ Settings is
  backend-manifested and policy-gated.
- `bash tests/dashboard-tabs-smoke.sh` - PASS: Wizard HQ tab shell is
  Merlin-native and read-only.
- `git diff --check` - PASS, no whitespace errors.

### Tests Skipped And Why

- Live browser click-through: not run in this pass because the current task was
  a static dashboard UX correction. It still needs visual confirmation after the
  local stack is started.
- Full installer retest: not triggered. No installer, package, launchd, or
  startup behavior changed.

### Failures Found

User-reported UX failure: a blocked `Review this project for security gaps`
request showed route/model/staff metadata as large cards in the chat and showed
Room save context even though the route was blocked.

### Failure Category

- UX/readiness confusion
- Wizard HQ/dashboard
- Test design gap

### Root Cause Or Current Hypothesis

`renderChatOutput()` rendered operational route metadata as a full grid for
every response state and always appended the Room save panel. Blocked routes do
not return a safe Merlin response and the Task API does not yet create an inline
chat approval id, so the UI looked like a dashboard/debug trace instead of a
clean chat decision point.

### Fix Applied

- Replaced the large route metadata grid with compact message tags.
- Added a blocked-route approval card with `Review approval` and `Keep blocked`.
- Kept the browser safe: the card does not pretend to approve a route without a
  backend approval id.
- Hid Room save unless Merlin returns an approved, non-degraded response.

### Retest Result

PASS for the dashboard smoke set listed above.

### Regression Test Added Or Reason Not Added

Updated `tests/dashboard-native-chat-smoke.sh` to assert:

- chat route metadata stays compact,
- bulky route metadata cards do not return,
- blocked routes show a clear approval card,
- the UI states that chat approvals are not yet backed by an inline approval id.

### Follow-Up Issues Created Or Recommended

Recommended under #106/#135:

- Add a backend chat-route approval request id if we want true inline
  `Allow`/`Deny` decisions for blocked routes.
- Add live browser automation for blocked route -> review approval -> keep
  blocked.

### Lesson Learned

Merlin Chat should feel like an assistant first and an operations dashboard
second. Route, model, and staff data belong as small proof tags unless the user
opens a system/debug surface.

### What Not To Repeat Next Time

Do not place full route/debug cards between the user and the assistant response.
Do not show Room save on blocked, pending, or degraded responses.

### Local Trusted Beta Impact

Positive. This makes the first blocked-route experience clearer and keeps the
policy gate visible without making the chat feel like an engineering console.

### Public Beta Impact

Positive, with remaining need for live browser evidence and a future backend
approval-id flow before true inline route approvals are advertised.

---

## 2026-05-09 23:51 EDT - Default Room Folder And Room Prompt Contract

### Branch

`main`

### Starting Commit SHA

`98a09386353cc0c119f36d735651d6fd56d079f3`

### Ending Commit SHA If Changed

Recorded in the session closeout and `git log`. The commit cannot embed its own
final SHA without changing that SHA.

### Target Issue(s)

#135 Merlin Rooms, #106 Wizard HQ Product Shell, #95 release-readiness evidence.

### Scope

Initialize the local Merlin brain/Rooms folder layout during install, fix the
current local machine so Wizard HQ can see the default Room, and document the
future Room Master Prompt plus prompt-based Room deletion contract.

### Files Changed

- `.github/workflows/ci.yml`
- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`
- `install.sh`
- `scripts/init-merlin-brain.sh`
- `tests/dashboard-rooms-smoke.sh`
- `tests/installer-merlin-api-policy-smoke.sh`
- `tests/merlin-brain-layout-smoke.sh`

### Protected Files Touched

- `install.sh` was touched narrowly to call a local folder initializer.

No package scripts, uninstall behavior, model-pull defaults, cloud defaults,
runtime policy gates, memory manager, router, or patent files were changed.

### Commands Run

- `curl -i --max-time 5 http://localhost:8766/status/routes`
- `curl -i --max-time 5 -X POST http://localhost:8766/approvals/room-transcript ...`
- `lsof -nP -iTCP:8766 -sTCP:LISTEN`
- `bash scripts/merlin-task-api.sh restart`
- `curl -i --max-time 5 -X POST http://127.0.0.1:8766/approvals/room-transcript ...`
- `curl -i --max-time 5 http://127.0.0.1:8766/status/rooms`
- `bash scripts/init-merlin-brain.sh`
- `curl -fsS --max-time 5 http://127.0.0.1:8766/status/rooms`
- `bash tests/merlin-brain-layout-smoke.sh`
- `bash tests/installer-merlin-api-policy-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash -n install.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `git diff --check`

### Test Output Summary

- Initial `POST /approvals/room-transcript` returned HTTP 404 from the live Task
  API process.
- `bash scripts/merlin-task-api.sh restart` started the current Task API.
- Retest `POST /approvals/room-transcript` returned HTTP 200 with
  `approval_request_id`.
- Initial `/status/rooms` showed `rooms_root_exists:false`.
- After `bash scripts/init-merlin-brain.sh`, `/status/rooms` showed
  `rooms_root_exists:true`, one `merlin-build` Room, and transcript count `0`.
- `bash tests/merlin-brain-layout-smoke.sh` - PASS.
- `bash tests/installer-merlin-api-policy-smoke.sh` - PASS.
- `bash tests/dashboard-rooms-smoke.sh` - PASS.
- `bash tests/pkg-readiness-smoke.sh` - PASS.
- `bash -n install.sh` - PASS.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Full installer retest: not run in this pass. It is triggered before Local
  Trusted Beta signoff because `install.sh` changed.
- Live browser click-through: not run in this pass. Backend endpoints were
  validated with curl, and dashboard static smokes passed.

### Failures Found

1. Live Task API returned `404 Not Found` for
   `POST /approvals/room-transcript`.
2. Live Rooms manifest reported `rooms_root_exists:false` before folder
   initialization.

### Failure Category

- Wizard HQ/dashboard
- Task API 8766 stale process
- Installer flow
- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

The Task API process on port `8766` was stale and did not include the current
Room approval endpoint. Separately, the installer did not create the default
local Merlin brain/Rooms folder layout, leaving the dashboard with no concrete
default Room until the first save.

### Fix Applied

- Restarted the local Task API with `bash scripts/merlin-task-api.sh restart`.
- Added `scripts/init-merlin-brain.sh`.
- Called the initializer from `install.sh` after environment setup.
- Added a static/functional brain layout smoke test and wired it into CI.
- Improved dashboard stale-backend copy for Room approval 404s.
- Documented Room Master Prompt generation and prompt-based Room deletion as
  future approval-gated contracts.

### Retest Result

PASS. The live Rooms manifest now reports:

- `rooms_root_exists:true`
- `rooms_root:/Users/kevinmedeiros/Merlin/brain/rooms`
- default Room `merlin-build`

### Regression Test Added Or Reason Not Added

Added `tests/merlin-brain-layout-smoke.sh` to verify:

- default brain root creation,
- default Room folder creation,
- transcript/summary/master-prompt/agent/index folders,
- `room.md` local-only metadata,
- no approved memory or transcript content is created by initialization.

Updated `tests/dashboard-rooms-smoke.sh` and
`tests/installer-merlin-api-policy-smoke.sh`.

### Follow-Up Issues Created Or Recommended

Recommended focused follow-ups under #135:

- Implement Room Master Prompt generation/review flow.
- Implement prompt-based Room delete intent with an `Are you sure?` approval
  card.
- Add live browser automation for Room save and Room management once local
  stack testing is stable.

### Lesson Learned

If Wizard HQ exposes a default Room, install must create the matching local
filesystem target. Otherwise the product appears to promise a Room that does not
exist yet.

### What Not To Repeat Next Time

Do not ship UI affordances that depend on a local data root without ensuring the
installer or first-run setup creates that root. Do not interpret a 404 from a
known endpoint as a user error before checking for a stale backend process.

### Local Trusted Beta Impact

Positive, but a full installer retest is now required because `install.sh`
changed.

### Public Beta Impact

Positive, but public beta remains blocked until full installer retest and live
browser evidence are captured.

---

## 2026-05-09 23:59 EDT - Room Launcher And Smooth Page UX

### Branch

`main`

### Starting Commit SHA

`0490b9bcec1b689eca4ccc78b1aab5c5eb3ae90b`

### Ending Commit SHA If Changed

Recorded in the session closeout and `git log`. The commit cannot embed its own
final SHA without changing that SHA.

### Target Issue(s)

#106 Wizard HQ Product Shell, #135 Merlin Rooms, #95 release-readiness evidence.

### Scope

Make the Rooms tab behave like a Room launcher and add a smooth, reduced-motion
safe interaction layer across Wizard HQ.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `tests/dashboard-rooms-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. No installer, package, API, policy, memory, router, or patent files were
changed in this slice.

### Commands Run

- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `git diff --check`

### Test Output Summary

- `bash tests/dashboard-rooms-smoke.sh` - PASS.
- `bash tests/dashboard-first-run-smoke.sh` - PASS.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Live browser click-through: not run in this static UX slice. Needs visual QA
  after the dashboard is opened.
- Full installer retest: not triggered by this slice. The prior installer
  change still requires full installer retest before Local Trusted Beta signoff.

### Failures Found

No command failures in this slice. User feedback identified a UX gap: Rooms
should be one or two clicks away from active Chat use, not just displayed as
status.

### Failure Category

- UX/readiness confusion

### Root Cause Or Current Hypothesis

Rooms were visible but passive. Selecting a Room did not clearly behave like
jumping into that Room's chat workspace, and page transitions were abrupt.

### Fix Applied

- Added `openRoomInChat()` so Rooms can launch back into Chat.
- Room selection now focuses the Chat input and shows a visible Room tag.
- Chat Room tag states that future context remains Room-only unless explicit
  selected-Room or all-Room sharing is enabled.
- Added smooth tab/page transitions, hover polish, focus-visible styling, and
  reduced-motion safeguards.

### Retest Result

PASS for focused dashboard static smokes listed above.

### Regression Test Added Or Reason Not Added

Updated:

- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-first-run-smoke.sh`

The tests now check Room launcher behavior, Chat return behavior, explicit
cross-Room sharing language, smooth page transitions, visible focus, and
reduced-motion support.

### Follow-Up Issues Created Or Recommended

Recommended under #135:

- Persist active Room and reference policy through a backend settings gate.
- Add real Room-only context retrieval only after policy persistence exists.
- Add live browser automation for Room launcher -> Chat input focus.

### Lesson Learned

Rooms become useful when they behave like workspaces the user can jump into, not
when they are only listed as backend state.

### What Not To Repeat Next Time

Do not add product tabs that are more than two clicks away from the task they
support. Do not enable cross-Room context by implication.

### Local Trusted Beta Impact

Positive. Wizard HQ now feels closer to a usable local AI workspace while
preserving no-context defaults.

### Public Beta Impact

Positive, but still needs live visual/browser evidence.

---

## 2026-05-10 00:18 EDT - #135 Room Master Prompt Draft Foundation

### Branch

`main`

### Starting Commit SHA

`56ea31a688cc800492d5b246447c96e03256f8f7`

### Ending Commit SHA

Pending commit at time of note.

### Target Issues

- #135 Merlin Rooms
- #123 Offline local brain and user-owned context store support path
- #31/#32 memory approval/delete safety boundaries, not directly implemented

### Scope

Add the first local-only Room Master Prompt draft path. This lets Merlin prepare
a Room-scoped prompt from saved local transcripts after a backend approval. The
draft is not approved memory, not context-enabled, not shared across Rooms, and
not generated from browser-side file controls.

### Files Changed

- `merlin/approval_store.py`
- `merlin/room_store.py`
- `merlin/task_endpoint.py`
- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `tests/dashboard-rooms-smoke.sh`
- `tests/test_room_store.py`
- `tests/test_task_endpoint.py`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/task_endpoint.py` - touched to add policy-gated Room Master Prompt
  endpoints on 8766 only.

No installer files, uninstall files, policy files, memory manager write paths,
or 8765 read-only status API behavior were changed.

### Commands Run

```bash
.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_task_endpoint.py
.venv-test/bin/python -m pytest tests/test_status_extension.py tests/test_room_store.py tests/test_task_endpoint.py
bash tests/dashboard-rooms-smoke.sh
bash tests/dashboard-native-chat-smoke.sh
bash tests/dashboard-tabs-smoke.sh
bash tests/dashboard-merlin-status-smoke.sh
bash tests/merlin-brain-layout-smoke.sh
git diff --check
```

### Test Output Summary

- `tests/test_room_store.py tests/test_task_endpoint.py` - 27 passed.
- `tests/test_status_extension.py tests/test_room_store.py tests/test_task_endpoint.py` - 57 passed.
- `bash tests/dashboard-rooms-smoke.sh` - PASS.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS.
- `bash tests/dashboard-tabs-smoke.sh` - PASS.
- `bash tests/dashboard-merlin-status-smoke.sh` - PASS.
- `bash tests/merlin-brain-layout-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Full installer retest: still required before Local Trusted Beta signoff
  because earlier work changed `install.sh`, but this slice did not change
  installer/package behavior.
- Live browser click-through: not run in this backend/doc/status slice. Needed
  before UX signoff on the Room Master Prompt review UI.
- Live Ollama/LiteLLM/Qdrant checks: not required; Room Master Prompt draft
  generation is deterministic local file synthesis and does not call a model.

### Failures Found

No command failures in this slice.

### Failure Category

No new command failure. The underlying user-reported product gap remains:
saved Room transcripts need a clear path toward reusable scoped context without
silent memory writes.

### Root Cause Or Current Hypothesis

Rooms could save transcript history, but there was no approved intermediate
artifact that could later become scoped context. Jumping directly from transcript
save to memory/context would violate the no-silent-memory-write rule.

### Fix Applied

- Added Room Master Prompt approval hashing and approval creation.
- Added Room Master Prompt draft approval enforcement.
- Added deterministic local draft generation under
  `master-prompts/master-prompt.md`.
- Added 8766 endpoints:
  - `POST /approvals/room-master-prompt`
  - `POST /rooms/master-prompt-drafts`
- Added dashboard read-only status for Room Master Prompt draft state.
- Updated Rooms architecture doc to distinguish transcript storage, draft prompt
  generation, approved memory, and future context reuse.

### Retest Result

PASS for all commands listed above.

### Regression Tests Added Or Updated

- `tests/test_room_store.py` verifies draft generation requires transcripts,
  writes local Markdown, stays `approved_for_context: false`, and does not leak
  raw content in manifest records.
- `tests/test_task_endpoint.py` verifies approval is required, pending approvals
  fail closed, approved drafts write local files, audit metadata excludes raw
  content, and context reuse remains disabled.
- `tests/dashboard-rooms-smoke.sh` verifies visible Room Master Prompt draft
  state and approval-gated copy.

### Follow-Up Issues Created Or Recommended

Recommended under #135:

- Add Wizard HQ review UI for `master-prompts/master-prompt.md`.
- Add approval-gated "approve for Room context" flow after review/edit.
- Add prompt-based Room delete/archive intent with an approval card and linked
  memory/master-prompt warning.
- Add browser automation for Room save -> Master Prompt draft -> review screen.

### Lesson Learned

Room transcripts should not become context directly. The safer bridge is:
transcript history -> local draft prompt -> user review/edit -> separate context
approval.

### What Not To Repeat Next Time

Do not make saved chat history reusable context by implication. Do not expose raw
Room content in approval payloads, status manifests, or audit metadata.

### Next Recommended Step

Build the Wizard HQ Room Master Prompt review surface: show draft metadata,
open/review local draft safely, and keep "approve for context" locked until a
separate backend policy gate exists.

### Local Trusted Beta Impact

Positive. Merlin now has a clearer, auditable path from local chat history to a
future scoped Room brain without silent memory writes.

### Public Beta Impact

Positive, but public beta still needs full installer retest, live browser
evidence, and the Room Master Prompt review/approval UX before making context
reuse claims.

---

## 2026-05-10 00:26 EDT - #133 Round Table Agent Governance Spec

### Branch

`main`

### Starting Commit SHA

`caf916dca7a7d4b20a4c8b1bc226fa8771be3b42`

### Ending Commit SHA

Pending commit at time of note.

### Target Issues

- #133 Round Table Architecture Doc
- #122 Product Focus Cut support
- #135 Room context boundary support

### Scope

Add a governance spec for project agents before building any runtime agent
behavior. The spec keeps Round Table roles suggest-only by default and blocks
unattended execution, cloud calls, memory writes, Room deletion, and cross-Room
context until future approval-gated issues exist.

### Files Changed

- `docs/architecture/ROUND_TABLE_AGENT_GOVERNANCE.md`
- `tests/round-table-agent-governance-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

```bash
bash tests/round-table-agent-governance-smoke.sh
bash tests/codex-master-prompt-v2-smoke.sh
git diff --check
```

### Test Output Summary

- `bash tests/round-table-agent-governance-smoke.sh` - PASS after one test
  design correction.
- `bash tests/codex-master-prompt-v2-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Runtime agent tests: no runtime agent API was added.
- Live browser tests: this is a docs/governance slice only.

### Failures Found

Two smoke-test failures were found while creating the new governance test:

1. The smoke expected the exact phrase `Room Master Prompt as approved for
   context reuse`; the doc used equivalent but less testable wording.
2. The negative regex matched the required sentence `They are not autonomous
   workers by default`.

### Failure Category

- Documentation mismatch
- Test design gap

### Root Cause Or Current Hypothesis

The initial smoke mixed semantic intent with brittle exact phrasing and used an
overbroad negative regex that flagged safe language.

### Fix Applied

- Tightened the doc wording for the Room Master Prompt context-reuse boundary.
- Narrowed the negative regex so it flags unsafe allowance language without
  matching explicit denial language.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

Added `tests/round-table-agent-governance-smoke.sh` to enforce:

- Round Table agents are suggest-only by default,
- no agent execution API in the first slice,
- no cloud, memory, or Room deletion defaults,
- Room context waits for approved Room Master Prompt reuse.

### Follow-Up Issues Created Or Recommended

Recommended under #133:

- Add a read-only Wizard HQ Round Table panel showing agent roles and default
  permissions.
- Add issue templates for future agent runtime work that require permission
  model, rollback, and evidence sections.

### Lesson Learned

Governance docs need smoke tests, but those tests must avoid matching protective
negative language as if it were permission.

### What Not To Repeat Next Time

Do not create broad negative regexes that match both allowed and denied forms of
the same concept.

### Next Recommended Step

Add a read-only Round Table panel in Wizard HQ after the Room Master Prompt
review screen, keeping all agent actions locked.

### Local Trusted Beta Impact

Positive. The project now has a documented agent governance boundary before any
agent runtime work begins.

### Public Beta Impact

Positive for trust posture, but no release-readiness claim changes.

---

## 2026-05-10 00:56 EDT - Roadmap And Master Prompt Drift Alignment

### Branch

`main`

### Starting Commit SHA

`d191e01c43775d637cc9427e39eda122c8395936`

### Ending Commit SHA

Pending commit at time of note.

### Target Issues

- #122 Product Focus Cut
- #123 Offline local brain and user-owned context store
- #134 Product Value Checkpoint
- #135 Merlin Rooms
- #133 Round Table governance
- #37/#95 release evidence support

### Scope

Align the top-level project prompts and roadmap docs with the live GitHub issue
queue and recent commits. The active product direction is v3.1 local brain proof:
Rooms, Room Master Prompt review, approved memory review/delete, and storage
location clarity. Developer ID signing and native automation remain deferred.

### Files Changed

- `CODEX_MASTER_PROMPT.md`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MASTER_CONTEXT.md`
- `docs/MASTER_PROMPT.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/CODEX_MASTER_PROMPT_V2.md`
- `docs/product/PRODUCT_NORTH_STAR.md`
- `tests/master-prompt-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None.

### Commands Run

```bash
git status --short
git branch --show-current
git rev-parse HEAD
git log --oneline -8
gh issue list --state open --limit 40 --json number,title,state,labels,milestone,updatedAt,url
gh issue list --state closed --limit 30 --json number,title,state,labels,milestone,closedAt,updatedAt,url
rg --files docs
sed -n '1,260p' docs/CANONICAL_PROJECT_STATE.md
sed -n '1,220p' docs/MASTER_CONTEXT.md
sed -n '1,260p' docs/MASTER_PROMPT.md
sed -n '1,340p' docs/MERLIN_IMPLEMENTATION_ROADMAP.md
bash tests/master-prompt-smoke.sh
bash tests/codex-master-prompt-v2-smoke.sh
bash tests/round-table-agent-governance-smoke.sh
bash tests/control-plane-strategy-smoke.sh
bash tests/observability-design-smoke.sh
git diff --check
```

### Test Output Summary

- `bash tests/master-prompt-smoke.sh` - PASS after smoke update.
- `bash tests/codex-master-prompt-v2-smoke.sh` - PASS.
- `bash tests/round-table-agent-governance-smoke.sh` - PASS.
- `bash tests/control-plane-strategy-smoke.sh` - PASS after aligning closed
  #118 expectation to current #129 model selection follow-up and canonical queue.
- `bash tests/observability-design-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Runtime Python tests: not run for docs-only governance alignment.
- Full installer retest: still required before Local Trusted Beta signoff, but
  this slice did not change installer/package behavior.

### Failures Found

`bash tests/master-prompt-smoke.sh` failed because it required
`Last verified: 2026-05-07` in `docs/MASTER_CONTEXT.md`.

`bash tests/control-plane-strategy-smoke.sh` failed because it required #118 as
an active canonical queue item even though #118 is closed. The current active
model UX follow-up is #129.

### Failure Category

- Documentation mismatch
- Test design gap
- Roadmap/governance drift

### Root Cause Or Current Hypothesis

The smoke test encoded an old date as truth instead of checking that
`MASTER_CONTEXT` reflects the current verified state.

### Fix Applied

- Updated `tests/master-prompt-smoke.sh` to require `Last verified: 2026-05-10`
  and current v3.1 focus markers.
- Updated `tests/control-plane-strategy-smoke.sh` to check #129 model selection
  instead of stale #118 model library follow-up, and added #129 back to the
  canonical active queue.
- Updated top-level roadmap/prompt docs to prioritize #135/#123/#134,
  #31/#32/#120, #130, #106/#114, and #133 before release signing or automation.
- Updated root `CODEX_MASTER_PROMPT.md` to stop future sessions from treating
  #37/#64/#95 or #92 as the immediate build queue.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

Updated `tests/master-prompt-smoke.sh` so future prompt/context drift checks
track the current v3.1 local brain direction.

### Follow-Up Issues Created Or Recommended

Recommended:

- Add a docs-governance smoke that verifies root `CODEX_MASTER_PROMPT.md`,
  `docs/CANONICAL_PROJECT_STATE.md`, and `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
  all mention the same top three active priorities.

### Lesson Learned

Governance tests should protect current product direction, not freeze old dates
or old milestone queues.

### What Not To Repeat Next Time

Do not let release/signing or automation prompts outrank the local
chat/Rooms/memory proof loop unless GitHub issue state and canonical state are
updated first.

### Next Recommended Step

Build the Wizard HQ Room Master Prompt review/edit surface, then add a separate
approve-for-context gate.

### Local Trusted Beta Impact

Positive. Future Codex sessions should now start from the correct v3.1 product
core instead of stale release/signing queues.

### Public Beta Impact

Positive for discipline, but no public beta readiness claim changes.

---

## 2026-05-10 - Merlin Identity And English-Default Chat Guard

### Branch

`main`

### Starting Commit SHA

`f7dd957f050c90b6a283ad561563ccadc91d9b7a`

### Ending Commit SHA

Pending commit at time of note.

### Target Issues

- #106 Wizard HQ Product Shell
- #123 Offline local brain and user-owned context store
- #129 Fast/Smart model selection UI
- #134 Product Value Checkpoint

### Scope

Fix user-reported chat identity/language confusion where the underlying local
engine surfaced as Qwen and the response included Chinese text. Merlin may use
Qwen or other local models underneath, but the product identity must remain
Merlin and responses should default to English unless the user asks otherwise.

### Files Changed

- `merlin/persona_injector.py`
- `dashboard/index.html`
- `tests/test_task_endpoint.py`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/persona_injector.py` - prompt contract only.
- `dashboard/index.html` - user-facing chat metadata only.

No installer, policy gate, memory write, secret, cloud, or service-control
behavior changed.

### Commands Run

```bash
.venv-test/bin/python -m pytest tests/test_task_endpoint.py
bash tests/dashboard-native-chat-smoke.sh
.venv-test/bin/python -m pytest tests/test_task_endpoint.py tests/test_status_extension.py
bash tests/dashboard-first-run-smoke.sh
bash tests/dashboard-model-readiness-smoke.sh
bash tests/dashboard-tabs-smoke.sh
git diff --check
```

### Test Output Summary

- `tests/test_task_endpoint.py` - 19 passed.
- `tests/test_task_endpoint.py tests/test_status_extension.py` - 49 passed.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS.
- `bash tests/dashboard-first-run-smoke.sh` - PASS.
- `bash tests/dashboard-model-readiness-smoke.sh` - PASS.
- `bash tests/dashboard-tabs-smoke.sh` - PASS.
- `git diff --check` - PASS.

### Tests Skipped And Why

- Live model output test: not run yet. This should be validated in the browser
  after restarting Task API/LiteLLM if the old prompt was already loaded.
- Full installer retest: not triggered by this slice because installer/package
  behavior did not change.

### Failures Found

User-reported product failure: chat surfaced Chinese text and/or identified the
assistant as Qwen instead of Merlin.

### Failure Category

- Wizard HQ/dashboard
- UX/readiness confusion
- Test design gap

### Root Cause Or Current Hypothesis

The system prompt identified Merlin but did not explicitly tell the local model
not to identify as the underlying engine or to default to English. Wizard HQ also
displayed raw selected model aliases as a chat metadata chip labeled `Brain`,
which made the product feel like Qwen rather than Merlin.

### Fix Applied

- Added `IDENTITY_AND_LANGUAGE_BLOCK` to every Merlin system prompt:
  - Merlin is the assistant identity.
  - Do not identify as Qwen/Llama/Mistral/DeepSeek/provider engines.
  - Explain engines as replaceable underneath Merlin.
  - Respond in English unless the user asks for another language.
- Updated Wizard HQ chat metadata to show `Merlin local route` instead of raw
  model aliases as the user-facing brain identity.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

- `tests/test_task_endpoint.py` verifies the identity/language block exists and
  is sent to LiteLLM in the system message.
- `tests/dashboard-native-chat-smoke.sh` verifies Wizard HQ labels the route as
  Merlin rather than exposing raw model aliases as the brain identity.

### Follow-Up Issues Created Or Recommended

Recommended under #106/#129:

- Add a live browser QA script that asks "who are you?" and verifies the visible
  answer identifies as Merlin in English.
- Add a user-facing Brains explanation that engine names are technical details,
  while Merlin is the assistant identity.

### Lesson Learned

Local model names are implementation details. If they surface in chat identity,
the product feels like a model launcher instead of Merlin.

### What Not To Repeat Next Time

Do not label raw model aliases as the user-facing brain in chat. Do not assume a
local model will preserve product identity without an explicit prompt contract.

### Next Recommended Step

Restart the Task API if it is running, then live-test Wizard HQ with:

- "Who are you?"
- "What model are you using?"
- "Answer in English: what is Merlin?"

### Local Trusted Beta Impact

Positive. This directly improves first-use trust and product identity.

### Public Beta Impact

Positive, but still needs live browser evidence before signoff.

---

## 2026-05-10 - Chat Room Save Meter And Side-Panel Engine Detail

### Branch

`main`

### Starting Commit SHA

`e0c41fac4442ac6073e647b058a931585ed6d3ff`

### Ending Commit SHA

Pending commit at time of note.

### Target Issues

- #106 Wizard HQ Product Shell
- #123 Offline local brain and user-owned context store
- #129 Fast/Smart model selection UI
- #135 Merlin Rooms

### Scope

Move technical model/route detail out of the main chat and into the side panel,
add a prompt-count meter that recommends saving to a Room before a chat grows too
long, and show saved Room transcript metadata in the side panel without exposing
raw transcript text.

### Files Changed

- `dashboard/index.html`
- `merlin/persona_injector.py`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/test_task_endpoint.py`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/persona_injector.py` - prompt contract only.
- `dashboard/index.html` - UI only.

No installer, policy gate, memory write, cloud, secret, or service-control
behavior changed.

### Commands Run

```bash
bash scripts/merlin-task-api.sh status
tail -n 80 logs/merlin-task-api.log
lsof -nP -iTCP:8766 -sTCP:LISTEN || true
gh run list --branch main --limit 3 --json databaseId,headSha,status,conclusion,name,createdAt,url
.venv-test/bin/python -m pytest tests/test_task_endpoint.py tests/test_status_extension.py
bash tests/dashboard-native-chat-smoke.sh
bash tests/dashboard-rooms-smoke.sh
bash tests/dashboard-first-run-smoke.sh
bash tests/dashboard-model-readiness-smoke.sh
bash tests/dashboard-tabs-smoke.sh
git diff --check
```

### Test Output Summary

- `tests/test_task_endpoint.py tests/test_status_extension.py` - 49 passed.
- `bash tests/dashboard-native-chat-smoke.sh` - PASS.
- `bash tests/dashboard-rooms-smoke.sh` - PASS.
- `bash tests/dashboard-first-run-smoke.sh` - PASS.
- `bash tests/dashboard-model-readiness-smoke.sh` - PASS.
- `bash tests/dashboard-tabs-smoke.sh` - PASS.
- `git diff --check` - PASS.
- GitHub Actions for prior identity fix commit `e0c41fa` - PASS.

### Tests Skipped And Why

- Live browser click-through: not run in this slice. Needed to visually confirm
  the side panel feels like a Perplexity-style Room/Space history.
- Raw saved transcript reopen: intentionally not implemented. Reopening raw
  transcript content needs a future policy-gated local read endpoint.

### Failures Found

After `bash scripts/merlin-task-api.sh restart`, a live curl to port 8766 failed
with `curl: (7) Failed to connect`. A later status check reported
`status: stopped`; logs showed recent successful starts plus intermittent bind
errors.

### Failure Category

- Task API 8766
- Launchd/autostart or local service lifecycle
- UX/readiness confusion

### Root Cause Or Current Hypothesis

The task API process can report started after a health check and then exit or be
replaced, likely due to local launchd/manual process coordination or intermittent
bind behavior. This was not fixed in this UI slice because the requested work
was chat/Rooms UX and no service-manager code was changed.

### Fix Applied

- Added Room Save Meter in the chat side panel with a six-prompt recommendation.
- Reset the meter after local Room save.
- Added Route Details side-panel card showing route, staff mode, and technical
  engine alias outside the main chat.
- Added Room History side-panel dropdowns from the read-only Rooms manifest.
- Selecting a saved transcript jumps back into that Room but does not load raw
  transcript content yet.
- Added technical engine alias to the Merlin system prompt so Merlin can answer
  model questions honestly while preserving Merlin as the assistant identity.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

- `tests/dashboard-native-chat-smoke.sh` verifies the Room Save Meter, prompt
  counter state, Room History, side-panel engine detail, and raw transcript
  reopen boundary.
- `tests/test_task_endpoint.py` verifies selected engine alias is included in
  the system prompt as technical route detail while preserving Merlin identity.

### Follow-Up Issues Created Or Recommended

Recommended:

- Add focused issue for Task API restart instability if the stopped-after-start
  behavior repeats.
- Add policy-gated saved transcript read/reopen endpoint for Room History.
- Add browser QA for side-panel Room dropdown and prompt meter behavior.

### Lesson Learned

The main chat should show Merlin, not engine plumbing. Technical model details
belong in an inspectable side panel, and saved transcript reopening needs its
own local read boundary.

### What Not To Repeat Next Time

Do not expose raw local transcript content through the read-only Rooms manifest.
Do not put raw model aliases in the main chat as the product identity.

### Next Recommended Step

Build the policy-gated saved transcript read/reopen endpoint, then wire the Room
History side panel to reopen saved chats safely.

### Local Trusted Beta Impact

Positive. Chat now better guides the user toward saving context and keeps Merlin
identity clean while preserving inspectable route details.

### Public Beta Impact

Positive, but public beta still needs browser evidence and the safe transcript
reopen path.

## 2026-05-10 - Temporary Approval Copy And Security Panel Clarity

### Date/Time

2026-05-10 08:22:45 EDT

### Branch

main

### Starting Commit SHA

`e0c41fac4442ac6073e647b058a931585ed6d3ff`

### Target Issues

- #135 Rooms and local transcript flow.
- #31/#32 approval-gated memory/review principles.
- #106 Wizard HQ product shell clarity.

### Scope

Clarify that dashboard approvals are temporary by default. Room transcript save
now presents an `Allow once` action, and the Security panel explains that
permanent allow belongs in Security Settings only after policy-backed controls
exist.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-rooms-smoke.sh`
- `tests/dashboard-security-center-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None in installer/runtime policy files. Dashboard and static smoke tests only.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_task_endpoint.py tests/test_status_extension.py`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `git diff --check`

### Test Output Summary

- Python tests: 49 passed.
- Native chat smoke: PASS.
- Rooms smoke: PASS.
- Security center smoke: PASS.
- First-run smoke: PASS.
- Model readiness smoke: PASS.
- Tabs smoke: PASS.
- Diff whitespace check: PASS.

### Tests Skipped And Why

Live browser click-through is deferred for this small copy/test slice; static
smokes cover the required user-facing approval semantics.

### Failures Found

None during this copy/test update at time of writing.

### Failure Category

No new failure.

### Root Cause Or Current Hypothesis

The UI phrase `Allow local save` was too broad. The backend approval is scoped
to a specific Room transcript payload, but the copy did not teach the user that
the approval is one-time and Merlin will ask again next time.

### Fix Applied

- Changed Room transcript save action from `Allow local save` to `Allow once`.
- Added one-time transcript approval copy to the Room save panel.
- Updated the Security panel to show `Default approval: allow once` and
  `Permanent allow: settings only`.
- Kept arbitrary approval buttons out of the Security dashboard.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

- `tests/dashboard-rooms-smoke.sh` now requires `Allow once`, one-time approval
  copy, and ask-again behavior.
- `tests/dashboard-security-center-smoke.sh` now requires temporary approval
  language and permanent-allow settings-only language.

### Follow-Up Issues Created Or Recommended

Recommended future issue: design policy-backed permanent approval settings with
clear scope, expiration, revoke controls, audit entries, and fail-closed
behavior. Do not implement permanent allow as a browser-only toggle.

### Lesson Learned

Permission words matter. `Allow local save` sounds like a broad capability,
while `Allow once` matches the actual payload-scoped approval model and better
protects user trust.

### What Not To Repeat Next Time

Do not use broad approval labels when the backend approval is one-time,
payload-scoped, or otherwise limited.

### Next Recommended Step

Run focused dashboard smokes and Python task endpoint tests, then commit the
chat/Rooms/approval clarity slice if all checks pass.

### Local Trusted Beta Impact

Positive. First-time users should better understand that Merlin asks again by
default and permanent allow is not silently enabled.

### Public Beta Impact

Positive, but public beta still needs browser click-through evidence and a
designed permanent approval settings model before offering always-allow
behavior.

## 2026-05-10 - Policy-Gated Saved Room Reopen

### Date/Time

2026-05-10 08:35 EDT

### Branch

main

### Starting Commit SHA

`3256773923c25318c17c87a254e5a7e256c46112`

### Target Issues

- #135 Rooms and local transcript flow.
- #31/#32 approval-gated memory/review principles.
- #106 Wizard HQ product shell.

### Scope

Add a narrow approval-gated saved transcript reopen path. Selecting a saved
Room transcript now prepares a one-time local file-read approval, and `Allow
once` reopens that transcript in Merlin Chat without writing memory or enabling
Room context reuse.

### Files Changed

- `merlin/approval_store.py`
- `merlin/room_store.py`
- `merlin/task_endpoint.py`
- `dashboard/index.html`
- `docs/architecture/MERLIN_ROOMS.md`
- `tests/test_room_store.py`
- `tests/test_task_endpoint.py`
- `tests/dashboard-native-chat-smoke.sh`
- `tests/dashboard-rooms-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

- `merlin/task_endpoint.py`: touched to add policy-gated read endpoints only.
- No installer, cloud, telemetry, model download, or browser execution behavior
  changed.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_task_endpoint.py tests/test_status_extension.py`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `git diff --check`

### Test Output Summary

- Python tests: 63 passed.
- Native chat smoke: PASS.
- Rooms smoke: PASS.
- Security center smoke: PASS.
- First-run smoke: PASS.
- Model readiness smoke: PASS.
- Tabs smoke: PASS.
- Merlin status smoke: PASS.
- Readiness smoke: PASS.
- Settings policy smoke: PASS.
- Diff whitespace check: PASS.

### Tests Skipped And Why

- Live browser click-through is deferred until after the local server is running
  cleanly. Static dashboard smokes and backend unit tests cover the policy
  contract for this slice.

### Failures Found

One command/read failure during inspection:

```text
sed: merlin/rooms.py: No such file or directory
```

### Failure Category

- Documentation mismatch
- Test design gap

### Root Cause Or Current Hypothesis

I looked for `merlin/rooms.py` from memory, but the actual module is
`merlin/room_store.py`. This was an operator context mistake, not a repo
runtime defect.

### Fix Applied

- Continued against the correct `merlin/room_store.py` module.
- Recorded the mismatch here so future sessions search `room_store.py` first.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

- `tests/test_room_store.py` verifies selected transcript read rejects unsafe
  transcript ids and returns User/Merlin sections without memory/context reuse.
- `tests/test_task_endpoint.py` verifies transcript read requires a matching
  file-read approval, raw content is absent from approval/audit metadata, and
  the same approval cannot be reused.
- `tests/dashboard-native-chat-smoke.sh` verifies the saved transcript reopen
  UI uses the approval-gated endpoints.
- `tests/dashboard-rooms-smoke.sh` verifies the Rooms doc and dashboard expose
  the one-time saved chat reopen boundary.

### Follow-Up Issues Created Or Recommended

Recommended: add browser automation that saves a Room transcript, clicks Room
History, approves the one-time local read, and confirms the reopened transcript
appears in chat.

### Lesson Learned

Room reopen is a file-read permission, not a status manifest feature. Raw
transcript content should only cross into the browser after a Task API approval
that is scoped to the selected Room and transcript id.

### What Not To Repeat Next Time

Do not load raw transcript content through `/status/rooms`. Do not use stale
module names when the repo already has `merlin/room_store.py`.

### Next Recommended Step

Run the broader dashboard/release smoke set, then commit if checks remain
green. After that, add browser click-through evidence for save -> reopen.

### Local Trusted Beta Impact

Positive. Saved Room chats can now be reopened in the product flow with a
visible one-time approval boundary.

### Public Beta Impact

Positive, but public beta still needs browser evidence, visual polish review,
and installer retest evidence after dashboard behavior changes.

## 2026-05-10 - In-Session Room Transcript Continuity

### Date/Time

2026-05-10 08:49 EDT

### Branch

main

### Starting Commit SHA

`748bbb06690aa25d955b5857481835b24fc6de72`

### Target Issues

- #135 Rooms and local transcript flow.
- #106 Wizard HQ product shell.
- #134 product value checkpoint.

### Scope

Keep the active Merlin Chat transcript visible for the whole browser session and
save the full in-session thread to a Room transcript instead of only the latest
single exchange. Reopened Room transcripts now reconstruct saved exchanges into
chat rows.

### Files Changed

- `dashboard/index.html`
- `tests/dashboard-native-chat-smoke.sh`
- `docs/release/evidence/2026-05-08-local-trusted-beta-progress.md`

### Protected Files Touched

None. This is dashboard browser state/rendering and static smoke coverage only.
The working Room save backend contract was preserved.

### Commands Run

- `.venv-test/bin/python -m pytest tests/test_room_store.py tests/test_task_endpoint.py tests/test_status_extension.py`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-rooms-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `git diff --check`

### Test Output Summary

- Python tests: 63 passed.
- Native chat smoke: PASS.
- Rooms smoke: PASS.
- Security center smoke: PASS.
- Diff whitespace check: PASS.

### Tests Skipped And Why

Live browser click-through remains the next validation item. This slice adds
static coverage for transcript continuity and preserves backend tests.

### Failures Found

No new command failure.

### Failure Category

No new failure.

### Root Cause Or Current Hypothesis

The save button worked, but the chat UI treated each response as a replaceable
card instead of a persistent session transcript. That made Room History feel
like metadata instead of a recoverable conversation.

### Fix Applied

- Added in-session `currentChatTranscript` browser state.
- Rendered the whole active transcript in Merlin Chat until New Conversation.
- Saved the full in-session thread into the existing Room transcript save path.
- Reconstructed saved Room transcript content back into chat rows after the
  one-time read approval.
- Kept saved Room transcripts separate from approved memory and context reuse.

### Retest Result

PASS for all commands listed above.

### Regression Test Added Or Updated

- `tests/dashboard-native-chat-smoke.sh` now requires active transcript state,
  full-thread Room save formatting, saved transcript reconstruction, and the
  restored-session copy.

### Follow-Up Issues Created Or Recommended

Recommended: run browser automation for multi-turn chat -> save Room -> reopen
Room transcript -> verify the same multi-turn thread appears in chat.

### Lesson Learned

A working save button is not enough. Users expect the chat session to behave
like a real conversation thread and expect Room History to recover that thread.

### What Not To Repeat Next Time

Do not collapse chat into a single latest-response card after the first message.
Do not treat saved Room History as metadata only when the product promise is
local conversation continuity.

### Next Recommended Step

Run browser click-through evidence for the complete Room lifecycle.

### Local Trusted Beta Impact

Positive. Merlin Chat now behaves closer to the expected Apple-like chat
experience while keeping Room save/read approval boundaries intact.

### Public Beta Impact

Positive, but public beta still needs visual browser evidence and installer
retest after dashboard behavior changes.
