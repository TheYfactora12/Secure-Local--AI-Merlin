# WIZARD AI Stack — Roadmap

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
> ⚠️  Real-hardware test on a clean Mac still needed to fully close this out.

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

## ✅ v0.8 — Wizard Brain + Model Management (DONE)
- [x] Brain renamed to **Wizard** — consistent across all containers, scripts, and workflows
- [x] `config/models/models.json` — declarative model manifest (required/optional, role, size)
- [x] `install.sh` reads `models.json` — no script editing needed to add/remove models
- [x] `dashboard/index.html` — Wizard HQ: live health dots, Ask panel, routing map, model status, activity log
- [x] `cli/wizard` — full CLI: `wizard ask`, `wizard route`, `wizard pull`, `wizard train`, `wizard backup`, `wizard open`, `wizard status`
- [x] CLI symlinked system-wide on install (available as `wizard` anywhere in terminal)
- [x] `backup/backup.sh` + `backup/restore.sh` — Qdrant memory + n8n workflow backup/restore
- [x] `config/mcp/mcp-claude-desktop.json` — Claude Desktop MCP integration ready to paste
- [x] `config/mcp/vscode-continue.json` — VS Code Continue extension config

## ✅ v0.9 — Agent + Routing Layer (DONE)
- [x] `n8n-workflows/01-smart-task-router.json` — Wizard classifies SENSITIVE/CODING/RESEARCH/GENERAL, routes accordingly
- [x] `n8n-workflows/02-daily-briefing.json` — 6AM InfoSec briefing (Perplexity news + local checklist)
- [x] `n8n-workflows/03-wizard-memory-ingestor.json` — RAG: embed docs into Qdrant via nomic-embed-text
- [x] `n8n-workflows/04-wizard-training-capture.json` — Wizard self-scores exchanges, saves quality ≥7 to memory
- [x] `n8n-workflows/05-wizard-health-monitor.json` — 15-min health check on brain + memory
- [x] SENSITIVE tasks: hardcoded local-only — never reach cloud APIs regardless of key configuration
- [x] All workflows use Wizard brain container hostname (`wizard`) for internal routing

## 🔲 v1.0 — Signed Release (NEXT)
- [ ] Signed + notarized `.pkg` tested on clean macOS 14+ machine
- [ ] `install.sh` updated to reference new `cli/`, `dashboard/`, `backup/`, `config/` paths
- [ ] Full install-to-verify under 30 minutes — documented and timed
- [ ] GitHub Release with `.pkg` artifact and `WIZARD-AI-Installer-v4.zip` attached
- [ ] One-line install command in README: `curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh | bash`
- [ ] CHANGELOG.md covering v0.1 → v1.0
- [ ] Security review: no hardcoded secrets, all ports documented, firewall rules verified
- [ ] Clean Mac smoke test: Docker → wizard start → wizard status → all green

## 🔲 v1.1 — Intelligence Upgrades (FUTURE)
- [ ] Wizard voice interface (Whisper STT → Mistral → TTS output)
- [ ] Wizard scheduled tasks (n8n cron → Wizard executes → result to memory)
- [ ] Wizard fine-tuning pipeline (export training data from Qdrant → Unsloth/LoRA)
- [ ] Multi-machine Wizard sync (Qdrant replication across 2+ local machines)
- [ ] Wizard mobile companion (iOS shortcut → n8n webhook → Wizard brain)

## 🔲 v1.2 — Hardware Layer + Full "Own Perplexity Computer" Stack
> Research session 2026-05-02: goal is a local AI as capable as paid cloud tools on right hardware.

### Hardware Decision Tree (document + automate preflight)
- [ ] `docs/hardware-guide.md` — tiered hardware specs:
  - Tier 1 (Minimum): Apple M2/M3 Mac mini, 16GB unified RAM, 512GB NVMe — runs 7B models
  - Tier 2 (Recommended): Apple M3 Pro/Max, 36–64GB unified RAM — runs 32B models at full speed
  - Tier 3 (Power): Mac Studio M2 Ultra / M3 Ultra, 96–192GB RAM — runs 70B+ locally
  - Tier 4 (GPU Box): Linux + NVIDIA RTX 4090 (24GB VRAM) or dual 3090s — runs 70B quantized
- [ ] `install.sh` hardware auto-detect: report tier, warn if under Tier 1
- [ ] `docs/hardware-guide.md` — NVMe speed matters (models load from disk): min 2GB/s read
- [ ] `docs/hardware-guide.md` — networking: gigabit LAN or better for multi-device access
- [ ] `docs/hardware-guide.md` — power/cooling baseline per tier

### Full Free Stack Map (the "own Perplexity" components)
- [ ] **Search brain**: SearXNG (already in stack) + Perplexica as the search UI — verify wired end-to-end
- [ ] **Code brain**: OpenHands (already in compose) — verify wizard routes CODING tasks to OpenHands
- [ ] **Voice brain**: Whisper (STT) + Kokoro/Piper (TTS) — add to `docker-compose.yml`
- [ ] **Image brain**: Stable Diffusion (AUTOMATIC1111 or ComfyUI) — optional compose profile
- [ ] **Document brain**: Docling or Unstructured for PDF/doc ingestion into Qdrant
- [ ] **Model quality**: verify `mistral-nemo`, `qwen2.5:32b`, `deepseek-r1:14b` in models.json as defaults
- [ ] `docs/free-stack-map.md` — full component-to-paid-equivalent mapping table

## 🔲 v1.3 — Competitive Gap Closers
> These are the exact reasons open source home AI projects have failed or stayed inferior to paid tools.
> Each item below is a documented failure pattern from real community data (2025–2026).
> Closing these gaps is what makes Wizard as good as the paid ones.

### Gap 1: Memory degrades over time (most common open-source failure)
- Problem: RAG pipelines accumulate stale context. Model retrieves old memories alongside new ones.
  Outputs look plausible but are wrong. Subtle, hard to catch.
- Fix: [ ] Implement structured memory schema in Qdrant — define what gets stored, when it expires,
  and what triggers an update. Not just "embed everything." Add `wizard memory clean` CLI command.

### Gap 2: n8n + Ollama structured output failures (known production bug)
- Problem: n8n Ollama node cancels requests mid-stream → HTTP 500 "context canceled" →
  Structured Output Parser throws "Model output doesn't fit required format."
  Affects any n8n agent workflow using local models with tool calls or JSON output.
- Fix: [ ] Add response timeout + retry logic to all n8n workflows using Ollama nodes.
  [ ] Add `wizard test-workflows` CLI command to validate all n8n workflows against local model.
  [ ] Document workaround in `tests/README.md`.

### Gap 3: No persistent cross-session identity (open source stacks feel "amnesia" by default)
- Problem: Every new chat starts cold. Cloud tools (ChatGPT, Perplexity) remember user context
  across sessions. Local stacks do not without explicit engineering.
- Fix: [ ] `n8n-workflows/06-session-memory-bridge.json` — auto-inject top-5 relevant memories
  into every new Open WebUI session via system prompt enrichment.

### Gap 4: Web search quality gap vs. Perplexity
- Problem: SearXNG returns results; Perplexica synthesizes them. But citation quality and
  answer accuracy still trails Perplexity Pro (92% factual accuracy in LMSYS April 2026 eval).
  Local stacks often skip re-ranking and source validation.
- Fix: [ ] Add re-ranking step to Perplexica config (cross-encoder reranker via Ollama).
  [ ] Add source freshness filter (prefer results < 30 days for research queries).
  [ ] `wizard search "<query>"` CLI command to test search pipeline quality directly.

### Gap 5: Setup complexity causes abandonment (most projects die here)
- Problem: Even technical users report spending hours on Ollama/n8n connectivity issues,
  wrong hostnames, port conflicts, and compose networking. Non-technical users give up entirely.
- Fix: [ ] `scripts/doctor.sh` — pre-flight diagnostic that checks every service port, hostname
  resolution, model availability, and n8n connectivity before user hits any issue.
  [ ] `wizard doctor` CLI command wraps this.
  [ ] Add troubleshooting section to README with the 10 most common failure modes.

### Gap 6: Model quality perception gap (local models feel "dumber")
- Problem: Users compare 7B local models to GPT-5 or Claude 3.5. Wrong comparison.
  The right comparison is 32B+ quantized models vs. GPT-3.5-class — where local wins on privacy.
  Perception gap causes abandonment even when the model is sufficient.
- Fix: [ ] `docs/model-selection-guide.md` — map tasks to right model size. Stop defaulting
  to smallest model. Set `qwen2.5:32b` as default brain on Tier 2+ hardware.
  [ ] `install.sh` model tier auto-selection based on detected RAM.

### Gap 7: No upgrade path keeps users locked on old models/versions
- Problem: Self-hosted stacks go stale. Users run 6-month-old models because updating
  is manual and risky. Cloud tools update silently.
- Fix: [ ] `scripts/upgrade.sh` already exists — extend it to also pull latest models
  from `models.json` and update n8n workflows from repo.
  [ ] Add `wizard upgrade` to CLI. Add weekly upgrade reminder to daily briefing workflow.

---
> **Rule:** Any new feature, bug found, or variation discovered gets added here before code is written.
> Maintained by: TheYfactora12 | Oxford, MA
