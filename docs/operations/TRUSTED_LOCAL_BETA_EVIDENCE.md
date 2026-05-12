# Trusted Local Beta Evidence Pack

Last updated: 2026-05-12

GitHub issue: #97
Milestone: `v3.0 — Public Product Release`

## Purpose

Merlin AI is not beta-ready until the local-first install, uninstall,
reinstall, upgrade, dashboard readiness, and privacy behavior are proven with
repeatable evidence. Merlin is the assistant inside the product; the product
signoff belongs to Merlin AI.

The first target is the 8GB Mac low/core path. Higher-memory validation follows
after the low/core path is green.

Failure learning is mandatory. Use
`docs/operations/FAILURE_LEARNING_LOOP.md` for every failed command, install,
service start, smoke test, UI check, or confusing user experience found during
this evidence run.

## Release Stage Gates

| Stage | Meaning | Required Evidence | Current Status |
|---|---|---|---|
| Engineering Alpha | Developer-facing repo is coherent and CI is green. | CI, static smokes, Python unit tests, protected installer checks. | Passed on current `main`. |
| Local Trusted Beta | Controlled local install is proven on owned hardware. | This evidence pack filled for 8GB low/core with screenshots, logs, uninstall/reinstall/upgrade, offline launch, and no-cloud checks. | Not signed off until the manual run is complete. |
| Public Beta | External users can install with clear trust signals. | Local Trusted Beta evidence, public onboarding, known blockers resolved, and package/signing state explained. | Not ready. |
| Public Release | Broad distribution path is supportable. | Public Beta evidence, Developer ID/notarization path, release artifacts, support docs, and rollback plan. | Not ready. |

## Full Installer Retest Trigger

Run this full evidence pack whenever any of these change:

- installer branding or package resources
- startup/loading/readiness UI
- dashboard onboarding or first-action UX
- launchd behavior
- status API or task API startup behavior
- service startup order or profile separation
- package signing/notarization behavior
- before any Local Trusted Beta, Public Beta, or Public Release signoff

## Release Candidate Metadata

Fill this block for each beta validation run. The current entry is a named
package/onboarding verification run, not a full beta signoff.

| Field | Value |
|---|---|
| Date | 2026-05-12 |
| Tester | Kevin Medeiros with Codex-assisted verification |
| Machine | `Kevins-MBP`, Apple M2 |
| OS version | macOS 26.4.1, build 25E253 |
| RAM / hardware tier | 8 GB / low-core target |
| Commit SHA | Package verification: `744f739`; evidence rollup: `e28640a` |
| CI run URL | `https://github.com/TheYfactora12/Secure-Local--AI-Merlin/actions/runs/25713160707` |
| Profile | `core` |
| Model pulls | `HOME_AI_SKIP_MODEL_PULLS=true` |
| Network state | Online for package install verification; offline launch not rerun in this entry |
| Result | Package/onboarding verification passed; full beta signoff still blocked pending the remaining table rows below |

## Current Evidence Rollup - 2026-05-12

This rollup records what has evidence today. It does not declare Local Trusted
Beta, Public Beta, or Public Release readiness.

| Area | Current evidence | Status |
|---|---|---|
| Latest CI on `main` | GitHub Actions run `25712920056` on commit `744f739` | Pass |
| Package install verification | `docs/release/evidence/2026-05-12-package-check-system-recovery-install.md` | Pass: 17 pass, 0 warn, 0 fail |
| Installed first-run onboarding | `docs/release/evidence/2026-05-12-package-check-system-recovery-install.md` | Pass: installed dashboard includes `Check System`, `Service details`, `Startup checks`, and recovery guidance |
| Package uninstall / reinstall loop | `docs/release/evidence/2026-05-11-package-uninstall-verification.md` | Pass for keep-files uninstall plus package reinstall; full destructive purge still needs explicit validation |
| Upgrade / rollback path | `docs/release/evidence/2026-05-11-safe-upgrade-progress.md` | Documented and tested for the safe upgrade path |
| Privacy / no surprise model pulls | README, installer policy smokes, and package evidence keep cloud/model pulls opt-in | Pass for documented/default posture; continue log review in release candidate runs |
| Developer ID signing / notarization | Deferred by product decision; tracked separately in #64 | Not part of #37 closure; still required before broad public release |

Remaining release-signoff gaps:

- Run the full evidence table below as a named release candidate run on the
  target low/core Mac and record tester, machine, OS, RAM, commit, CI URL, and
  result.
- Run a full destructive purge validation only after explicit approval because
  it can remove shared tools such as Docker Desktop, Ollama, and Homebrew.
- Keep Developer ID signing/notarization deferred until #64 is intentionally
  resumed.

## CI Baseline

Before manual beta validation, current `main` must have a green CI run.

```bash
git rev-parse --short HEAD
gh run list --branch main --limit 3
gh run view --log-failed
```

Required CI/static gates:

- ShellCheck for all shell scripts
- `install.sh` syntax and dry-run checks
- Docker Compose validation
- YAML/PLIST validation
- n8n workflow JSON validation
- static smoke tests
- Python Merlin Staff Core offline pytest suite
- regex secret scan
- gitleaks secret scan

## 8GB Low/Core Clean Install

Use this first. It preserves the repo checkout but removes runtime data.

```bash
bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true \
  bash install.sh --profile core --skip-model-pulls --non-interactive
bash launchd/install-launchd.sh
sleep 35
bash scripts/doctor.sh
```

Expected evidence:

- installer exits 0
- profile is `core`
- model pulls are skipped
- Docker services start for dashboard, Open WebUI, LiteLLM, and Qdrant
- native Ollama is used on macOS
- Merlin status API is available on port 8765 after launchd/manual start
- Merlin task API is available on port 8766 after launchd/manual start
- Wizard HQ explains that non-interactive installs leave Merlin API panels
  warming/degraded until `bash launchd/install-launchd.sh` or the manual API
  start commands complete
- launchd warmup language is visible: Status API starts after roughly 35
  seconds and Task API after roughly 40 seconds
- no cloud/API keys are required
- no hidden telemetry is enabled

## 16GB+ Matrix Placeholder

After the 8GB low/core run is green, repeat the evidence pack on a 16GB+ Mac.

Additional evidence to capture:

- hardware tier reported as `base` or higher
- optional search profile can be started intentionally
- no OpenHands or n8n profile starts by default
- model recommendations remain explicit and do not auto-download without
  confirmation

## Uninstall, Reinstall, And Upgrade

Run all three before beta signoff:

```bash
# Uninstall without deleting the repo checkout
bash pkg/scripts/uninstall.sh --yes --keep-files

# Reinstall core path without model pulls
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true \
  bash install.sh --profile core --skip-model-pulls --non-interactive

# Upgrade path
bash scripts/upgrade.sh --profile core
```

Evidence to capture:

- commands and exit codes
- before/after `docker compose ps`
- `.env` backup behavior
- launchd agent status after reinstall
- any warnings from `bash scripts/doctor.sh`

## Service Health Validation

```bash
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
bash scripts/doctor.sh
bash tests/core-live-smoke.sh
bash tests/merlin-status-api-smoke.sh
bash tests/merlin-task-api-smoke.sh
curl -fsS --max-time 3 http://localhost:8888 >/dev/null
curl -fsS --max-time 3 http://localhost:8765/healthz
curl -fsS --max-time 3 http://localhost:8766/status/routes
curl -fsS --max-time 3 http://localhost:8766/status/approvals
curl -fsS --max-time 3 http://localhost:8766/status/memory
curl -fsS --max-time 3 http://localhost:6333/healthz
curl -fsS --max-time 3 http://localhost:4000/health/readiness
curl -fsS --max-time 3 http://localhost:3000 >/dev/null
FINISHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "startup_timing=${STARTED_AT}..${FINISHED_AT}"
```

Expected evidence:

- `doctor.sh` has 0 failures
- core live smoke has 0 failures
- Wizard HQ reachable on `localhost:8888`
- status API reachable on `localhost:8765`
- task API reachable on `localhost:8766`
- Qdrant, LiteLLM, and Open WebUI reachable
- warnings are documented with issue links when release-relevant

## Dashboard Readiness Validation

Wizard HQ must never fake readiness.

```bash
bash tests/dashboard-readiness-smoke.sh
bash tests/dashboard-merlin-status-smoke.sh
bash tests/dashboard-security-center-smoke.sh
bash tests/dashboard-first-run-smoke.sh
```

Optional automated browser evidence:

```bash
bash scripts/setup-browser-qa.sh
.venv-test/bin/python scripts/dashboard-browser-qa.py
```

Expected evidence:

- desktop 1280px screenshots
- mobile 375px screenshots
- composer typed-state validation
- mode selector validation
- search chip toggle validation
- summary JSON under `docs/release/evidence/assets/<date>-wizard-hq-browser-qa/`

Manual screenshots to capture:

- package welcome screen with Merlin M logo
- terminal installer header
- Wizard HQ Startup Readiness with all services running
- Wizard HQ with task API down: route/task stages degraded
- Wizard HQ with Qdrant down: memory vault degraded
- Wizard HQ with Ollama down: local AI brain degraded/warming
- Wizard HQ Sovereignty Status showing local-only/cloud-disabled posture

Store screenshots under `docs/release/evidence/assets/<date>/` or attach them
to the relevant GitHub issue comment if they should not live in git.

Do not mark beta-ready if a service is down and Wizard HQ presents it as ready.

## Offline Launch Validation

After Docker images and Homebrew/native dependencies are already present, test
offline behavior:

```bash
# Disconnect from network manually, then:
docker compose up -d dashboard open-webui litellm qdrant
bash scripts/doctor.sh
curl -fsS --max-time 3 http://localhost:8888 >/dev/null
```

Expected evidence:

- core services launch from local images/dependencies
- no cloud/API calls are required
- no surprise model downloads occur
- Wizard HQ shows degraded/warming if a dependency cannot start offline

## No Cloud Calls And No Surprise Model Downloads

```bash
bash tests/installer-model-pull-policy-smoke.sh
bash tests/openwebui-local-first-smoke.sh
bash tests/installer-branding-smoke.sh
bash tests/sast-gitleaks-smoke.sh
```

Log review checklist:

- no `api.openai.com`
- no `api.anthropic.com`
- no hosted Langfuse URL
- no hidden telemetry endpoint
- no model pull unless `scripts/add-model.sh` or equivalent explicit command was run
- API keys are presence-only in reports and never logged

## Magic Mode And Audit Validation

Magic Mode remains plan-only for beta readiness.

```bash
bash tests/merlin-magic-plan-smoke.sh
bash tests/merlin-audit-view-smoke.sh
bash cli/wizard merlin magic plan "prepare a local-first beta readiness checklist"
bash cli/wizard merlin audit list
```

Expected evidence:

- Magic Mode creates a plan only
- no shell/file/browser/API execution occurs
- audit view is local and redacted
- approval gates remain visible and fail-closed

## Startup Logs Review

Capture and review:

```bash
tail -100 logs/*.log 2>/dev/null || true
docker compose logs --tail=100 dashboard open-webui litellm qdrant
launchctl list | grep -E 'homeai|merlin' || true
```

Look for:

- `ERROR` or `CRITICAL`
- bind/port conflicts
- missing config
- unexpected external network attempts
- unredacted secrets
- repeated restart loops
- launchd agents not loaded after login

## Evidence Table

| Area | Command / artifact | Expected | Actual | Pass? | Issue |
|---|---|---|---|---|---|
| CI baseline | `gh run list --branch main --limit 3` | latest run green | Run `25713160707` passed on `e28640a` | Pass | None |
| Clean install | `scripts/run-pkg-install-verification.sh ./merlin-ai-0.8.6.pkg` | exit 0 and core endpoints green | Package install verification passed with 17 pass, 0 warn, 0 fail; see `docs/release/evidence/2026-05-12-package-check-system-recovery-install.md` | Pass | None |
| Uninstall | `pkg/scripts/uninstall.sh --yes --keep-files` | exit 0 | Keep-files uninstall verified; endpoints stopped as expected except native Ollama preserved by design | Pass | None |
| Reinstall | package verification after keep-files uninstall | exit 0 | Package reinstall verification passed with 17 pass, 0 warn, 0 fail; see `docs/release/evidence/2026-05-11-package-uninstall-verification.md` | Pass | None |
| Upgrade | `bash scripts/upgrade.sh --profile core` | exit 0 | Safe upgrade/rollback path documented and tested; see `docs/release/evidence/2026-05-11-safe-upgrade-progress.md` | Pass | None |
| Offline launch | local-image restart from installed runtime | local services start or degrade honestly | Local-image restart passed with `--pull never`; Open WebUI warmed on first probe, then all endpoints returned `200`; see `docs/release/evidence/2026-05-12-local-image-restart-validation.md` | Partial pass | True network-disconnected launch still needs manual validation |
| Service health | package verification endpoint checks | 0 failures | Dashboard, Open WebUI, LiteLLM, Qdrant, Ollama, status API, and task API checks passed in package verification | Pass | None |
| Dashboard readiness | installed dashboard copy checks and smokes | no fake ready | Installed dashboard includes `Check System`, `Service details`, `Startup checks`, warming/recovery copy; dashboard/readme smokes passed | Pass | None |
| Privacy defaults | policy/log review | no cloud, no telemetry | README and dashboard preserve local-first/no-cloud guidance; no cloud-provider setup required for package verification | Pass with continued log review required | None |
| Model downloads | installer policy smoke/package run | no surprise pulls | Model pulls remain explicit; no package evidence indicates surprise model download | Pass with continued log review required | None |
| Magic Mode | plan/audit smokes | plan-only | Not rerun in the 2026-05-12 package/onboarding verification entry | Blocked for beta signoff | Needs named Magic Mode/audit validation |
| Startup logs | package verification log | no release-blocking errors | Local package verification log recorded; final result was 17 pass, 0 warn, 0 fail after expected warmup attempts | Pass | None |

## Blocker Rule

If any row fails, create or update a GitHub issue before beta signoff. Include:

- affected milestone
- exact command
- expected vs actual result
- logs/screenshots
- risk level
- rollback or mitigation

Do not close #95 or call v3.0 beta-ready until this evidence pack has a passing
8GB low/core run and all release-blocking issues are linked.

## Failure Learning Appendix

For each failure, append a known failure pattern entry to the dated evidence note
or a dedicated follow-up runbook. Required format:

```markdown
### Failure Pattern: <short name>

**Date first seen:**
YYYY-MM-DD

**Category:**
Installer / Dashboard / API / Memory / CI / etc.

**Symptoms:**
What the user or test saw.

**Command or action:**
Exact command or action that exposed it.

**Expected:**
What should have happened.

**Actual:**
What happened.

**Likely root cause:**
Best known explanation.

**Confirmed root cause:**
Fill in once proven.

**Fix:**
What fixed it.

**Regression test:**
Test added or updated.

**Retest result:**
Pass/fail and date.

**Do not repeat:**
What future Codex sessions must avoid.

**Related issue/PR/commit:**
Links or identifiers.
```

Release impact must be one of: No release impact, Local Trusted Beta blocker,
Public Beta blocker, Public Release blocker, or Unknown needs investigation.
Installer, uninstall, reinstall, upgrade, no-cloud default, surprise model
download, service startup, Wizard HQ readiness, privacy, and local-only failures
are Local Trusted Beta blockers until proven otherwise.
