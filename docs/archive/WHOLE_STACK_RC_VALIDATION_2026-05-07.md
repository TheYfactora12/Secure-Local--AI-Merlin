# Whole-Stack Release-Candidate Validation — 2026-05-07

## Summary

- GitHub issue: #62
- Commit validated: `d5f28b2`
- Hardware: macOS, 8GB RAM, low tier
- Profile: `core`
- Model pulls: skipped by policy with `HOME_AI_SKIP_MODEL_PULLS=true`
- Result: Passed with documented expected warnings only

This validation re-ran the v1.0 release gate after the separate launchd-managed
Merlin task API on port 8766 was added. It complements the earlier fresh-install
RC validation in `docs/archive/WHOLE_STACK_RC_VALIDATION_2026-05-06.md`.

## Fresh-Data Install Path

The validation used the safe fresh-data path: stop services, remove Docker
volumes, keep the checked-out repo files, then run the current installer from
`main`.

```bash
bash pkg/scripts/uninstall.sh --yes --keep-files --remove-data
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true \
  bash install.sh --profile core --skip-model-pulls --non-interactive
bash launchd/install-launchd.sh
```

Uninstall notes:

- Docker containers and stack volumes were removed.
- `.env` was backed up automatically.
- Docker Desktop, Homebrew, Ollama, and Ollama models were preserved.
- `pkgutil --forget` was skipped because admin privileges were not available;
  this does not affect the script installer path.

Install notes:

- Low/core profile was selected for 8GB RAM.
- Optional cloud API key prompts were skipped in non-interactive mode.
- Ollama model pulls were skipped.
- Core Docker services started: dashboard, Open WebUI, LiteLLM, Qdrant.
- Bootstrap detected missing Qdrant collections and re-ran initialization.
- Legacy/current and canonical Merlin Qdrant collections were recreated.
- Non-interactive install did not directly start Merlin APIs; launchd setup was
  run explicitly after install.

## Commands Run

```bash
.venv/bin/python merlin/config_loader.py
.venv-test/bin/python -m pytest \
  tests/test_config_loader.py \
  tests/test_memory_manager.py \
  tests/test_policy_engine.py \
  tests/test_router.py \
  tests/test_session_memory_bridge.py \
  tests/test_status_extension.py \
  tests/test_task_endpoint.py \
  --ignore=tests/test_memory_manager_integration.py \
  -k 'not integration and not live' \
  -q
bash tests/master-prompt-smoke.sh
bash tests/doctor-smoke.sh
bash tests/merlin-task-api-smoke.sh
bash tests/core-live-smoke.sh
.venv-test/bin/python -m pytest tests/test_session_memory_bridge.py -q
bash scripts/doctor.sh
curl -fsS --max-time 3 http://127.0.0.1:8765/healthz
curl -fsS --max-time 3 http://127.0.0.1:8766/status/routes
curl -fsS --max-time 3 http://127.0.0.1:8766/status/approvals
curl -fsS --max-time 3 http://127.0.0.1:8766/status/memory
curl -fsS --max-time 60 http://127.0.0.1:8766/task \
  -H 'Content-Type: application/json' \
  -d '{"input":"explain how Qdrant works in one sentence","session_id":"rc-62-fresh"}'
```

## Validation Results

- Config loader: passed, `All configs valid`.
- Offline Merlin Python suite: 108 passed.
- Session memory bridge static tests: 16 passed.
- Doctor smoke: 13 passed, 0 failed.
- Core live smoke: 18 passed, 0 warnings, 0 failures.
- Doctor after fresh-data reinstall: 52 passed, 3 warnings, 0 failures.
- Dashboard reachable on port 8888.
- Open WebUI reachable on port 3000.
- LiteLLM readiness reachable on port 4000.
- Qdrant health reachable on port 6333.
- Native Ollama reachable on port 11434.
- Status API reachable on port 8765.
- Task API reachable on port 8766.
- `GET /healthz` on port 8765 returned `execution_allowed=false` and
  `side_effects=none`.
- `GET /status/routes` on port 8766 returned 5 routes.
- `GET /status/approvals` on port 8766 returned 14 closed approval gates.
- `GET /status/memory` on port 8766 returned `degraded=false` and recreated
  Qdrant collections, including `documents` at 1536 dimensions and Merlin
  collections at 768 dimensions.
- Live `POST /task` on port 8766 returned `approved=true`, `degraded=false`,
  `route_id=general`, and `memory_written=false`.
- Session memory bridge remained importable and inactive by default:
  `active=false` in `n8n-workflows/06-session-memory-bridge.json`.
- Cloud/API keys remained empty according to `doctor`.
- No automatic model pulls were performed.

## Expected Warnings

- gitleaks pre-commit hook is not installed locally.
- 8GB low-tier warning: avoid OpenHands, full search stack, n8n automation, and
  14B+ models by default.
- Doctor log scan found one historical local runtime log line from an earlier
  sandbox-blocked foreground task API start attempt. This was not reproduced by
  the fresh-data install path or launchd validation.

## Follow-Up Issues

- #64 remains the public Developer ID Installer signing and notarization path.
- Optional profile live tests for search, automation, and coding remain outside
  the 8GB low/core v1.0 release gate.

## Conclusion

The v1.0 low/core release gate is green on this 8GB Mac after fresh-data
reinstall. The installer remains protected, local-first defaults are intact,
port 8765 remains read-only, port 8766 serves the execution-aware FastAPI task
surface, and no release-blocking defect was found.
