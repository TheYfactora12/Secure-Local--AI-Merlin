# Phase 3 Live End-to-End Validation

Date: 2026-05-07
Machine: macOS, 8GB RAM, low tier
Scope: core local stack, Merlin task API, Phase 3 outcome learning loop

## Result

Live end-to-end validation passed for the low-tier core path.

Validated:

- Docker core services were running: `dashboard`, `open-webui`, `litellm`, `qdrant`.
- Native Ollama was reachable on `localhost:11434`.
- Installed local models were detected: `qwen2.5:7b` and `nomic-embed-text`.
- Core live smoke passed: 18 checks, 0 warnings, 0 failures.
- Read-only Merlin status API served `/healthz` on port 8765 with `execution_allowed=false`.
- Merlin task API served `/status/routes` and `/task` on port 8766.
- `/task` completed a local LiteLLM/Ollama response with `degraded=false`.
- Memory write was correctly skipped by default because `memory_write` requires approval.
- A route requiring code execution returned HTTP 403 with approval gates.
- Qdrant status panels reported canonical memory collections with `degraded=false`.
- One explicit approved outcome wrote to `skill_outcomes`.
- `wizard skills` read the approved outcome from Qdrant.
- Skill bias safety tests passed: safe routes cannot be statistically biased into `openhands` or `n8n`.

## Commands Run

```bash
docker info
bash scripts/doctor.sh
bash cli/wizard skills
bash scripts/merlin-status-api.sh start
PYTHONPATH=. .venv-test/bin/python -m merlin.task_endpoint
bash tests/core-live-smoke.sh
MERLIN_CREATE_CANONICAL_COLLECTIONS=true bash scripts/init-qdrant.sh
curl -fsS --max-time 3 http://127.0.0.1:8765/healthz
curl -fsS --max-time 3 http://127.0.0.1:8766/status/routes
curl -sS --max-time 120 http://127.0.0.1:8766/task
curl -sS --max-time 10 http://127.0.0.1:8766/task
curl -fsS --max-time 5 http://127.0.0.1:8766/status/approvals
curl -fsS --max-time 5 http://127.0.0.1:8766/status/memory
.venv-test/bin/python -m pytest tests/test_router_skill_bias.py tests/test_skill_scorer.py tests/test_outcome_observer.py -v --tb=short
```

## Key Observations

The successful `/task` response used the `general` route, target `litellm`, and a local model alias. The response was non-degraded and route audit writing succeeded.

The task response reported:

- `approved=true`
- `degraded=false`
- `memory_written=false`
- `audit_written=true`

`memory_written=false` is the expected secure default because the persistent session memory path requires the `memory_write` approval gate.

The explicit approved outcome write reported:

- `route_id=general`
- `staff_mode=operator`
- `skill_domain=research`
- `outcome_rating=approved`
- `audit_written=true`
- `skill_outcome_written=true`

Qdrant collection `skill_outcomes` was created with:

- vector size: 384
- distance: Cosine
- points count: 1

`wizard skills` then reported:

```text
Outcomes read: 1
litellm              research        n/a 0.000     1 unknown
```

The score is intentionally `n/a` because the skill scorer requires at least 3 approved outcomes before producing a score or route bias.

## Safety Checks

Policy gate check:

- Input: `write a python function to parse JSON`
- Result: HTTP 403
- Gates returned: `service_start`, `file_read`, `file_write`, `shell_command`, `git_operation`, `openhands_task`

Approval status panel:

- total gates: 14
- open count: 0
- closed count: 14

Focused regression tests:

- `tests/test_router_skill_bias.py`
- `tests/test_skill_scorer.py`
- `tests/test_outcome_observer.py`

Result: 23 passed.

Doctor after both APIs were live:

- 53 checks passed
- 2 warnings
- 0 failures

Warnings were expected:

- gitleaks pre-commit hook not installed locally
- 8GB low-tier warning for heavy optional profiles

## Notes

The lifecycle-managed status API smoke test passed. In the Codex sandbox, the detached `scripts/merlin-status-api.sh start` process did not remain available for the broader live run, so the validation used a foreground status API process for port 8765. This is a sandbox/runtime-process limitation, not a status API code failure.

No cloud API keys were used. No model downloads were triggered. No installer files were modified.

## Remaining Follow-Up

- Add `skill_outcomes` to the canonical memory manifest before a packaged release if Phase 3E becomes part of the release baseline.
- Run the same live pass after login/reboot using launchd-managed services, not foreground test processes.
- Accumulate at least 3 approved outcomes for one domain before validating non-`n/a` skill scoring and route bias in live mode.
