# Local Image Restart Validation - 2026-05-12

## Target

- Issue focus: #95 Product push audit / release readiness evidence
- Evidence row: offline launch

## Scope

This was a local-image restart validation, not a full air-gapped test.

Network access was not disabled because doing so could interrupt the active
Codex session. The test still used local installed Docker images only by
starting core services with Docker Compose pull disabled.

## Environment

- Runtime path: `/Users/kevinmedeiros/merlin-ai`
- Machine: `Kevins-MBP`
- CPU: Apple M2
- RAM: 8 GB
- OS: macOS 26.4.1 build 25E253
- Profile: `core`

## Commands

```bash
docker compose stop dashboard open-webui litellm qdrant
sleep 5
docker compose up -d --no-build --pull never dashboard open-webui litellm qdrant
```

Endpoint probe loop:

```bash
for attempt in 1 2 3 4 5 6; do
  for url in \
    http://localhost:8888 \
    http://localhost:3000 \
    http://localhost:4000/health/readiness \
    http://localhost:6333/healthz \
    http://localhost:11434/api/tags \
    http://localhost:8765/healthz \
    http://localhost:8766/status/routes; do
      code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 "$url" || true)
      printf '%s %s\n' "$code" "$url"
  done
  sleep 5
done
```

Additional validation:

```bash
bash scripts/doctor.sh
bash tests/core-live-smoke.sh
bash tests/merlin-status-api-smoke.sh
bash tests/merlin-task-api-smoke.sh
docker compose logs --tail=100 dashboard open-webui litellm qdrant | \
  rg -i "api\.openai|api\.anthropic|telemetry|analytics|error|critical|pull|download" || true
```

## Results

Docker restart:

- `docker compose up -d --no-build --pull never ...` completed successfully.
- Core containers started from already-present images:
  - `dashboard`
  - `open-webui`
  - `litellm`
  - `qdrant`

Endpoint probes:

- Attempt 1:
  - Dashboard: `200`
  - Open WebUI: `000` with `curl: (52) Empty reply from server`
  - LiteLLM: `200`
  - Qdrant: `200`
  - Ollama: `200`
  - Merlin status API: `200`
  - Merlin task API: `200`
- Attempts 2 through 6:
  - All endpoints returned `200`

Startup timing:

```text
startup_timing=2026-05-12T04:28:32Z..2026-05-12T04:29:05Z
```

Doctor:

```text
doctor: 50 checks passed, 3 warnings, 0 failures
```

Warnings:

- `gitleaks pre-commit hook missing`
- low-tier Mac should avoid heavy optional profiles by default
- no installed Ollama models detected

Core live smoke:

```text
Summary: 15 passed, 2 warnings, 0 failures
```

Warnings:

- no Ollama generation-capable models installed
- LiteLLM chat completion check skipped because no generation-capable model was installed

API smokes:

- `bash tests/merlin-status-api-smoke.sh`: passed
- `bash tests/merlin-task-api-smoke.sh`: passed

Log review:

- No OpenAI or Anthropic endpoint hits were found in the scanned core logs.
- No pull/download entries were found in the scanned core logs.
- Qdrant reported `Telemetry reporting disabled`.

## Assessment

Local-image restart behavior passed. Merlin recovered from stopped core Docker
services using already-present local images, with honest warmup behavior from
Open WebUI on the first probe and all core endpoints green by the second probe.

This does not fully close the offline-launch evidence row because the Mac was
not physically disconnected from the network. A final air-gapped/manual
validation remains required before beta signoff.

## Release Impact

- Local Trusted Beta: improves evidence, but true network-disconnected launch
  remains a blocker before signoff.
- Public Beta: no claim.
- Public Release: no claim.
