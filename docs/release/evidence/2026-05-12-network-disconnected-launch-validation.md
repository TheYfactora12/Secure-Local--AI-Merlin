# Network-Disconnected Launch Validation - 2026-05-12

## Target

- Issue focus: #95 Product push audit / release readiness evidence
- Evidence row: offline launch

## Scope

Validate that the installed Merlin AI core stack can restart from local Docker
images while Wi-Fi is disabled, without pulling images or requiring cloud
services.

## Environment

- Runtime path: `/Users/kevinmedeiros/merlin-ai`
- Machine: `Kevins-MBP`
- CPU: Apple M2
- RAM: 8 GB
- Wi-Fi device: `en0`
- Default route before test: `en0`
- Profile: `core`
- Raw local log: `/tmp/merlin-network-disconnected-validation-20260512T224209Z.log`

## Commands

Wi-Fi was disabled with a shell trap that restored Wi-Fi on exit.

```bash
networksetup -setairportpower en0 off
docker compose stop dashboard open-webui litellm qdrant
docker compose up -d --no-build --pull never dashboard open-webui litellm qdrant
```

Endpoint probe loop checked:

```text
http://localhost:8888
http://localhost:3000
http://localhost:4000/health/readiness
http://localhost:6333/healthz
http://localhost:11434/api/tags
http://localhost:8765/healthz
http://localhost:8766/status/routes
```

Follow-up validation:

```bash
bash scripts/doctor.sh
bash tests/core-live-smoke.sh
bash tests/merlin-status-api-smoke.sh
bash tests/merlin-task-api-smoke.sh
docker compose logs --tail=100 dashboard open-webui litellm qdrant | \
  rg -i "api\.openai|api\.anthropic|telemetry|analytics|error|critical|pull|download" || true
```

## Results

Network state:

- Wi-Fi before: `Wi-Fi Power (en0): On`
- Default route before: `en0`
- Wi-Fi during test: `Wi-Fi Power (en0): Off`
- Default route during test: none detected
- Wi-Fi after restore: `Wi-Fi Power (en0): On`
- Default route after restore: `en0`

Docker restart:

- Core services stopped cleanly.
- Core services restarted with:

```bash
docker compose up -d --no-build --pull never dashboard open-webui litellm qdrant
```

Endpoint probes:

- Attempt 1:
  - Dashboard: `200`
  - Open WebUI: `000` / empty reply
  - LiteLLM: `000` / empty reply
  - Qdrant: `000` / empty reply
  - Ollama: `200`
  - Status API: `200`
  - Task API: `200`
- Attempt 2:
  - Dashboard: `200`
  - Open WebUI: `000` / empty reply
  - LiteLLM: `000` / empty reply
  - Qdrant: `200`
  - Ollama: `200`
  - Status API: `200`
  - Task API: `200`
- Attempts 3 through 6:
  - All tested endpoints returned `200`

Startup timing:

```text
startup_timing=2026-05-12T22:42:27Z..2026-05-12T22:42:58Z
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
- LiteLLM chat completion check skipped because no generation-capable model was
  installed

API smokes:

- `bash tests/merlin-status-api-smoke.sh`: passed
- `bash tests/merlin-task-api-smoke.sh`: passed

Log review:

- No OpenAI or Anthropic endpoint hits were found in the scanned core logs.
- No pull/download entries were found in the scanned core logs.
- Qdrant reported `Telemetry reporting disabled`.
- LiteLLM logged expected local model errors because no generation-capable
  Ollama model was installed:

```text
OllamaException - {"error":"model 'qwen2.5:7b' not found"}
```

## Assessment

Network-disconnected launch passed for core service restart and local health
checks. Merlin restarted from local images with Wi-Fi disabled and no default
route, and all core endpoints were green by the third probe.

The run also exposed a product-readiness gap: the stack can start offline, but
first local generation cannot work until a generation-capable Ollama model is
installed. This is not a cloud/privacy failure. It is an onboarding/model
availability gap.

Observed user-facing message when no internet/model was available:

```text
No chat-capable local model is installed. Install one manually with bash scripts/add-model.sh qwen2.5:7b. Merlin will not download models from the browser.
```

Assessment of that message:

- Security posture is correct: Merlin does not silently download models from the
  browser.
- Product posture needs polish before beta: a non-technical user should not hit
  a terminal-only instruction as the primary path.
- Recommended follow-up: add a guided, policy-gated model install path outside
  browser-side execution, or improve first-run onboarding so users install a
  low-tier model before they expect offline chat to work.

## Release Impact

- Local Trusted Beta: offline core launch evidence is now present.
- Local Trusted Beta blocker remains: first local chat/model readiness must
  guide the user clearly when no model is installed.
- Public Beta: no claim.
- Public Release: no claim.
