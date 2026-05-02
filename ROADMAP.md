# WIZARD AI Stack — Roadmap

> **Failure Map:** See [`docs/failure-map.md`](docs/failure-map.md) for the 20 documented patterns
> from real self-hosted AI projects that failed. Every v1.3 item below closes a specific failure.

> **Research Log:** Session 2026-05-02 — benchmarks, observability, memory architecture, Ollama MLX,
> and self-hosted failure mapping added as v1.5, v1.6, v1.7 milestones.

> **Stress Test Log:** Session 2026-05-02 — rc2 patch closes 8 surfaces found in hard stress test.
> See commit history for surface-by-surface findings.

---

## ✅ v0.1 — Foundation
- [x] Repo scaffolding & folder structure
- [x] `docker-compose.yml` — 8 services wired together
- [x] `.env.example` — all variables documented
- [x] `README.md` — architecture, hardware tiers, commands
- [x] `scripts/` — status, stop, restart, update, backup, add-model

## ✅ v0.2 — Full Stack Config
- [x] `install.sh` — RAM-aware, 4 model tiers, health checks, dashboard
- [x] `configs/litellm/config.yaml` — local-first model router
- [x] `configs/searxng/settings.yml` — private web search
- [x] `configs/perplexica/config.toml` — AI-powered search frontend
- [x] `n8n-workflows/ai-router.json` — starter automation workflow
- [x] `mcp/install-mcp-servers.sh` — GitHub + Qdrant MCP connectors

## ✅ v0.3 — First-Boot Automation
- [x] `scripts/init-qdrant.sh` — auto-create 4 Qdrant collections
- [x] `scripts/import-n8n-workflows.sh` — auto-import via REST API
- [x] `scripts/bootstrap.sh` — orchestrates full first-boot init
- [x] `launchd/` — macOS auto-start on login (Docker + all services)
- [x] `launchd/install-launchd.sh` — one-command setup + uninstall

## ✅ v0.4 — CI/CD + Safe Upgrades
- [x] `.github/workflows/ci.yml` — ShellCheck, compose validate, JSON/YAML lint
- [x] `scripts/upgrade.sh` — backup → pull → restart → health check → auto-rollback
- [x] `.github/workflows/release.yml` — auto-tag GitHub releases on main

## ✅ v0.5 — macOS PKG Installer
- [x] `pkg/build-pkg.sh` — sign & notarize a `.pkg` with pkgbuild
- [x] Pre-install script: preflight checks (macOS version, RAM, disk space)
- [x] Post-install script: runs install.sh + bootstrap.sh silently
- [x] LaunchAgent installed by the pkg
- [x] Uninstaller bundled inside the pkg
> ⚠️ Real-hardware test on a clean Mac still needed to fully close this out.

## ✅ v0.6 — QC Hardening & Test Layer
- [x] `tests/e2e-test.sh` — service health end-to-end validation
- [x] `tests/README.md` — how to run tests, expected output, failure guide
- [x] `.gitleaks.toml` — secret scanning config
- [x] CI: `tests/` + `pkg/scripts/` syntax check added
- [x] CI: secret scan job (gitleaks + pattern check)

## ✅ v0.7 — Security Hardening
- [x] `configs/nginx/nginx.conf` — Nginx TLS reverse proxy, HTTP→HTTPS redirect, rate limiting
- [x] `configs/fail2ban/jail.local` — Fail2ban: 5 failures = 1hr ban
- [x] `configs/fail2ban/filter.d/open-webui.conf` + `n8n.conf`
- [x] `docker-compose.yml` — Nginx, Fail2ban, Watchtower added
- [x] `launchd/com.homeai.backup.plist` — daily 2am backup timer
- [x] `scripts/generate-certs.sh` — self-signed TLS cert generator
- [x] `scripts/healthcheck.sh` — full stack health + optional webhook ping

## ✅ v0.8 — Wizard Brain + Model Management
- [x] Brain renamed to **Wizard** — consistent across all containers, scripts, and workflows
- [x] `config/models/models.json` — declarative model manifest (required/optional, role, size)
- [x] `install.sh` reads `models.json` — no script editing needed to add/remove models
- [x] `dashboard/index.html` — Wizard HQ: live health dots, Ask panel, routing map, model status, activity log
- [x] `cli/wizard` — full CLI: `wizard ask`, `wizard route`, `wizard pull`, `wizard train`, `wizard backup`, `wizard open`, `wizard status`
- [x] CLI symlinked system-wide on install (available as `wizard` anywhere in terminal)
- [x] `backup/backup.sh` + `backup/restore.sh` — Qdrant memory + n8n workflow backup/restore
- [x] `config/mcp/mcp-claude-desktop.json` — Claude Desktop MCP integration ready to paste
- [x] `config/mcp/vscode-continue.json` — VS Code Continue extension config

## ✅ v0.9 — Agent + Routing Layer
- [x] `n8n-workflows/01-smart-task-router.json` — classifies SENSITIVE/CODING/RESEARCH/GENERAL
- [x] `n8n-workflows/02-daily-briefing.json` — 6AM InfoSec briefing
- [x] `n8n-workflows/03-wizard-memory-ingestor.json` — RAG: embed docs into Qdrant
- [x] `n8n-workflows/04-wizard-training-capture.json` — self-scores exchanges, saves quality ≥7
- [x] `n8n-workflows/05-wizard-health-monitor.json` — 15-min health check
- [x] SENSITIVE tasks: hardcoded local-only — never reach cloud APIs
- [x] All workflows use Wizard brain container hostname (`wizard`) for internal routing

---

## 🔲 v1.0 — Signed Release (NEXT — DO NOT DEVIATE)

### Stress Test Patches Applied (rc1 + rc2)
- [x] **rc1** — `install.sh`: macOS `df -BG` crash fixed (cross-platform `df -k`)
- [x] **rc1** — `install.sh`: `llama3.3:70b-instruct-q4_K_M` → canonical `llama3.3:70b` tag
- [x] **rc1** — `install.sh`: explicit `cli/wizard` file check before symlink with actionable error
- [x] **rc2** — `docker-compose.yml`: removed deprecated `version: '3.8'` key
- [x] **rc2** — `docker-compose.yml`: Ollama port bound to `127.0.0.1:11434` (was `0.0.0.0` — LAN bypass risk)
- [x] **rc2** — `docker-compose.yml`: Qdrant gRPC port `6334` removed (unused, zero-auth exposure)
- [x] **rc2** — `docker-compose.yml`: all secret fallbacks changed from known defaults to `REQUIRED_CHANGE_ME` (loud failure vs. silent insecurity)
- [x] **rc2** — `docker-compose.yml`: healthcheck blocks added to LiteLLM, Open WebUI, n8n
- [x] **rc2** — `docker-compose.yml`: `ENABLE_SIGNUP` moved to `.env` variable (lockdown without editing compose)
- [x] **rc2** — `install.sh`: `nomic-embed-text` pull failure is now `err` (hard stop — was `warn`+continue; silent failure breaks all RAG)
- [x] **rc2** — `nginx depends_on` upgraded to `service_healthy` conditions on all upstream services
- [x] **rc2** — `openhands depends_on` upgraded to `service_healthy` on `litellm`

### Remaining v1.0 Gate Items
- [ ] Signed + notarized `.pkg` tested on clean macOS 14+ machine
- [ ] Full install-to-verify under 30 minutes — documented and timed
- [ ] GitHub Release with `.pkg` artifact and `WIZARD-AI-Installer-v1.0.zip` attached
- [ ] One-line install verified: `curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh | bash`
- [ ] `CHANGELOG.md` covering v0.1 → v1.0 finalized
- [ ] Security review: no hardcoded secrets ✔ (rc2), all ports documented ✔ (rc2), firewall rules verified
- [ ] Clean Mac smoke test: Docker → `wizard start` → `wizard status` → all green
- [ ] Update `.env.example` with `ENABLE_SIGNUP=true # Set false after admin account created`

## 🔲 v1.1 — Intelligence Upgrades
- [ ] Wizard voice interface (Whisper STT → Mistral → TTS output)
- [ ] Wizard scheduled tasks (n8n cron → Wizard executes → result to memory)
- [ ] Wizard fine-tuning pipeline (export training data from Qdrant → Unsloth/LoRA)
- [ ] Multi-machine Wizard sync (Qdrant replication across 2+ local machines)
- [ ] **Wizard mobile companion** — Closes Failure 18 (AI trapped on desktop)
  - iOS shortcut → n8n webhook → Wizard brain

## 🔲 v1.2 — Hardware Layer + Full “Own Perplexity Computer” Stack
> Research session 2026-05-02: goal is local AI as capable as paid cloud tools on right hardware.

### Hardware Decision Tree
- [ ] `docs/hardware-guide.md` — tiered hardware specs:
  - Tier 1 (Minimum): Apple M2/M3 Mac mini, 16GB RAM — 7B models
  - Tier 2 (Recommended): Apple M3 Pro/Max, 36–64GB RAM — 32B models
  - Tier 3 (Power): Mac Studio M2/M3 Ultra, 96–192GB RAM — 70B+ models
  - Tier 4 (GPU Box): Linux + NVIDIA RTX 4090 (24GB VRAM) — 70B quantized
- [ ] `install.sh` hardware auto-detect: report tier, warn if under Tier 1
- [ ] NVMe speed requirement documented (min 2GB/s read for model loading)
- [ ] Networking baseline: gigabit LAN or better for multi-device access

### Full Free Stack Map
- [ ] **Search brain**: SearXNG + Perplexica — verify wired end-to-end
- [ ] **Code brain**: OpenHands — verify wizard routes CODING tasks to OpenHands
- [ ] **Voice brain**: Whisper (STT) + Kokoro/Piper (TTS) — add to compose
- [ ] **Image brain**: ComfyUI/AUTOMATIC1111 — optional compose profile
- [ ] **Document brain**: Docling/Unstructured for PDF/doc ingestion — **Closes Failure 10**
- [ ] Model quality: verify `mistral-nemo`, `qwen2.5:32b`, `deepseek-r1:14b` as defaults
- [ ] `docs/free-stack-map.md` — component-to-paid-equivalent mapping table

## 🔲 v1.3 — Competitive Gap Closers
> Ordered by **abandonment impact** from `docs/failure-map.md` research.
> Each item closes one or more of the 20 documented failure patterns.
> Build in this exact sequence — do not reorder.

### Priority 1: `wizard doctor` — Closes Failures 1, 4, 15 (Setup Abandonment)
> Highest ROI item. Prevents the most common abandonment cause: hours of debugging before first chat.
- [ ] `scripts/doctor.sh` — preflight check: all 8 ports, hostname resolution, model availability,
  n8n connectivity, env vars, Docker network, disk space
- [ ] `wizard doctor` CLI command wraps this — run before first boot and after any change
- [ ] Add troubleshooting section to README: top 10 failure modes with exact fix commands

### Priority 2: n8n Ollama Retry Logic — Closes Failure 2 (Silent Workflow Failures)
> Prevents production workflows from failing silently mid-stream.
- [ ] Add response timeout + retry logic to all n8n workflows using Ollama nodes
- [ ] `wizard test-workflows` CLI command: validates all 5 n8n workflows against local model
- [ ] Document "context canceled" workaround in `tests/README.md`

### Priority 3: Structured Qdrant Memory Schema — Closes Failures 6, 7, 8 (Amnesia + Drift)
> Makes Wizard feel smart across sessions. Fixes the #1 “AI feels dumb” complaint.
- [ ] Define memory schema: payload fields (type, source, timestamp, ttl, quality_score)
- [ ] `wizard memory clean` CLI: prune stale/low-score memories from all 4 collections
- [ ] `n8n-workflows/06-session-memory-bridge.json` — auto-inject top-5 relevant memories
  into every new Open WebUI session via system prompt enrichment
- [ ] Memory expiry rules: conversation memories expire 30 days, facts/preferences never expire

### Priority 4: Model Tier Auto-Selection — Closes Failure 11 (7B Perception Gap)
> Stops users from using the wrong model and concluding local AI is inferior.
- [ ] `install.sh` auto-detects RAM and sets default model tier:
  - 16GB → `mistral-nemo` (12B), 32GB+ → `qwen2.5:32b`, 64GB+ → `qwen2.5:72b`
- [ ] `docs/model-selection-guide.md` — task-to-model mapping: coding, analysis, search, sensitive
- [ ] `wizard model recommend` CLI: suggests best model for available hardware

### Priority 5: Web Search Quality Upgrades — Closes Failure 14 (Search Gap vs. Perplexity)
> Brings search answer quality closer to Perplexity Pro.
- [ ] Add cross-encoder reranking step to Perplexica config (via Ollama reranker model)
- [ ] Add source freshness filter: prefer results < 30 days for research queries
- [ ] `wizard search "<query>"` CLI command: test search pipeline quality directly
- [ ] `docs/search-quality-guide.md` — how Wizard search compares to Perplexity, what to expect

### Priority 6: `scripts/upgrade.sh` Extension — Closes Failure 17 (Stale Stack)
> Keeps Wizard current without manual intervention.
- [ ] Extend `scripts/upgrade.sh` to also pull latest models from `models.json`
- [ ] Extend to pull latest n8n workflows from repo
- [ ] Add `wizard upgrade` CLI wrapper
- [ ] Add weekly upgrade reminder to daily briefing workflow (02-daily-briefing.json)

---

## 🔲 v1.4 — Full Hardware Research Package (“Own Perplexity Computer”)
- [ ] `docs/hardware-buying-guide.md` — exact hardware recommendations with current prices
- [ ] `docs/equipment-checklist.md` — complete shopping list from Mac to NVMe to networking
- [ ] `install.sh` — single-command installs full stack + all components from scratch
- [ ] Target: blank Mac → fully working Wizard stack in under 30 minutes

---

## 🔲 v1.5 — Memory Benchmark Harness
> **Source:** 2026-05-02 research — MemoryArena, EpBench, AMA-Bench integration guide.
> Goal: Wizard memory is not just functional — it is **measurable and improvable**.
> Every memory feature must pass benchmark gates before merge.

### Benchmark Suites (add in this order)
| Suite | What it tests | Primary metrics |
|---|---|---|
| EpBench | Episodic recall, event ordering, temporal grounding | Recall@k, F1, Kendall's τ, answer grounding |
| MemoryArena | Multi-session interdependent task completion | Task success, cross-session dependency success, memory usefulness |
| AMA-Bench | Long-horizon agent memory under realistic trajectories | Horizon-scaled accuracy, causal retrieval quality |

### Deliverables
- [ ] `tests/benchmarks/` directory scaffold — one subdir per suite
- [ ] `tests/benchmarks/schema.py` — canonical case object: `{id, suite, sessions, writes, queries, expected, metadata}`
- [ ] `tests/benchmarks/epbench/adapter.py` — EpBench adapter: episodic write → recall → ordering
- [ ] `tests/benchmarks/memoryarena/adapter.py` — MemoryArena adapter: session loop, action-memory tracking
- [ ] `tests/benchmarks/amabench/adapter.py` — AMA-Bench adapter: long trajectory + causal retrieval hooks
- [ ] `tests/benchmarks/metrics.py` — shared metrics engine: latency p50/p95, hit@k, contradiction drift rate, latest-truth accuracy
- [ ] `tests/benchmarks/layer_aware.py` — layer-aware scoring: did router query right layer?
- [ ] `scripts/run-benchmarks.sh` — unified runner with profile flags
- [ ] `config/benchmarks/wizard.yaml` — tunable knobs: `top_k`, horizon_length, noise_ratio, contradiction_rate
- [ ] `wizard benchmark run` CLI command
- [ ] CI gate: EpBench recall@5 ≥ 0.75 required to merge memory-layer changes
- [ ] JSONL result output → Langfuse (when v1.6 is live) for trend tracking

### Memory Layer Architecture
- [ ] Split Qdrant collections explicitly by layer:
  - `wizard_working` — short-term, session-scoped, TTL 4 hours
  - `wizard_episodic` — events with timestamps, entities, state changes, TTL 30 days
  - `wizard_semantic` — facts, preferences, long-term knowledge, no expiry
  - `wizard_action` — agent action history with outcomes, TTL 90 days
- [ ] `scripts/init-qdrant.sh` updated to create all 4 collections with correct schemas
- [ ] Memory router: classify each write and route to correct layer before storing
- [ ] Retrieval router: query correct layer(s) based on query type

---

## 🔲 v1.6 — Observability Layer (Langfuse)
> Goal: Wizard is not a black box. Every prompt, route decision, memory lookup, and failure is traceable.

- [ ] Add Langfuse to `docker-compose.yml` as a local self-hosted service
- [ ] `configs/langfuse/` — env config for self-hosted Langfuse instance
- [ ] Ollama → Langfuse tracing via OpenAI-compatible SDK wrapper
- [ ] n8n workflows emit trace IDs to Langfuse on every Ollama call
- [ ] Memory layer emits read/write events to Langfuse
- [ ] Benchmark results (v1.5) export JSONL to Langfuse for trend dashboards
- [ ] `wizard trace <session_id>` CLI: inspect full trace for a session
- [ ] `wizard score` CLI: show last 7-day quality trend from Langfuse
- [ ] `docs/observability-guide.md`

---

## 🔲 v1.7 — Wizard Brain v2 (Self-Improving Agent OS)
> Goal: Wizard stops being “a model that answers” and becomes “an agent OS that learns.”

### Model Router v2 — Specialist Routing
- [ ] Replace single-model routing with specialist model dispatch
- [ ] Router confidence scoring: if confidence < 0.7, escalate to next model tier
- [ ] `wizard route "<query>"` CLI: shows routing decision + confidence
- [ ] Router decisions logged to Langfuse (requires v1.6)

### MoE Gating Layer (Experimental)
- [ ] `src/router/moe_gate.py` — lightweight MoE gating network in PyTorch
- [ ] A/B test: MoE gate vs. rule-based router on MemoryArena benchmark
- [ ] `wizard train-gate` CLI: weekly gate re-training from Langfuse data

### Critic + Self-Improvement Loop
- [ ] `n8n-workflows/07-wizard-critic.json` — Wizard scores its own responses 1–10
- [ ] Weekly self-improvement report
- [ ] `wizard improve` CLI: manual critic review on last 100 sessions
- [ ] Contradiction detection before every memory write

### Ollama MLX Optimization (Apple Silicon)
- [ ] Verify MLX preview enabled (`OLLAMA_USE_MLX=1`)
- [ ] `docs/apple-silicon-optimization.md`
- [ ] Benchmark: tokens/sec before/after MLX per specialist model
- [ ] `install.sh` auto-enable MLX on Apple Silicon
- [ ] Add MLX status to `wizard status` + `scripts/healthcheck.sh`

---

## Milestone Summary

| Milestone | Focus | Status | Gate |
|---|---|---|---|
| v0.1–v0.9 | Foundation → Agent routing | ✅ Complete | — |
| v1.0 | Signed release | 🔲 **rc2 — smoke test remaining** | Clean Mac smoke test |
| v1.1 | Voice + fine-tuning | 🔲 Planned | v1.0 complete |
| v1.2 | Hardware guide + full stack | 🔲 Planned | v1.0 complete |
| v1.3 | Competitive gap closers | 🔲 Planned | v1.0 complete |
| v1.4 | Hardware research package | 🔲 Planned | v1.2 complete |
| v1.5 | Memory benchmark harness | 🔲 Planned | Memory layer split done |
| v1.6 | Observability (Langfuse) | 🔲 Planned | v1.5 JSONL output done |
| v1.7 | Wizard Brain v2 — self-improving | 🔲 Planned | v1.5 + v1.6 complete |

---

> **Rule:** Any new feature, bug found, or variation discovered gets added here before code is written.
> **Stress Test Rule:** Run full 8-surface stress test before every release candidate tag.
> **Failure Map:** [`docs/failure-map.md`](docs/failure-map.md) — 20 patterns, update when new ones found.
> **Research Log:** See session notes in `docs/research/` for source reasoning behind each milestone.
> Maintained by: TheYfactora12
