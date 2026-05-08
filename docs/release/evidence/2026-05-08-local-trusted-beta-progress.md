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
