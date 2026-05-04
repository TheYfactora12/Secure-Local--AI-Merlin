# Home AI Elite Installer/Firmware Fixes

Validation date: May 3, 2026

This log captures the installer and stack fixes made while preparing Home AI Elite for a shareable macOS package and GitHub `main` release.

## Installer fixes

- Added non-interactive install support with `--non-interactive`, `--yes`, `--skip-model-pulls`, `HOME_AI_NON_INTERACTIVE`, and `HOME_AI_SKIP_MODEL_PULLS`.
- Added Docker CLI discovery for Docker Desktop's bundled CLI at `/Applications/Docker.app/Contents/Resources/bin`.
- Added Docker Desktop startup/wait handling on macOS when Docker is installed but not running.
- On macOS, uses native Ollama for runtime model serving so Apple Metal acceleration is available.
- Skips the Docker Ollama container on macOS so native Ollama can own `localhost:11434`.
- Made terminal clearing safe in non-interactive runs so `clear` cannot abort the installer under `set -e`.
- Changed health waits so timeout warnings do not abort the entire install after services are launched.
- Generated nginx TLS certificates during install and mounted them into nginx from the repo-local `certs/` directory.

## Stack fixes

- Fixed the n8n image tag from `n8nio/n8n:1.87` to `n8nio/n8n:1.87.1`.
- Fixed Perplexica image names to valid published images.
- Replaced brittle container healthcheck dependencies with `service_started` dependencies because several upstream images do not include `curl`.
- Updated LiteLLM readiness checks to use `http://localhost:4000`, since `/health` requires authentication on the current LiteLLM image.
- Removed the incompatible LiteLLM `model_group_alias` block that caused startup crashes on the current LiteLLM image.
- Set Watchtower's Docker API version explicitly to avoid restart loops against newer Docker Desktop engines.

## Script fixes

- Updated `scripts/bootstrap.sh` to run from the actual repository path instead of hardcoding `${HOME}/home-ai-elite`.
- Updated bootstrap model checks and pulls to use native Ollama on macOS and Docker Ollama on Linux.
- Updated `scripts/add-model.sh` to pull and list models inside the Docker Ollama container.
- Updated `scripts/status.sh` to check LiteLLM on the root endpoint and list Ollama models from the Docker container.

## May 3 macOS clean-clone smoke follow-up

During a fresh GitHub clone smoke test from `/private/tmp/home-ai-elite-smoke`, two macOS-specific boot blockers were found and fixed:

- Patch 4 used `grep -P`, which is GNU grep-only and fails on macOS BSD grep. Result: the installer skipped the `depends_on: ollama` removal and Docker Compose tried to start the Ollama container, conflicting with native Ollama on `127.0.0.1:11434`. Fix: use portable `grep -q`.
- The n8n Docker healthcheck used `localhost`, which resolved to `::1` inside the container. n8n listens on IPv4, so Docker marked it unhealthy while `http://localhost:5678/healthz` worked from the host. Fix: healthcheck now probes `http://127.0.0.1:5678/healthz`.
- `scripts/bootstrap.sh` also called plain `docker compose up -d`, which reintroduced the Ollama container after the installer correctly skipped it. Fix: bootstrap now skips the Ollama Docker service on macOS and uses native Ollama for model checks.
- Both installer and bootstrap now build the filtered Compose service list as a Bash array before invoking `docker compose up`.
- `scripts/status.sh` now lists native Ollama models on macOS instead of reporting "Ollama container not running".
- `tests/e2e-test.sh` now resolves the repo path from its own location, uses the current service ports, discovers Docker Desktop's bundled CLI, and increments counters safely under `set -e`.

## Package fixes

- Updated package preinstall checks for Docker Desktop and the bundled Docker CLI.
- Updated package postinstall to open Docker Desktop, use the bundled Docker CLI, and run `install.sh --non-interactive`.
- Updated package documentation with the Docker Desktop requirement and corrected local service URLs.

## Smoke validation

The installer completed end-to-end from a clean smoke copy at `/private/tmp/home-ai-elite-smoke` using:

```bash
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --non-interactive --skip-model-pulls
```

Validated running endpoints:

- Open WebUI: `http://localhost:3000`
- Perplexica: `http://localhost:3002`
- OpenHands: `http://localhost:3003`
- SearXNG: `http://localhost:8080`
- LiteLLM: `http://localhost:4000`
- n8n: `http://localhost:5678`
- Qdrant: `http://localhost:6333`
- Ollama: `http://localhost:11434`

## Full macOS pull-down validation

After pushing the macOS installer/bootstrap fixes, a fresh GitHub clone was tested at `/private/tmp/home-ai-elite-realtest` using:

```bash
HOME_AI_NON_INTERACTIVE=true bash install.sh --non-interactive
```

Validated outcomes:

- Native Ollama model pulls completed for `nomic-embed-text`, `qwen2.5:7b`, `qwen2.5-coder:7b`, and `deepseek-r1:7b`.
- Docker Compose started all non-Ollama services and did not start the Ollama Docker container on macOS.
- n8n became Docker-healthy using the IPv4 healthcheck.
- Bootstrap completed, including Qdrant `home_ai_memory` collection creation.
- `tests/e2e-test.sh` passed with 14 checks and 0 failures.
- Real-test logs were collected at `/private/tmp/home-ai-elite-realtest-logs`.

## Compose safety follow-up

- Made raw `docker-compose.yml` macOS-safe without relying on installer patching by moving Docker Ollama behind the `docker-ollama` profile and fail2ban behind the `linux-security` profile.
- Removed hard `depends_on: ollama` edges from LiteLLM, Open WebUI, and Perplexica backend.
- Standardized Ollama container clients on `http://host.docker.internal:11434`; Linux Docker-Ollama mode reaches the published Ollama port through Docker `host-gateway`.
- Updated Linux installer/bootstrap startup to enable `docker-ollama` and `linux-security` profiles explicitly.
- Added the Wizard HQ dashboard as an actual Compose service on `http://localhost:8888` and included it in README, status, bootstrap output, and e2e checks.
- Corrected the high RAM tier model pull list to `llama3.3:70b`, `qwen2.5:32b`, and `deepseek-r1:32b`.
