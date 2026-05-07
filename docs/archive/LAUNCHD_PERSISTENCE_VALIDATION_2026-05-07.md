# launchd Persistence Validation

Date: 2026-05-07
Machine: macOS, 8GB RAM, low tier
Scope: macOS LaunchAgents for Docker, core stack, read-only Merlin status API, and Merlin task API

## Result

launchd persistence validation passed for the shipped v1.0 LaunchAgent scope and the
separate Merlin task API LaunchAgent added by #75.

Validated:

- `launchd/install-launchd.sh` registered all four shipped agents.
- `com.homeai.stack` started the laptop-safe core profile and exited with code 0.
- `com.homeai.merlin-status-api` remained running under launchd.
- `com.homeai.merlin-task-api` remained running under launchd.
- Port 8765 served the read-only status API with `execution_allowed=false`.
- Port 8766 served the execution-aware FastAPI task/status panels.
- Core services remained running: dashboard, Open WebUI, LiteLLM, Qdrant, native Ollama.
- `tests/core-live-smoke.sh` passed with 18 checks, 0 warnings, 0 failures.
- `doctor` reported 52 passed, 3 warnings, 0 failures.

## Commands Run

```bash
bash launchd/install-launchd.sh
sleep 35
launchctl print gui/$(id -u)/com.homeai.merlin-status-api
launchctl print gui/$(id -u)/com.homeai.merlin-task-api
launchctl print gui/$(id -u)/com.homeai.stack
curl -fsS --max-time 3 http://127.0.0.1:8765/healthz
curl -fsS --max-time 3 http://127.0.0.1:8765/status
curl -sS --max-time 3 http://127.0.0.1:8766/status/routes
bash tests/core-live-smoke.sh
bash scripts/doctor.sh
```

## Observed launchd State

`com.homeai.merlin-status-api`:

- state: running
- pid present
- last exit code: never exited
- properties: `keepalive`, `runatload`

`com.homeai.merlin-task-api`:

- state: running
- pid present
- last exit code: never exited
- properties: `keepalive`, `runatload`

`com.homeai.stack`:

- state: not running
- last exit code: 0
- expected because this agent is a one-shot starter for `wizard start core`

## Status API

`GET /healthz` on port 8765 returned:

```json
{
  "execution_allowed": false,
  "side_effects": "none",
  "status": "ok"
}
```

`GET /status` confirmed:

- active profile: core
- hardware tier: low
- privacy mode: local_only
- online mode: false
- cloud allowed: false
- dashboard: running
- LiteLLM: running
- Ollama: running
- Open WebUI: running
- Qdrant: running

## Task API

Port 8766 is now managed by a separate launchd job:
`com.homeai.merlin-task-api`.

`GET /status/routes` on port 8766 returned the configured route registry.

This preserves the required boundary:

- Port 8765 remains read-only and reports `execution_allowed=false`.
- Port 8766 owns the execution-aware FastAPI app, `POST /task`, and Phase 2
  status panels.

## Doctor Warnings

Expected warnings:

- gitleaks pre-commit hook is not installed locally
- 8GB low-tier warning for heavy optional profiles
- one historical local runtime log line from the earlier sandbox-blocked
  foreground task API start attempt

Failures: 0

## Conclusion

The v1.0 launchd persistence path is valid for the core installer stack, the
read-only dashboard status bridge, and the separate execution-aware Merlin task
API. `/task` and the Phase 2 status panels are now expected to persist after
login through `com.homeai.merlin-task-api`.
