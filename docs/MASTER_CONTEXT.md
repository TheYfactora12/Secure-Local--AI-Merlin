# Wizard AI Master Context

Last verified: 2026-05-06
Repo: `TheYfactora12/home-ai-elite`
Branch: `main`
Installer: `install.sh` v1.6

Use this file with `docs/MASTER_PROMPT.md` at the start of every Codex, Perplexity, or AI session to avoid drift.

## Decision

Wizard AI is a local-first AI platform: own Perplexity + Codex + Memory on user-owned hardware with zero required subscriptions.

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
| Merlin status API | 8765 | Live dashboard status bridge |

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
- `wizard merlin approvals list|approve|deny` records approval audit state but still does not execute actions.
- `wizard merlin status` reports local profile, hardware tier, privacy mode, approvals, and services.
- `wizard merlin status-api start|status|stop` manages the localhost-only read-only status API.
- `wizard start` starts the selected profile, then starts the read-only Merlin status API if profile startup succeeds.
- `wizard stop` stops the status API before stopping Docker services.
- `wizard restart` stops and restarts the status API around Docker restart.
- Dashboard reads `http://localhost:8765/status` when the status API is running.
- The status API is read-only: `GET /healthz`, `GET /status`, mutation methods rejected, `execution_allowed=false`.

## RAM Tiers

Do not change these without a dedicated issue and validation run.

| RAM | Tier | Models |
| --- | --- | --- |
| 8-15 GB | low | `mistral:7b`, `qwen2.5:7b` |
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

1. Run one real local `wizard start` and dashboard check after status API wiring.
2. Decide whether launchd should include the read-only status API or keep it tied to manual `wizard start`.
3. Continue Merlin v1 work toward policy-gated execution only after read-only status/approval flows are stable.
4. Keep signed package/notarization work deferred until the installer and local validation remain green.
5. Continue optional live tests for search, automation, coding, and upgrade profiles on hardware with enough memory.

## Reasoning Summary

The current architecture keeps the default user path local-first and low-friction while preserving Linux server security options through explicit profiles. macOS avoids Docker Ollama conflicts by using native Ollama; Linux can still run Ollama in Docker when profiles are enabled.

The next engineering priority is a real local `wizard start` verification of the read-only Merlin status API and dashboard state. Signed release work can wait until the local core loop is stable.

## Risks / Unknowns

- Native macOS Ollama availability depends on the host service staying up.
- `host.docker.internal` plus `host-gateway` must be retested on future Docker Desktop and Linux Docker engine changes.
- The status API is intentionally read-only and must not become a privileged control plane without a separate policy-gated execution layer.
- launchd does not auto-start the status API yet.
- Optional live profile tests still need hardware/time validation.
- Memory quality and regression safety still need stronger test coverage before Magic Mode writes memory.

## Next Actions

1. Run `wizard start` and confirm `wizard merlin status-api status` reports running.
2. Open the dashboard and confirm Merlin Control Status shows the API online.
3. If clean, decide whether to add launchd support for the status API.

## Validation

Last validated on 2026-05-06:

- GitHub Actions passed for commit `f41f019`:
  - CI `25413833697`
- `wizard start|stop|restart` is wired to the guarded read-only Merlin status API lifecycle.
- `tests/wizard-start-status-api-smoke.sh` passed.
- `tests/merlin-status-api-smoke.sh` passed with localhost-bind permission.
- Full local static smoke suite passed.
- Dashboard contains the read-only Merlin Control Status panel and points to `wizard merlin status-api start`.

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
