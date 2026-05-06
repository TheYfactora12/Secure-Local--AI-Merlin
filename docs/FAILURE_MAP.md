# Self-Hosted AI Failure Map

> **Purpose:** Map 20 documented failure modes across real self-hosted AI projects, their root causes, and the concrete mitigations built into this installer to prevent them. This is a living document — update it when new failure patterns are observed.

---

## Executive Summary

The #1 cause of self-hosted AI project death is not hardware or model quality — it is **operational neglect after launch**: services that drift, secrets that leak, updates that break things, and no process to recover. Second is **hardware undersizing**, which kills performance before the stack ever gets a fair test. This document maps 20 failure modes with specific targets this project is designed to meet.

---

## Failure Mode Map

### Category 1 — Hardware & Infrastructure

| # | Failure Mode | Root Cause | Real-World Example | Our Target / Mitigation |
|---|---|---|---|---|
| 1 | **RAM starvation kills inference** | Running too many services or too-large models on low-memory machines | Users running Ollama + Open WebUI + n8n + Qdrant on M1 MacBook Air 8GB — swap thrashing, 30s+ response times | 8GB is the entry point and is supported only in low/core mode. Doctor warns against heavy profiles and model pulls are opt-in. |
| 2 | **GPU/NPU not utilized** | Default Docker config ignores Apple Silicon GPU; models run on CPU | Ollama installed via Docker without Metal acceleration — 10x slower than native | Ollama installed natively (not Docker) to get full Metal GPU access on Apple Silicon |
| 3 | **Disk fills silently** | Model files (4–20GB each), n8n logs, Qdrant vectors grow unbounded | Qdrant fills `/var/lib/docker` volume, container crashes with no warning | `status.sh` monitors disk usage; launchd agent alerts at 80% disk; model storage mapped to external volume path |
| 4 | **Docker Desktop memory cap** | Default Docker Desktop on Mac limits container memory to 2GB | Open WebUI OOM-killed repeatedly; users can't figure out why | `docker-compose.yml` includes `mem_limit` directives; README documents Docker Desktop memory setting to 10GB+ |
| 5 | **Port conflicts block startup** | Multiple services competing for common ports (3000, 8080, 5678) | Open WebUI port 3000 conflicts with local dev server; silent failure | Core services bind to documented localhost ports and `wizard doctor` reports closed/unreachable services without mutating the system. |

---

### Category 2 — Security & Secrets

| # | Failure Mode | Root Cause | Real-World Example | Our Target / Mitigation |
|---|---|---|---|---|
| 6 | **API keys committed to git** | Hardcoded keys in `docker-compose.yml` or scripts pushed to GitHub | Perplexity, OpenAI, Anthropic keys leaked in public GitHub repos — credentials rotated, costs incurred | `.env` excluded via `.gitignore`; `.env.example` has no real values; gitleaks pre-commit hook blocks accidental commits |
| 7 | **Services exposed on 0.0.0.0** | Default Docker bind to all interfaces exposes services to LAN/internet | n8n webhook port accessible to entire home network or cloud VPS public IP | All services bind to `127.0.0.1` by default; explicit `ports: "127.0.0.1:XXXX:XXXX"` in compose |
| 8 | **No auth on Open WebUI** | Fresh install has no password; anyone on network can access | Home lab users surprised to find Open WebUI accessible from phone on same WiFi | `WEBUI_SECRET_KEY` required in `.env`; first-run forces admin password setup |
| 9 | **n8n credentials stored plaintext** | Default n8n SQLite stores credentials unencrypted | n8n database copied/backed up with all API keys in plaintext | `N8N_ENCRYPTION_KEY` set in `.env`; documented in setup checklist |
| 10 | **Ollama API open with no auth** | Ollama has no built-in auth; if bound to 0.0.0.0 anyone can pull/run models | Ollama exposed on VPS public IP used as free inference endpoint by strangers | Ollama bound to `127.0.0.1:11434` only; only Open WebUI talks to it via Docker network |

---

### Category 3 — Reliability & Operations

| # | Failure Mode | Root Cause | Real-World Example | Our Target / Mitigation |
|---|---|---|---|---|
| 11 | **No health checks; silent failures** | Services crash and nobody knows until someone tries to use them | Qdrant OOM crash goes unnoticed for days; embeddings silently fail in n8n workflows | `status.sh` checks all service health endpoints; launchd `HealthMonitor.plist` runs every 5 min and logs failures |
| 12 | **Updates break the stack** | `docker compose pull` without version pinning pulls breaking changes | Open WebUI 0.4→0.5 migration broke custom model configs; n8n 1.x→2.x broke workflows | All images version-pinned in `docker-compose.yml`; `scripts/update.sh` pulls then runs smoke tests before accepting |
| 13 | **No backup; data loss on rebuild** | Qdrant collections, n8n workflows, Open WebUI history stored only in Docker volumes | Mac rebuilt, Docker Desktop reset — all vector embeddings, workflows, chat history gone | `scripts/backup.sh` exports n8n workflows as JSON, snapshots Qdrant, copies Open WebUI DB to `~/home-ai-elite/backup/` |
| 14 | **Mac sleep kills Docker services** | macOS aggressive power management suspends Docker containers | MacBook lid close stops all AI services; webhooks fail; scheduled n8n jobs miss | `launchd/` plists configure wake-on-network; README documents Energy Saver settings; `caffeinate` wrapper in bootstrap |
| 15 | **No rollback path** | One bad config change or update bricks entire stack with no documented recovery | Edited `docker-compose.yml` breaks Qdrant volume mount — spend hours debugging | `scripts/rollback.sh` restores last known-good compose and env from backup; CHANGELOG documents every breaking change |

---

### Category 4 — Model & AI Quality

| # | Failure Mode | Root Cause | Real-World Example | Our Target / Mitigation |
|---|---|---|---|---|
| 16 | **Wrong model for task** | Using a 3B chat model for code generation or a 70B model on 16GB RAM | llama3.2:3b used for complex reasoning — poor output quality blamed on "local AI is bad" | Model selection guide in README: llama3.1:8b for chat, deepseek-coder-v2:16b for code, nomic-embed-text for RAG |
| 17 | **RAG returns garbage** | Wrong embedding model, chunk size mismatch, or Qdrant collection misconfigured | Using mxbai-embed-large with 2048-char chunks — retrieval irrelevant, LLM hallucinates anyway | `configs/qdrant-collections.json` standardizes collection setup; embedding model pinned to `nomic-embed-text:v1.5` |
| 18 | **Context window overflow** | Sending too much context to small models causes truncation and incoherent output | n8n workflow sends 50-message chat history to 8B model — last messages ignored | n8n workflow templates include context windowing; max 10-turn history passed to local models |
| 19 | **Unsafe cloud fallback** | Cloud escalation happens without explicit user approval | Sensitive local prompts get sent to external APIs because fallback logic is automatic | Local-first routing is mandatory. Cloud providers are optional, disabled by default, and require explicit user approval. |

---

### Category 5 — Installer & Reproducibility

| # | Failure Mode | Root Cause | Real-World Example | Our Target / Mitigation |
|---|---|---|---|---|
| 20 | **Non-idempotent installer** | Running `install.sh` twice breaks things; no checks for already-installed components | Re-running setup script reinstalls Homebrew packages, resets `.env`, breaks running containers | `install.sh` uses `command -v` checks and `brew list` guards; all steps are idempotent — safe to re-run |

---

## Risk Priority Matrix

| Priority | Failure Mode | Impact | Likelihood | Status |
|---|---|---|---|---|
| 🔴 P0 | Secret/key leak to git (#6) | Critical — credential exposure | High — easy mistake | ✅ Mitigated (gitleaks + gitignore) |
| 🔴 P0 | Services exposed on 0.0.0.0 (#7) | Critical — unauthorized access | High — Docker default | ✅ Mitigated (127.0.0.1 bind) |
| 🔴 P0 | RAM starvation (#1) | High — unusable stack | High — common hardware | ✅ Mitigated (preflight check) |
| 🟠 P1 | No backup (#13) | High — unrecoverable data loss | Medium | ✅ Mitigated (backup.sh) |
| 🟠 P1 | Silent service failure (#11) | High — invisible outage | Medium | ✅ Mitigated (status.sh + launchd) |
| 🟠 P1 | Updates break stack (#12) | Medium — stack downtime | High — frequent updates | ✅ Mitigated (version pinning + smoke test) |
| 🟡 P2 | Wrong model for task (#16) | Medium — poor output quality | High — no guidance | ⚠️ Partially mitigated (README guide) |
| 🟡 P2 | RAG garbage output (#17) | Medium — trust erosion | Medium | ⚠️ Partially mitigated (collection config) |
| 🟡 P2 | Cloud fallback never triggers (#19) | Medium — missed capability | Medium | 🔲 Planned (ModelRouter workflow) |
| 🟢 P3 | Mac sleep kills services (#14) | Low-Medium — convenience | High | ⚠️ Partially mitigated (launchd) |

---

## Targets: Definition of Done

The stack is considered production-ready for home lab use when all of the following are true:

- [ ] `install.sh` runs idempotently from zero to working stack in < 30 minutes on a supported Mac
- [ ] 8GB machines install in low/core mode with conservative model/service defaults
- [ ] All services bind to `127.0.0.1` only; zero open ports on LAN interfaces
- [ ] `.env` is never tracked by git; gitleaks pre-commit hook is active
- [ ] `status.sh` returns green for all 5 services (Ollama, Open WebUI, n8n, Qdrant, launchd agents)
- [ ] `backup.sh` runs on schedule and produces restorable artifacts
- [ ] `rollback.sh` can restore last known-good state in < 5 minutes
- [ ] Model selection defaults are documented with specific model names and use cases
- [ ] Model routing remains local-first and never escalates to cloud without explicit approval
- [ ] Zero secrets in git history (verified with `git log -p | grep -E 'sk-|Bearer'`)

---

## Changelog

| Date | Change |
|---|---|
| 2026-05-02 | Initial failure map created — 20 failure modes documented across 5 categories |
