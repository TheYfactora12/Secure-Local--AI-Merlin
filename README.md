# Home AI Elite

> **Private AI at home in 30 minutes. No cloud account, no subscription, no terminal knowledge required for the finished product.**

Home AI Elite is a local-first Mac product that installs a private AI stack on
hardware you own. Merlin is the AI assistant inside it: the voice, chat, memory,
routing, and safety layer that helps a non-technical user ask questions, save
useful context into local Rooms, and see proof that cloud is off by default.

The product is built for the privacy-conscious Mac owner who wants the power of
ChatGPT-style assistance without sending personal conversations, work files, or
family data to someone else's servers.

Home AI Elite protects the user's private AI home:

- **Wizard HQ** is the friendly app surface.
- **Merlin** is the assistant the user talks to.
- **Rooms** organize local chat history and project context.
- **The Vault** stores approved memory only after the user agrees.
- **The Watchtower** shows readiness, privacy, model, and service status.
- **The Round Table** handles approvals for anything sensitive.

The product is intentionally local-first: start with the lightweight core profile, keep cloud disabled by default, and enable heavier profiles such as search, automation, coding agents, and server operations only when the machine and the user are ready.

[![Version](https://img.shields.io/badge/version-0.2-blue)]
[![License](https://img.shields.io/badge/license-MIT-green)]

---

## Brand Direction

**Home AI Elite** is the product name. **Merlin** is the AI assistant inside the
product.

Some dashboard, installer, package, and documentation surfaces still say
`Merlin AI` because an earlier brand direction favored that name. Issue #131 now
tracks the cleanup path: keep runtime compatibility paths stable, but make the
external promise clear and simple for non-technical users.

See [`docs/product/MERLIN_MYTHOLOGY_BRAND_SYSTEM.md`](docs/product/MERLIN_MYTHOLOGY_BRAND_SYSTEM.md)
for the internal naming system. Myth names are only allowed when they map to
real user-facing controls, not decoration.

---

## Release Readiness

Home AI Elite is currently being prepared for a controlled **Local Trusted Beta**.
It is not being claimed as Public Beta ready yet.

- Installer/downloader Merlin branding is complete and covered by
  `tests/installer-branding-smoke.sh`.
- Wizard HQ startup readiness is read-only and must show ready/degraded states
  from live localhost checks, not hardcoded success.
- The beta evidence runbook is
  [`docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`](docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md).
- Public release packaging and onboarding hardening remain tracked in #37.
- Developer ID signing/notarization remains tracked in #64.

Before any public beta claim, the evidence pack must be filled on the 8GB
low/core path after branding, loading, onboarding, first-10-minute journey, and
storage-location visibility changes.

---

> ⚠️ **macOS Users — `bash install.sh` is still the supported path**
>
> `docker compose up` is now safe on macOS because Docker Ollama is profile-gated,
> but `bash install.sh` remains the recommended command.
>
> On macOS, `install.sh` automatically:
> - Runs Ollama **natively** for Apple Metal GPU acceleration
> - Sets `OLLAMA_BASE_URL` to `host.docker.internal` for container-to-host routing
> - Disables `fail2ban` (incompatible with Docker Desktop networking)
>
> Running `docker compose up` directly skips installer steps such as secret
> rotation, optional RAM-tier model pulls, Qdrant bootstrap, and n8n workflow import.
>
> **Linux Docker-Ollama users:** run
> `docker compose --profile docker-ollama --profile linux-security up -d` or use
> `bash install.sh`.

## ⚡ Install

Laptop-safe default:

```bash
git clone https://github.com/TheYfactora12/home-ai-elite.git
cd home-ai-elite
bash install.sh
```

After the GitHub repository slug is renamed, existing clones can update their
remote with:

```bash
git remote set-url origin https://github.com/TheYfactora12/merlin-ai.git
```

Profile-aware install:

```bash
bash install.sh --profile core
bash install.sh --profile developer
bash install.sh --profile workstation
bash install.sh --profile server
bash install.sh --profile custom --profiles search,automation
```

`core` is the laptop-safe default. Optional profiles can still be started later with `wizard start search`, `wizard start automation`, `wizard start coding`, or `wizard start full`.

Non-interactive core validation path:

```bash
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true \
  bash install.sh --profile core --skip-model-pulls --non-interactive
```

Model downloads are opt-in. To allow the installer to pull the recommended tier models:

```bash
HOME_AI_PULL_RECOMMENDED_MODELS=true bash install.sh --profile core
```

**Or install directly from GitHub (no clone needed):**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh)
```

**Requirements:**
- Docker Desktop (running)
- macOS 13+ or Ubuntu 22.04+
- 8 GB RAM entry point for low/core mode (24 GB+ recommended for heavier profiles)
- 50 GB free disk

---

## 🔁 Codex Resume

> **Active session** — resume Codex to continue where we left off building this project.

```bash
codex resume 019def0f-35cd-7083-aa1a-9e14d69338bd
```

Run this from the repo root to pick up the ongoing build context (dashboard, install feedback loop, swarm monitoring, macOS stress test fixes).

---

## 🗺️ Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the scalable install plan.

Core profile:

```
You
 │
 ├──► Wizard HQ    :8888   ← Merlin product hub and readiness surface
 ├──► Open WebUI   :3000   ← Current local chat bridge
 ├──► LiteLLM      :4000   ← Local-first model gateway
 │         │
 │         └──► Ollama  :11434  ← Native local model runtime on macOS
 │
 └──► Qdrant       :6333   ← Vector memory (RAG)
```

Optional expanded profiles:

```
You
 │
 ├──► Wizard HQ    :8888   ← Merlin product hub and readiness surface
 ├──► Open WebUI   :3000   ← Current local chat bridge
 ├──► Perplexica   :3002   ← Search AI with citations (your Perplexity)
 ├──► OpenHands    :3003   ← Autonomous coding agent (your Codex)
 ├──► n8n          :5678   ← Workflow automation & AI routing
 │
 │    (all route through)
 │
 ├──► LiteLLM      :4000   ← Model router (local-first, optional cloud only with approval)
 │         │
 │         ├──► Ollama  :11434  ← Local AI brain
 │         └──► Cloud APIs      ← Optional escalation
 │
 ├──► SearXNG      :8080   ← Private web search (no tracking)
 └──► Qdrant       :6333   ← Vector memory (RAG)
```

---

## 📋 Services

| Service | Port | What It Does | Replaces |
|---------|------|--------------|----------|
| **Dashboard (Wizard HQ)** | 8888 | Primary Merlin product hub, readiness, routing, memory, security, and system status | Manual status checks |
| **Open WebUI** | 3000 | Current local chat bridge behind Wizard HQ | ChatGPT-style workspace |
| **Perplexica** | 3002 | AI-powered web search with citations | Perplexity AI |
| **OpenHands** | 3003 | Autonomous multi-file coding agent | GitHub Copilot Workspace / Codex |
| **SearXNG** | 8080 | Private metasearch engine | Google (for the AI) |
| **LiteLLM** | 4000 | Unified local-first model router; optional cloud only with approval | OpenAI-compatible API layer |
| **n8n** | 5678 | Workflow automation + AI routing | Zapier + custom logic |
| **Qdrant** | 6333 | Vector database for AI memory | Pinecone |
| **Ollama** | 11434 | Local LLM server | OpenAI API |

---

## 💻 Hardware Tiers

The installer detects RAM and recommends safe model tiers. Model pulls are optional and should be confirmed on low-memory machines.

| RAM | Tier | Recommended models | Default behavior |
|-----|------|-----------------|----------------------|
| 8-15 GB | Low | qwen2.5:7b, nomic-embed-text | Core only; avoid OpenHands, n8n, full search stack, and 14B+ models |
| 16-23 GB | Base | qwen2.5:7b, qwen2.5-coder:7b, deepseek-r1:7b | Core + optional search |
| 24-47 GB | Mid | qwen2.5:32b, qwen2.5-coder:14b, deepseek-r1:14b | Core + search + automation where practical |
| 48+ GB | High | llama3.3:70b, qwen2.5:32b, deepseek-r1:32b | Full stack available intentionally |

Pull models explicitly:

```bash
bash scripts/add-model.sh qwen2.5:7b
```

---

## 🛠️ Management Commands

```bash
bash scripts/doctor.sh              # Read-only install/profile diagnostic
bash scripts/status.sh              # Live health dashboard
bash scripts/start-core.sh          # Start laptop-safe core profile
bash scripts/start-search.sh        # Start core + search profile
bash scripts/start-automation.sh    # Start core + n8n automation profile
bash scripts/start-coding.sh        # Start core + OpenHands coding profile
bash scripts/stop.sh                # Stop all services
bash scripts/restart.sh             # Restart all services
bash scripts/update.sh              # Pull latest images + restart
bash scripts/backup.sh              # Backup all data volumes
bash backup/backup.sh               # Backup Merlin memory/config snapshot
bash backup/restore.sh --dry-run <backup.tar.gz>
bash scripts/add-model.sh qwen2.5:32b  # Pull a new model
```

Native Ollama brain control:

```bash
wizard start                        # Start core profile
wizard start search                 # Start core + search profile
wizard start automation             # Start core + n8n profile
wizard start coding                 # Start core + OpenHands profile
wizard brain status                 # Show API, loaded models, installed models
wizard brain stop                   # Cool down local model runners
wizard brain start                  # Start native Ollama again
wizard doctor                       # Diagnose install, Docker, Ollama, ports, and profile safety
wizard merlin ask "explain RAG"     # Ask Merlin through the local task endpoint
```

See `docs/MODEL_OPERATIONS.md` for model efficiency and cooldown notes.

---

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `.env` | API keys, passwords, model selection |
| `configs/litellm/config.yaml` | Model routing rules (optional cloud providers stay disabled unless explicitly enabled) |
| `configs/searxng/settings.yml` | Search engines, privacy settings |
| `configs/perplexica/config.toml` | Perplexica model + endpoint config |

### n8n Local HTTP vs HTTPS

For local browser access at `http://localhost:5678`, keep:

```bash
N8N_SECURE_COOKIE=false
```

If you expose n8n only through HTTPS, switch it back on:

```bash
N8N_SECURE_COOKIE=true
docker compose restart n8n
```

Do not expose n8n over LAN or internet with `N8N_SECURE_COOKIE=false`.

---

## 🔑 Optional: Cloud Escalation

The stack runs locally out of the box. Optional cloud providers are off by default and must be explicitly enabled and approved. To add optional cloud routing for hard tasks:

1. Edit `.env` — add `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.
2. Edit `configs/litellm/config.yaml` — uncomment cloud model entries
3. `docker compose restart litellm`

---

## 📦 After Install

Core:

1. `bash scripts/doctor.sh` → verify Docker, Ollama, ports, models, `.env`, and service health.
2. `bash tests/core-live-smoke.sh` → verify the running core path end to end.
3. `bash tests/core-install-budget-smoke.sh` → re-run the core installer path and enforce the documented time budget.
4. **http://localhost:8888** → Wizard HQ → review Merlin status, privacy, brains, memory, agents, and settings.
5. **http://localhost:3000** → Open WebUI → current local chat bridge until native Merlin Chat moves into Wizard HQ.
6. `bash scripts/add-model.sh qwen2.5:7b` → pull a small local model if none is installed.

The current core install budget is 10 minutes for `--profile core --skip-model-pulls --non-interactive` on a machine with Docker Desktop already installed and running.

Optional profiles:

- `wizard start search` → enables Perplexica `:3002` and SearXNG `:8080`.
- `wizard start automation` → enables n8n `:5678`.
- `wizard start coding` → enables OpenHands `:3003`; avoid this on 8 GB machines.

Package signing:

- Local/trusted testing can use a self-signed package identity named `Home AI Elite Local Signing` until the signing identity is renamed.
- Build unsigned with `bash pkg/build-pkg.sh`, then sign with `bash scripts/sign-pkg.sh --version <version>`.
- The package builder signs both the component package and final distribution package when signing is enabled.
- macOS privileged installs do not trust a current-user self-signed installer certificate by default. Self-signed `.pkg` testing needs System keychain trust, `installer -allowUntrusted` in controlled local tests, or a future Developer ID Installer/notarized release path.
- Apple Developer ID notarization is a future public distribution gate, not required for the local script-based v1.0 path.

---

## 📍 Roadmap

- [x] v0.1 — Core scaffold exists and the laptop-safe core path is verified
- [~] v0.2 — Full stack prototype exists, but optional profiles still need separate validation
- [~] v0.3 — First-boot automation is partial; n8n import still depends on API key setup
- [~] v0.4 — macOS unsigned `.pkg`, live Qdrant backup/restore, core upgrade, launchd, clean reinstall, and package signing mechanics are validated; public trust remains separate
- [ ] v1.0 — Stable laptop-first release with profiles, doctor checks, tests, backup/restore, upgrade path, and guarded uninstall

---

## 📄 License

MIT — see [LICENSE](LICENSE)
