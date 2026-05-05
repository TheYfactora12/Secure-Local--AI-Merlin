# Wizard AI Master Context

Last verified: 2026-05-05
Repo: `TheYfactora12/home-ai-elite`
Branch: `main`
Installer: `install.sh` v1.6
Codex resume: `codex resume 019def0f-35cd-7083-aa1a-9e14d69338bd`

Use this file at the start of every Codex, Perplexity, or AI session to avoid drift.

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

## Open Issues, Priority Order

1. #1: v1.0 signed release checklist.
2. #2: `wizard doctor` command.
3. #3: n8n Ollama retry logic.
4. #4: Qdrant memory schema + session bridge.
5. #6: ModelRouter n8n workflow.
6. #7: memory benchmark harness.
7. #8: observability with self-hosted Langfuse + Ollama tracing.
8. #5: hardware guide + free stack map.
9. #22: `wizard report-bug` sanitized failure report + GitHub issue creation.

## Reasoning Summary

The current architecture keeps the default user path local-first and low-friction while preserving Linux server security options through explicit profiles. macOS avoids Docker Ollama conflicts by using native Ollama; Linux can still run Ollama in Docker when profiles are enabled.

The next engineering priority should be #1 and #2. A signed release proves distributability; `wizard doctor` reduces support cost and catches install drift before users debug manually.

## Risks / Unknowns

- Native macOS Ollama availability depends on the host service staying up.
- `host.docker.internal` plus `host-gateway` must be retested on future Docker Desktop and Linux Docker engine changes.
- n8n workflow reliability is still tracked in #3.
- Memory quality and regression safety are still tracked in #4 and #7.
- Observability is not yet production-grade until #8 is implemented.

## Next Actions

1. Tackle #1 if release packaging is the immediate objective.
2. Tackle #2 if the next goal is install robustness and field diagnostics.
3. Keep #22 for after the bug-fix loop is stable, so automated reporting does not file noisy or secret-bearing issues.

## Validation

Last validated on 2026-05-05:

- Core install path completed with `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`.
- `tests/core-install-budget-smoke.sh` completed the core installer in 95 seconds against a 600 second budget, then passed live core smoke.
- Docker Desktop core services were running: Wizard HQ `:8888`, Open WebUI `:3000`, LiteLLM `:4000`, and Qdrant `:6333`.
- Native Ollama was running through Homebrew service.
- Approved low-tier model `qwen2.5:7b` was installed.
- Ollama local generation returned `Merlin core online`.
- LiteLLM `/v1/models` listed configured aliases and `/v1/chat/completions` with `qwen7b` returned `Merlin gateway online`.
- `scripts/doctor.sh` completed with 43 passes, 2 warnings, and 0 failures.
- Unsigned local package build produced `home-ai-elite-0.6.1.pkg`; payload check found no `.env` or generated certs. Package is not signed/notarized.

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
