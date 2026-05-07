# launchd Persistence Validation

Date: 2026-05-07
Machine: macOS, 8GB RAM, low tier
Scope: macOS LaunchAgents for Docker, core stack, and read-only Merlin status API

## Result

launchd persistence validation passed for the shipped v1.0 LaunchAgent scope.

Validated:

- `launchd/install-launchd.sh` registered all three shipped agents.
- `com.homeai.stack` started the laptop-safe core profile and exited with code 0.
- `com.homeai.merlin-status-api` remained running under launchd.
- Port 8765 served the read-only status API with `execution_allowed=false`.
- Core services remained running: dashboard, Open WebUI, LiteLLM, Qdrant, native Ollama.
- `tests/core-live-smoke.sh` passed with 18 checks, 0 warnings, 0 failures.
- `doctor` reported 51 passed, 4 warnings, 0 failures.

## Commands Run

```bash
bash launchd/install-launchd.sh
sleep 35
launchctl print gui/$(id -u)/com.homeai.merlin-status-api
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

## Task API Gap

Port 8766 was closed after launchd startup.

This is expected with the current repo: launchd currently manages Docker,
the core stack, and the read-only status API, but not the Merlin task API.

Tracking issue:

- #75 — Add launchd-managed Merlin Task API on port 8766

Do not solve this by merging port 8766 into port 8765. Port 8765 must remain
read-only with `execution_allowed=false`.

## Doctor Warnings

Expected warnings:

- gitleaks pre-commit hook is not installed locally
- 8GB low-tier warning for heavy optional profiles
- Merlin Task API not reachable on 8766
- port 8766 closed

Failures: 0

## Conclusion

The v1.0 launchd persistence path is valid for the core installer stack and the
read-only dashboard status bridge. The execution-aware Merlin task API needs its
own LaunchAgent/lifecycle manager before `/task` can be considered persistent
after login.
