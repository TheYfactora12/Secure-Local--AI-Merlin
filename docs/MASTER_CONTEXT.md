# Wizard AI Master Context

Last verified: 2026-05-06
Repo: `TheYfactora12/home-ai-elite`
Branch: `main`
Installer: `install.sh` v1.6

Use this file with `docs/MASTER_PROMPT.md` at the start of every Codex, Perplexity, or AI session to avoid drift.

## Decision

Wizard AI is a local-first AI platform: own Perplexity + Codex + Memory on user-owned hardware with zero required subscriptions.

Hardware principle: 8GB Macs are the entry point in low/core mode. The system scales upward by profile and hardware tier; the full stack is not expected to run on 8GB.

The supported install path is:

```bash
bash install.sh
```

Raw `docker compose up` is now macOS-safe by default because macOS-incompatible services are profile-gated. It is still not the preferred install path because it skips secret rotation, model pulls, Qdrant bootstrap, and n8n workflow import.

## Current Architecture

| Service | Port | Replaces |
| --- | ---: | --- |
| Wizard HQ | 8888 | Manual status checks |
| Open WebUI | 3000 | ChatGPT |
| Perplexica | 3002 | Perplexity AI |
| OpenHands | 3003 | GitHub Copilot/Codex |
| n8n | 5678 | Zapier |
| LiteLLM | 4000 | OpenAI API layer |
| SearXNG | 8080 | Google for AI search |
| Qdrant | 6333 | Pinecone |
| Ollama | 11434 | OpenAI API, local |
| Merlin status API | 8765 | Read-only dashboard status bridge |
| Merlin task API | 8766 | FastAPI task endpoint and Phase 2 status panels |

Port 8765 and port 8766 are separate by design:

- `scripts/merlin-status-api.py` serves port 8765. It is read-only, JSONL/status based, and must keep `execution_allowed=false`. Do not modify it for execution-aware features.
- `merlin/task_endpoint.py` serves port 8766. It owns `POST /task` plus `/status/routes`, `/status/approvals`, `/status/traces`, and `/status/memory`.

macOS:

- Ollama runs natively for Apple Metal GPU acceleration.
- Containers reach native Ollama through `http://host.docker.internal:11434`.
- Docker Ollama is profile-gated behind `docker-ollama`.
- fail2ban is profile-gated behind `linux-security`.
- Default `docker compose up` excludes both Docker Ollama and fail2ban.

Linux Docker-Ollama mode:

```bash
docker compose --profile docker-ollama --profile linux-security up -d
```

Merlin control-plane status:

- `wizard merlin dry-run "goal"` previews routing, model, profile, and approval requirements with no side effects.
- `wizard merlin config validate` validates Phase 2A Merlin config startup contracts from `configs/merlin/` with no new runtime YAML dependency.
- `wizard merlin approvals list|approve|deny` records approval audit state but still does not execute actions.
- `wizard merlin status` reports local profile, hardware tier, privacy mode, approvals, and services.
- `wizard merlin execute plan|execute --action merlin_status` is the v0 policy-gated execution boundary. It only allows read-only Merlin status and writes a redacted execution audit record on execute.
- `wizard merlin magic plan "goal"` drafts plan-only Magic Mode steps from the existing route dry-run. With `--write-plan`, it writes redacted plan JSONL and route/approval audit records; it still executes nothing.
- `wizard merlin memory plan|simulate|write --memory-type <type> --text <text>` is the approved memory-write boundary. Simulate writes redacted JSONL only. Write requires an approved `memory_write` approval id, an existing canonical Qdrant collection, and local Ollama embeddings before it upserts approved memory to local Qdrant.
- `wizard merlin memory search --query "..." --memory-type <type>` is the local-only memory-read boundary. It searches Qdrant with local Ollama embeddings and writes a redacted read audit record.
- `wizard merlin status-api start|status|stop` manages the localhost-only read-only status API.
- `wizard start` starts the selected profile, then starts the read-only Merlin status API if profile startup succeeds.
- `wizard stop` stops the status API before stopping Docker services.
- `wizard restart` stops and restarts the status API around Docker restart.
- launchd runs the read-only Merlin status API as its own foreground job: `com.homeai.merlin-status-api`.
- Dashboard reads `http://localhost:8765/status` when the status API is running.
- The status API is read-only: `GET /healthz`, `GET /status`, mutation methods rejected, `execution_allowed=false`.
- Canonical config root is `configs/`; root `config/` is forbidden. Merlin config lives in `configs/merlin/`.

## Phase 2 Complete

Phase 2 is complete on `main` through commit `b4f35c8`, with 58 tests passing locally and CI green for the Phase 2F merge run.

| Phase | Commit | Files |
| --- | --- | --- |
| 2A Config Loader | `99645ca` | `merlin/config_loader.py`, `tests/test_config_loader.py` |
| 2B Policy Engine | `e6ffa8c` | `merlin/policy_engine.py`, `tests/test_policy_engine.py` |
| Policy gate fix | `3c8222f` | explicit `secret_access` gate in policy |
| 2C Native Router | `cbbd41c` | `merlin/router.py`, `tests/test_router.py` |
| 2D Memory Manager | `dfcd500` | `merlin/memory_manager.py`, memory tests |
| Router trace correction | `d608de0` | actual route schema fields |
| 2E Persona + Task Endpoint | `1503dab` | `persona_injector.py`, `task_endpoint.py`, endpoint tests |
| 2F Status Extension | `b4f35c8` | `status_extension.py`, status extension tests |

Phase 2 runtime package:

- `merlin/config_loader.py` validates the Merlin YAML config set.
- `merlin/policy_engine.py` enforces 14 fail-closed approval gates.
- `merlin/router.py` routes into the real 5 route IDs and carries approval gates.
- `merlin/memory_manager.py` talks to local Ollama embeddings and Qdrant with dimension guards.
- `merlin/persona_injector.py` builds Merlin system prompts with guardian ethos and Pi warmth.
- `merlin/task_endpoint.py` exposes FastAPI on port 8766.
- `merlin/status_extension.py` adds route, approval, trace, and memory status panels to the FastAPI app.

## RAM Tiers

Do not change these without a dedicated issue and validation run.

| RAM | Tier | Models |
| --- | --- | --- |
| 8-15 GB | low | `qwen2.5:7b`, `nomic-embed-text` |
| 16-23 GB | base | `qwen2.5:7b`, `qwen2.5-coder:7b`, `deepseek-r1:7b` |
| 24-47 GB | mid | `qwen2.5:32b`, `qwen2.5-coder:14b`, `deepseek-r1:14b` |
| 48+ GB | high | `llama3.3:70b`, `qwen2.5:32b`, `deepseek-r1:32b` |

## Closed Bug/Architecture Issues

All BUG-01 through BUG-18 fixes are written, pushed, and verified on `main`.

Recently verified closures:

- #11 BUG-10: litellm/open-webui macOS `depends_on: ollama` startup blocker.
- #13 BUG-12: blank `.env` keys no longer report as `SET`.
- #16 BUG-15: open-webui same root cause as BUG-10.
- #18 BUG-17: LiteLLM config pre-flight guard.
- #19 BUG-18: bootstrap failure messaging is actionable.
- #20 ARCH: raw `docker-compose.yml` is macOS-safe without requiring install-time dependency surgery.
- #23 macOS real install test bugs: native Ollama/bootstrap/validation gaps fixed.

## Open Work, Priority Order

1. Continue Issue #25 with deeper SAST planning only after reviewing the gitleaks gate outcome.
2. Start Pi Emotional Intelligence only after the next security slice is scoped.
3. Keep signed package/notarization work deferred until installer, Phase 2 API, support tooling, and CI gates remain green.
4. Continue optional live tests for search, automation, coding, and upgrade profiles on hardware with enough memory.

## Reasoning Summary

The current architecture keeps the default user path local-first and low-friction while preserving Linux server security options through explicit profiles. macOS avoids Docker Ollama conflicts by using native Ollama; Linux can still run Ollama in Docker when profiles are enabled.

The next engineering priority is supportability: diagnostics, sanitized bug reports, and drift-proof docs so another AI or human can continue without breaking the installer or crossing security boundaries. Signed release work can wait until the local core loop and support loop remain green.

## Risks / Unknowns

- Native macOS Ollama availability depends on the host service staying up.
- `host.docker.internal` plus `host-gateway` must be retested on future Docker Desktop and Linux Docker engine changes.
- The status API is intentionally read-only and must not become a privileged control plane without a separate policy-gated execution layer.
- The FastAPI task API is intentionally separate on port 8766. Do not bridge it into `scripts/merlin-status-api.py`.
- The v0 execution layer only allows `merlin_status`; approval alone must not unlock shell, file, network, memory write, service, model download, cloud, or OpenHands actions.
- Magic Mode is plan-only: steps can be drafted and audited, but no step adapter can execute until separately implemented and tested.
- Memory write simulation is not persistence. It stores only redacted audit metadata and must not be treated as learned memory.
- launchd starts the core profile through `wizard start core` and runs the read-only status API as a separate foreground LaunchAgent. Do not rely on a short-lived launchd shell to daemonize the API.
- n8n is still a Phase 1 workflow/execution surface and remains parallel to the Phase 2 Python control plane. Do not decommission it until replacements are proven route by route.
- Optional live profile tests still need hardware/time validation.
- Memory quality and regression safety still need stronger test coverage before Magic Mode writes memory.

## Next Actions

1. Review Issue #25 Layer 1 results and decide whether the next slice is deeper SAST or Pi Emotional Intelligence.
2. Keep verifying `ci-success` requires both `gitleaks-scan` and `merlin-staff-core-pytest`.
3. Continue updating roadmap/docs/tests with every milestone before signing/notarization work.

## Validation

Last verified: 2026-05-06.

- Phase 2F merged at `b4f35c8`; local Phase 2 Python suite reported 58 passing tests.
- CI was green for the Phase 2F merge run.
- Issue #22 support tooling is merged and pushed at `47f30df`: additive doctor checks, redaction helper, sanitized report generator, wizard wiring, and doctor/report-bug/redaction smokes.
- Issue #24 CI gate is merged and pushed at `c6f6652`; GitHub Actions run `25451110988` passed.
- Issue #25 Layer 1 is merged and pushed at `d4ece3d`; GitHub Actions run `25454666989` passed with `gitleaks-scan` and `merlin-staff-core-pytest` both required by `ci-success`.

- Current local validation for the Qdrant memory adapter work:
  - `bash tests/merlin-memory-write-smoke.sh`
  - `bash tests/memory-config-smoke.sh`
  - `bash tests/master-prompt-smoke.sh`
  - `bash -n cli/wizard scripts/merlin-memory-write.sh tests/merlin-memory-write-smoke.sh tests/memory-config-smoke.sh tests/master-prompt-smoke.sh`
  - `git diff --check`
- Most recent checked GitHub Actions run before this patch passed for commit `232038c`.
- `wizard start|stop|restart` is wired to the guarded read-only Merlin status API lifecycle for manual starts.
- launchd source now includes a dedicated read-only Merlin status API foreground agent for persistent login auto-start.
- `tests/wizard-start-status-api-smoke.sh` passed.
- `tests/merlin-status-api-smoke.sh` passed with localhost-bind permission.
- Full local static smoke suite passed.
- Dashboard contains the read-only Merlin Control Status panel and points to `wizard merlin status-api start`.
- Live launchd reinstall registered `com.homeai.docker`, `com.homeai.stack`, and `com.homeai.merlin-status-api`.
- `launchctl print gui/501/com.homeai.merlin-status-api` reported `state = running` and `last exit code = (never exited)`.
- `wizard merlin status-api status`, `GET /healthz`, and `GET /status` passed against `http://127.0.0.1:8765`.
- `GET /status` reported profile `core`, hardware tier `low`, RAM `8`, privacy `local_only`, cloud disabled, all core services running, and `execution_allowed=false`.
- `bash tests/core-live-smoke.sh` passed with 18 checks, 0 warnings, and 0 failures.
- `wizard merlin execute execute --action merlin_status` is the only v0 executable action; it prints read-only status and writes `logs/merlin-executions.jsonl`.
- `tests/merlin-execute-smoke.sh` verifies dry-run/execute separation, audit logging, CLI routing, and denial of risky actions even after approval.
- `wizard merlin magic plan "goal"` drafts plan-only steps and can write redacted plan records to `logs/merlin-magic-plans.jsonl`.
- `tests/merlin-magic-plan-smoke.sh` verifies Magic Mode remains plan-only, writes no raw goals, and produces approval-blocked plans for risky routes.
- `wizard merlin memory simulate --memory-type preference --text "..." --approval-id <id>` writes only redacted simulated memory audit records to `logs/merlin-memory-writes.jsonl`.
- `wizard merlin memory write --memory-type preference --text "..." --approval-id <id>` can upsert approved memory to local Qdrant with local Ollama embeddings. It does not create collections, pull models, start services, call cloud APIs, or store raw text in the JSONL audit log.
- `tests/merlin-memory-write-smoke.sh` verifies approved `memory_write` gate validation, fail-closed denial, no raw audit logging, no Qdrant/embedding calls during plan/simulate/denial, and a fake local Qdrant/Ollama write path for approved `write`.
- `wizard merlin memory search --query "..." --memory-type preference` can retrieve approved memory from local Qdrant with local Ollama embeddings. It writes redacted read audit records to `logs/merlin-memory-reads.jsonl` and performs no memory writes, cloud calls, service starts, or tool execution.
- `tests/merlin-memory-read-smoke.sh` verifies local embedding search, Qdrant read behavior, CLI routing, no memory writes, and no raw query or raw memory text in read audit logs.
- `tests/merlin-config-validate-smoke.sh` verifies the Phase 2A config validator, route/policy cross-checks, memory dimension contract checks, and rejection of the legacy root `config/` directory.
- Live memory validation on 2026-05-06 initialized canonical Qdrant collections with `MERLIN_CREATE_CANONICAL_COLLECTIONS=true bash scripts/init-qdrant.sh`, explicitly installed local `nomic-embed-text`, approved `approval_dryrun_20260506_040756_17686`, wrote point `640cc4bb-5dc9-3c68-8a44-5d2560a15ab5` into `merlin_user`, and verified the JSONL audit record `mem_20260506_040805_654553` stayed redacted.
- Live memory search validation on 2026-05-06 ran `wizard merlin memory search --query "local-first profile-aware" --memory-type preference --limit 3`, retrieved point `640cc4bb-5dc9-3c68-8a44-5d2560a15ab5`, and verified read audit record `mread_20260506_041535_472003` stored hashes only.
- PR #10 / `installer-hardening` is closed and `origin/installer-hardening` is an ancestor of `origin/main`; it is not an active blocker.

Earlier live validation on 2026-05-05:

- Core install path completed with `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`.
- `tests/core-install-budget-smoke.sh` completed the core installer in 95 seconds against a 600 second budget, then passed live core smoke.
- Docker Desktop core services were running: Wizard HQ `:8888`, Open WebUI `:3000`, LiteLLM `:4000`, and Qdrant `:6333`.
- Native Ollama was running through Homebrew service.
- Approved low-tier model `qwen2.5:7b` was installed.
- Ollama local generation returned `Merlin core online`.
- LiteLLM `/v1/models` listed configured aliases and `/v1/chat/completions` with `qwen7b` returned `Merlin gateway online`.
- `scripts/doctor.sh` completed with 43 passes, 2 warnings, and 0 failures.
- Unsigned local package build produced `home-ai-elite-0.6.1.pkg`; payload check found no `.env` or generated certs. Package is not signed/notarized.
- `pkg/release-preflight.sh` confirms package tools are installed, but this Mac has no Developer ID Installer identity and no Apple notarization environment set.

Earlier validation on 2026-05-04:

- `docker compose config --quiet` passed.
- Default `docker compose config --services` excludes `ollama` and `fail2ban`.
- `docker compose --profile docker-ollama --profile linux-security config --services` includes both `ollama` and `fail2ban`.
- `bash -n` passed for changed shell scripts.
- `scripts/status.sh` showed Wizard HQ on `http://localhost:8888`.
- `tests/e2e-test.sh` passed with 14 checks and 0 failures.
- GitHub Actions were green for commit `4932356`:
  - CI `25297415649`
  - Release `25297415662`
