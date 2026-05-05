# Test Strategy

## Goals

Testing must protect the working installer while Merlin evolves. Tests should prove that local-only behavior remains default, low-memory machines avoid heavy services, secrets are not exposed, and profile changes do not break existing startup paths.

## Manual Tests

### Installer Baseline

- Fresh clone.
- `bash install.sh --help`.
- `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --non-interactive --skip-model-pulls`.
- `bash tests/core-install-budget-smoke.sh` completes inside the current 10 minute budget when Docker Desktop is already installed and running.
- Confirm `.env` exists and permissions are `600`.
- Confirm secrets are not default values.
- Confirm service URLs print.
- Confirm failure report is generated on controlled failure.

### macOS Native Ollama

- Confirm Docker Ollama is not started by default on macOS.
- Confirm `http://localhost:11434` responds.
- Confirm containers use `host.docker.internal`.
- Confirm `scripts/add-model.sh <model>` uses native Ollama.

### Service Start/Stop

- `bash scripts/status.sh`.
- `bash scripts/restart.sh`.
- `bash scripts/stop.sh`.
- `wizard status`.
- `wizard brain status/start/stop`.

### Profile Behavior Future Tests

- Core profile starts only core services.
- Search profile adds Perplexica/SearXNG.
- Automation profile adds n8n.
- Coding profile adds OpenHands.
- Full profile requires explicit confirmation.

## Automated Tests

### Static Tests

- `bash -n install.sh`
- `bash -n scripts/*.sh`
- `bash -n launchd/*.sh`
- `bash -n pkg/scripts/*`
- `bash tests/pkg-readiness-smoke.sh`
- Unsigned local package build with `bash pkg/build-pkg.sh`.
- Package payload check confirms `.env`, generated certs, and package artifacts are not bundled.
- `bash -n cli/wizard`
- `docker compose config --quiet`
- JSON validation for `n8n-workflows/*.json`
- YAML validation for configs

### Smoke Tests

Core:

- Docker running.
- Ollama API reachable.
- Open WebUI reachable.
- LiteLLM reachable.
- Qdrant reachable.
- Dashboard reachable.
- `tests/core-live-smoke.sh` verifies the laptop-safe core path end to end without model pulls, cloud calls, or secret output.
- `tests/core-install-budget-smoke.sh` reruns the laptop-safe installer path and then calls the live core smoke test.
- If a local model is installed, core smoke verifies both direct Ollama generation and LiteLLM routing.
- `wizard start` starts the same profile as `bash scripts/start-core.sh`.

Search:

- SearXNG reachable.
- Perplexica frontend reachable.
- Perplexica backend reachable.

Automation:

- n8n reachable.
- Workflow import handles missing API key gracefully.
- Workflow JSON validates.

Coding:

- OpenHands reachable only when coding profile enabled.
- Docker socket warning is present.

## Security Tests

- `.env` is not tracked.
- `.env` permissions are `600`.
- No hardcoded live-looking API keys.
- Dashboard never displays secret values.
- `*_BIND=0.0.0.0` produces warning.
- No cloud provider selected unless online mode and API key are enabled.
- Sensitive tasks route local-only.
- Memory write requires approval.
- Magic Mode file/shell/network actions require approval.
- OpenHands is disabled unless coding profile is enabled.

## Performance Tests

Tier 1:

- Does not start OpenHands by default.
- Does not pull 14B+ models by default.
- Installer does not pull recommended models unless the user confirms or sets `HOME_AI_PULL_RECOMMENDED_MODELS=true`.
- Does not start n8n/search unless selected.

Tier 2:

- Starts core within target time.
- Runs one local 7B model.
- Light Qdrant retrieval works.

Tier 3:

- Search profile works.
- Optional automation works.
- Magic Mode plan-only mode works.

Tier 4:

- Larger models are allowed after confirmation.
- Parallel agent warnings appear.

## Regression Tests for Installer

Required before merging installer-adjacent changes:

- `install.sh --help` works.
- Non-interactive install with skipped model pulls works.
- Non-interactive install defaults to no model pulls unless explicitly opted in.
- macOS native Ollama path remains intact.
- Linux Docker Ollama profile remains intact.
- `tests/update-upgrade-profile-smoke.sh` confirms update/upgrade stay profile-aware and do not start Docker Ollama on macOS core.
- `.env` creation and secret rotation work.
- `N8N_SECURE_COOKIE=false` remains set for local HTTP unless user changes it.
- `PERPLEXICA_CONFIG_FILE` runtime config behavior remains intact.
- `wizard` CLI symlink install still works or fails with actionable message.
- Bootstrap remains idempotent.
- Failure report does not include secret values.

## No-Cloud-By-Default Tests

- Empty provider keys in `.env`.
- Offline/local mode enabled.
- Ask a general question.
- Assert no request is made to OpenAI, Anthropic, Perplexity, or other external provider.
- Assert LiteLLM route is local Ollama.

Implementation options:

- Run in a network-restricted test environment.
- Add proxy/log capture around outbound requests.
- Add route-decision dry-run tests before live calls.

## Magic Mode Approval Tests

Plan-only:

- User asks "clean up my repo".
- Merlin returns plan.
- No files changed.
- Approval required before any write.

File write:

- Proposed file write returns approval request.
- Deny leaves file unchanged.
- Approve writes only scoped file.

Shell:

- Proposed shell command returns approval request.
- Deny does not execute.
- Approve logs command and output.

Network:

- External URL request requires approval.
- Localhost service checks allowed by policy.

Memory:

- Proposed memory write shows content and source.
- Deny does not write.
- Approve writes to canonical collection and audit log.

## Release Readiness Tests

- Clean Mac install.
- Clean Linux install.
- Package install.
- Package uninstall.
- Volume backup.
- Merlin memory backup.
- Merlin memory restore dry-run.
- Merlin memory restore against a disposable Qdrant collection.
- `tests/qdrant-restore-live-smoke.sh` verifies a disposable Qdrant collection can be backed up and restored without touching production memory.
- Upgrade.
- Rollback.
- Core profile.
- Full profile.
- Low-memory profile simulation.

## Acceptance Criteria

Merlin v1 cannot be called stable until:

- Installer regression tests pass.
- Core services pass smoke tests.
- No-cloud-by-default test passes.
- Low-memory tier avoids heavy services.
- Memory write approval test passes.
- Magic Mode approval tests pass in plan-only or simulated mode.
- Dashboard shows state without exposing secrets.
- Backup/restore test passes for canonical memory collections.
