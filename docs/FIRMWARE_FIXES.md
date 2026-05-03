# Home AI Elite Installer/Firmware Fixes

Validation date: May 3, 2026

This log captures the installer and stack fixes made while preparing Home AI Elite for a shareable macOS package and GitHub `main` release.

## Installer fixes

- Added non-interactive install support with `--non-interactive`, `--yes`, `--skip-model-pulls`, `HOME_AI_NON_INTERACTIVE`, and `HOME_AI_SKIP_MODEL_PULLS`.
- Added Docker CLI discovery for Docker Desktop's bundled CLI at `/Applications/Docker.app/Contents/Resources/bin`.
- Added Docker Desktop startup/wait handling on macOS when Docker is installed but not running.
- Removed the hard dependency on Homebrew Ollama for runtime model serving; the installer now uses the Docker Ollama container.
- Added Homebrew Ollama conflict handling so a locally running Homebrew service does not block Docker Ollama from binding `localhost:11434`.
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
- Updated bootstrap model checks and pulls to use Docker Ollama through `docker compose exec`.
- Updated `scripts/add-model.sh` to pull and list models inside the Docker Ollama container.
- Updated `scripts/status.sh` to check LiteLLM on the root endpoint and list Ollama models from the Docker container.

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
