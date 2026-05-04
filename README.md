# 🧠 Home AI Elite

> **Your own Perplexity + Codex running on hardware you own. Zero subscriptions.**

A one-shot installer that sets up a complete local AI stack — private web search, conversational AI, autonomous coding agent, vector memory, and workflow automation — in a single command.

[![Version](https://img.shields.io/badge/version-0.2-blue)]
[![License](https://img.shields.io/badge/license-MIT-green)]

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
> rotation, RAM-tier model pulls, Qdrant bootstrap, and n8n workflow import.
>
> **Linux Docker-Ollama users:** run
> `docker compose --profile docker-ollama --profile linux-security up -d` or use
> `bash install.sh`.

## ⚡ Install

```bash
git clone https://github.com/TheYfactora12/home-ai-elite.git
cd home-ai-elite
bash install.sh
```

**Or install directly from GitHub (no clone needed):**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh)
```

**Requirements:**
- Docker Desktop (running)
- macOS 13+ or Ubuntu 22.04+
- 8 GB RAM minimum (24 GB recommended)
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

```
You
 │
 ├──► Dashboard    :8888   ← Wizard HQ service dashboard
 ├──► Open WebUI   :3000   ← Chat UI (your ChatGPT / Perplexity)
 ├──► Perplexica   :3002   ← Search AI with citations (your Perplexity)
 ├──► OpenHands    :3003   ← Autonomous coding agent (your Codex)
 ├──► n8n          :5678   ← Workflow automation & AI routing
 │
 │    (all route through)
 │
 ├──► LiteLLM      :4000   ← Model router (local-first, cloud fallback)
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
| **Dashboard (Wizard HQ)** | 8888 | Unified local stack dashboard | Manual status checks |
| **Open WebUI** | 3000 | Chat, RAG, voice, web search UI | ChatGPT, Perplexity UI |
| **Perplexica** | 3002 | AI-powered web search with citations | Perplexity AI |
| **OpenHands** | 3003 | Autonomous multi-file coding agent | GitHub Copilot Workspace / Codex |
| **SearXNG** | 8080 | Private metasearch engine | Google (for the AI) |
| **LiteLLM** | 4000 | Unified model router — local + cloud | OpenAI API layer |
| **n8n** | 5678 | Workflow automation + AI routing | Zapier + custom logic |
| **Qdrant** | 6333 | Vector database for AI memory | Pinecone |
| **Ollama** | 11434 | Local LLM server | OpenAI API |

---

## 💻 Hardware Tiers

The installer detects your RAM and pulls the right models automatically.

| RAM | Tier | Models Installed | Recommended Hardware |
|-----|------|-----------------|----------------------|
| 8–15 GB | Low | mistral:7b, qwen2.5:7b | Any Mac/PC |
| 16–23 GB | Base | qwen2.5:7b, qwen2.5-coder:7b, deepseek-r1:7b | Mac Mini M2/M3 16GB |
| 24–47 GB | Mid ⭐ | qwen2.5:32b, qwen2.5-coder:14b, deepseek-r1:14b | Mac Mini M4 Pro 24GB |
| 48+ GB | High | llama3.3:70b, qwen2.5:32b, deepseek-r1:32b | Mac Studio / Mac Pro |

**Best value:** Mac Mini M4 Pro 24 GB (~$1,399) — silent, 10W idle, runs 32B models at full speed.

---

## 🛠️ Management Commands

```bash
bash scripts/status.sh              # Live health dashboard
bash scripts/stop.sh                # Stop all services
bash scripts/restart.sh             # Restart all services
bash scripts/update.sh              # Pull latest images + restart
bash scripts/backup.sh              # Backup all data volumes
bash scripts/add-model.sh qwen2.5:32b  # Pull a new model
```

Native Ollama brain control:

```bash
wizard brain status                 # Show API, loaded models, installed models
wizard brain stop                   # Cool down local model runners
wizard brain start                  # Start native Ollama again
```

See `docs/MODEL_OPERATIONS.md` for model efficiency and cooldown notes.

---

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `.env` | API keys, passwords, model selection |
| `configs/litellm/config.yaml` | Model routing rules (add cloud fallback here) |
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

The stack runs 100% locally out of the box. To add cloud fallback for hard tasks:

1. Edit `.env` — add `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.
2. Edit `configs/litellm/config.yaml` — uncomment cloud model entries
3. `docker compose restart litellm`

---

## 📦 After Install

1. **http://localhost:3000** → Open WebUI → create admin account → start chatting
2. **http://localhost:3002** → Perplexica → try a web search with citations
3. **http://localhost:3003** → OpenHands → give it a coding task (point at a GitHub repo)
4. **http://localhost:5678** → n8n → import `n8n-workflows/ai-router.json`
5. **`bash scripts/add-model.sh`** → pull more models anytime

---

## 📍 Roadmap

- [x] v0.1 — Core scaffold: Ollama, Open WebUI, n8n, Qdrant
- [x] v0.2 — Full stack: Perplexica, SearXNG, LiteLLM, OpenHands, RAM-aware installer
- [ ] v0.3 — Qdrant collection init, n8n workflow auto-import, launchd auto-start agents
- [ ] v0.4 — macOS `.pkg` signed installer, preflight backup/restore
- [ ] v1.0 — Stable release, automated tests, upgrade path

---

## 📄 License

MIT — see [LICENSE](LICENSE)
