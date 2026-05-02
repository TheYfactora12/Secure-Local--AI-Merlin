# Model Manager UI — home-ai-elite v0.8

A local web dashboard for managing your Ollama models.
Connects directly to your local Ollama instance — no cloud, no telemetry.

---

## How to open

```bash
# Option 1 — open directly in browser
open ~/home-ai-elite/model-ui/index.html

# Option 2 — serve via Python (avoids browser CORS restrictions for API calls)
cd ~/home-ai-elite/model-ui && python3 -m http.server 8181
# Then open: http://localhost:8181

# Option 3 — it will be added as a route in Nginx in v0.9
```

> ⚠️  **CORS note:** Browsers block direct `fetch()` calls from `file://` URLs to `localhost:11434`.
> Use Option 2 (Python server) or serve through Nginx for full functionality.

---

## Pages

| Page | What it does |
|---|---|
| **Dashboard** | Model count, disk used, RAM tier, Ollama status at a glance |
| **My Models** | Full list of installed models with size, family, usage count, and delete button |
| **Pull Model** | Pull any model by name with live progress bar; suggested models by use case |
| **RAM Tiers** | Switch between 8GB / 16GB / 32GB / 64GB+ profiles |
| **Usage Stats** | Per-model call counts and latency (session-based) |
| **Scheduler** | Bandwidth-aware pull controls — block large downloads during work hours |

---

## RAM Tier Profiles

| Tier | RAM | Chat Model | Coder Model |
|---|---|---|---|
| Efficient | 8 GB | mistral:7b | qwen2.5-coder:3b |
| Balanced | 16 GB | qwen2.5:7b | qwen2.5-coder:7b |
| Performance | 32 GB | qwen2.5:32b | qwen2.5-coder:14b |
| Elite | 64 GB+ | qwen2.5:72b | qwen2.5-coder:32b |

Switching a tier shows the recommended models. Applying it outputs the `.env` values to update.

---

## Connecting to Ollama

The UI connects to `http://localhost:11434` by default.
Make sure Ollama is running:

```bash
ollama serve
# or
docker compose up -d ollama
```

---

## v0.9 planned upgrades
- Served via Nginx at `/model-ui/` route (no manual Python server)
- LiteLLM usage metrics piped into Usage Stats
- Persistent stats stored in Qdrant
- Model comparison view (benchmark scores side-by-side)
