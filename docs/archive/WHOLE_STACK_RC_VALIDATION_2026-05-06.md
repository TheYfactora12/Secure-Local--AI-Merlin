# Whole-Stack Release-Candidate Validation — 2026-05-06

## Summary

- GitHub issue: #63
- Starting commit: `67b3ab1`
- Hardware: 8GB Mac, low tier
- Profile: `core`
- Model pulls: skipped by installer policy; existing local models were used for live checks
- Result: Passed after three release-candidate defects were fixed in the same validation session

## Release Policy

Issue #1 was closed as the v1.0 runtime installer gate. The remaining trusted `.pkg`
work is split to #64 because Developer ID Installer/notarization is a public
distribution trust policy issue, not a runtime installer defect.

## Commands Run

```bash
bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive
bash scripts/merlin-status-api.sh run
PYTHONPATH=. .venv/bin/python -m merlin.task_endpoint
.venv/bin/python merlin/config_loader.py
.venv-test/bin/python -m pytest tests/test_config_loader.py tests/test_memory_manager.py tests/test_policy_engine.py tests/test_router.py tests/test_session_memory_bridge.py tests/test_status_extension.py tests/test_task_endpoint.py --ignore=tests/test_memory_manager_integration.py -k 'not integration and not live' -q
bash scripts/doctor.sh
bash tests/core-live-smoke.sh
bash tests/automation-profile-smoke.sh
bash tests/doctor-smoke.sh
bash tests/redact-smoke.sh
bash tests/report-bug-smoke.sh
bash tests/installer-merlin-api-policy-smoke.sh
bash tests/merlin-status-api-smoke.sh
curl -fsS --max-time 60 http://localhost:8766/task -H 'Content-Type: application/json' -d '{"input":"explain how Qdrant works in one sentence","session_id":"rc-63"}'
curl -fsS --max-time 3 http://localhost:8766/status/memory
```

## Findings Fixed

1. The installer did not create a Merlin Python runtime, so system `python3` could
   not run `merlin/config_loader.py` or `merlin/task_endpoint.py` without manually
   installed dependencies.
   Fix: add `requirements-merlin.txt` and install a lightweight `.venv` during
   `install.sh`.

2. Running `python -m merlin.task_endpoint` served the `__main__` module's app
   instance and did not register the `/status/*` router.
   Fix: run uvicorn from the import string `merlin.task_endpoint:app`.

3. After removing Docker volumes while keeping files, `.wizard-bootstrapped`
   could make the installer skip Qdrant collection initialization.
   Fix: re-run bootstrap if either `home_ai_memory` or canonical `merlin_session`
   is missing, and create canonical Merlin collections during bootstrap.

4. Live `/task` calls degraded because the Task API did not send the local
   `LITELLM_MASTER_KEY` to LiteLLM.
   Fix: read the key from environment or local `.env` and send only the
   Authorization header. Secrets are never logged.

## Validation Results

- Installer low/core run: passed.
- Merlin Python runtime install: passed.
- Config validation with installer `.venv`: passed.
- Offline Merlin pytest suite: 97 passed.
- Doctor: 53 passed, 2 warnings, 0 failures.
- Core live smoke: 18 passed, 0 warnings, 0 failures.
- Static smoke subset: passed.
- Status API 8765: reachable, `execution_allowed=false`.
- Task API 8766: `/status/routes` reachable, route total 5.
- Task API live `/task`: approved true, degraded false, route `general`.
- Qdrant collections: legacy and canonical collections present, including
  `merlin_session`, `merlin_user`, `merlin_documents`, `merlin_tools`, and
  `merlin_audit`.
- Cloud defaults: OpenAI, Anthropic, Perplexity, and GitHub token keys remained
  empty in doctor output.

## Expected Warnings

- gitleaks pre-commit hook missing locally.
- 8GB low-tier warning: avoid OpenHands, full search stack, n8n automation, and
  14B+ models by default.

## Not Covered

- Full optional profiles (`search`, `automation`, `coding`) were not enabled on
  this 8GB validation run.
- Public Developer ID Installer/notarization remains deferred to #64.
- n8n workflow live execution was not required; the session memory bridge remains
  inactive by default and is covered by offline static tests.
