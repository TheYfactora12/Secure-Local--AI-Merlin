# WIZARD AI Stack — Roadmap

> **Failure Map:** See [`docs/failure-map.md`](docs/failure-map.md) for the 20 documented patterns
> from real self-hosted AI projects that failed. Every v1.3 item below closes a specific failure.

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
- [ ] Signed + notarized `.pkg` tested on clean macOS 14+ machine
- [ ] `install.sh` updated to reference new `cli/`, `dashboard/`, `backup/`, `config/` paths
- [ ] Full install-to-verify under 30 minutes — documented and timed
- [ ] GitHub Release with `.pkg` artifact and `WIZARD-AI-Installer-v4.zip` attached
- [ ] One-line install: `curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh | bash`
- [ ] `CHANGELOG.md` covering v0.1 → v1.0
- [ ] Security review: no hardcoded secrets, all ports documented, firewall rules verified
- [ ] Clean Mac smoke test: Docker → wizard start → wizard status → all green

## 🔲 v1.1 — Intelligence Upgrades
- [ ] Wizard voice interface (Whisper STT → Mistral → TTS output)
- [ ] Wizard scheduled tasks (n8n cron → Wizard executes → result to memory)
- [ ] Wizard fine-tuning pipeline (export training data from Qdrant → Unsloth/LoRA)
- [ ] Multi-machine Wizard sync (Qdrant replication across 2+ local machines)
- [ ] **Wizard mobile companion** — Closes Failure 18 (AI trapped on desktop)
  - iOS shortcut → n8n webhook → Wizard brain

## 🔲 v1.2 — Hardware Layer + Full "Own Perplexity Computer" Stack
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
- [ ] Document \"context canceled\" workaround in `tests/README.md`

### Priority 3: Structured Qdrant Memory Schema — Closes Failures 6, 7, 8 (Amnesia + Drift)
> Makes Wizard feel smart across sessions. Fixes the #1 \"AI feels dumb\" complaint.
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
- [ ] `wizard search \"<query>\"` CLI command: test search pipeline quality directly
- [ ] `docs/search-quality-guide.md` — how Wizard search compares to Perplexity, what to expect

### Priority 6: `scripts/upgrade.sh` Extension — Closes Failure 17 (Stale Stack)
> Keeps Wizard current without manual intervention.
- [ ] Extend `scripts/upgrade.sh` to also pull latest models from `models.json`
- [ ] Extend to pull latest n8n workflows from repo
- [ ] Add `wizard upgrade` CLI wrapper
- [ ] Add weekly upgrade reminder to daily briefing workflow (02-daily-briefing.json)

---

## 🔲 v1.4 — Full Hardware Research Package (\"Own Perplexity Computer\")
- [ ] `docs/hardware-buying-guide.md` — exact hardware recommendations with current prices
- [ ] `docs/equipment-checklist.md` — complete shopping list from Mac to NVMe to networking
- [ ] `install.sh` — single-command installs full stack + all components from scratch
- [ ] Target: blank Mac → fully working Wizard stack in under 30 minutes

---
> **Rule:** Any new feature, bug found, or variation discovered gets added here before code is written.
> **Failure Map:** [`docs/failure-map.md`](docs/failure-map.md) — 20 patterns, update when new ones found.
> Maintained by: TheYfactora12 | Oxford, MA
