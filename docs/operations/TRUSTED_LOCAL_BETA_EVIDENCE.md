# Trusted Local Beta Evidence Pack

Last updated: 2026-05-08

GitHub issue: #97
Milestone: `v3.0 — Public Product Release`

## Purpose

Merlin AI is not beta-ready until the local-first install, uninstall, reinstall,
upgrade, dashboard readiness, and privacy behavior are proven with repeatable
evidence. This document is the runbook and evidence checklist for that signoff.

The first target is the 8GB Mac low/core path. Higher-memory validation follows
after the low/core path is green.

## Release Candidate Metadata

Fill this block for each beta validation run:

| Field | Value |
|---|---|
| Date | TODO |
| Tester | TODO |
| Machine | TODO |
| OS version | TODO |
| RAM / hardware tier | TODO |
| Commit SHA | TODO |
| CI run URL | TODO |
| Profile | `core` |
| Model pulls | `HOME_AI_SKIP_MODEL_PULLS=true` |
| Network state | TODO: online for dependency install / offline launch test |
| Result | TODO: pass / fail / blocked |

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
```

Expected evidence:

- installer exits 0
- profile is `core`
- model pulls are skipped
- Docker services start for dashboard, Open WebUI, LiteLLM, and Qdrant
- native Ollama is used on macOS
- Merlin status API is available on port 8765 after launchd/manual start
- Merlin task API is available on port 8766 after launchd/manual start
- no cloud/API keys are required
- no hidden telemetry is enabled

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
```

Manual screenshots to capture:

- package welcome screen with Merlin M logo
- terminal installer header
- Wizard HQ Startup Readiness with all services running
- Wizard HQ with task API down: route/task stages degraded
- Wizard HQ with Qdrant down: memory vault degraded
- Wizard HQ with Ollama down: local AI brain degraded/warming
- Wizard HQ Sovereignty Status showing local-only/cloud-disabled posture

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
bash cli/wizard merlin magic-plan "prepare a local-first beta readiness checklist"
bash cli/wizard merlin audit recent
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
| CI baseline | `gh run list --branch main --limit 3` | latest run green | TODO | TODO | TODO |
| Clean install | install command above | exit 0 | TODO | TODO | TODO |
| Uninstall | `pkg/scripts/uninstall.sh --yes --keep-files` | exit 0 | TODO | TODO | TODO |
| Reinstall | install command above | exit 0 | TODO | TODO | TODO |
| Upgrade | `bash scripts/upgrade.sh --profile core` | exit 0 | TODO | TODO | TODO |
| Offline launch | offline commands above | local services start or degrade honestly | TODO | TODO | TODO |
| Service health | doctor + curl checks | 0 failures | TODO | TODO | TODO |
| Dashboard readiness | screenshots + smokes | no fake ready | TODO | TODO | TODO |
| Privacy defaults | policy/log review | no cloud, no telemetry | TODO | TODO | TODO |
| Model downloads | installer policy smoke | no surprise pulls | TODO | TODO | TODO |
| Magic Mode | plan/audit smokes | plan-only | TODO | TODO | TODO |
| Startup logs | log review | no release-blocking errors | TODO | TODO | TODO |

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
