# 🐝 Swarm Coordinator — Architecture Reference

> Ruflo-pattern multi-agent orchestration, 100% local on Ollama.
> No cloud dependency. No API costs. Full privacy.

---

## What This Is

Phase 1 of the Ruflo-inspired swarm integration. Instead of running one AI
agent at a time, the Swarm Coordinator receives a task, classifies its
complexity and intent, routes it to the best specialist agent, and writes
the result to shared Qdrant memory so future agents benefit from it.

Inspired by: [Ruflo by Reuven Cohen](https://github.com/ruvnet/ruflo) —
the open-source Claude Code multi-agent orchestrator.
Key difference: **Wizard AI runs entirely on your hardware with Ollama.**

---

## Architecture

```
                    ┌─────────────────────────────────────┐
                    │        USER / WIZARD CLI             │
                    │  POST http://localhost:5678/         │
                    │       webhook/swarm                  │
                    │  { "task": "your request here" }    │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │      n8n: SWARM COORDINATOR          │
                    │  1. Classify complexity              │
                    │     tiny / medium / heavy            │
                    │  2. Detect intent                    │
                    │     search / code / generate         │
                    │  3. Select agent + model             │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
  ┌────────▼────────┐   ┌──────────▼──────────┐  ┌────────▼────────┐
  │   PERPLEXICA    │   │     OPENHANDS        │  │    LITELLM      │
  │  :3002          │   │     :3003            │  │    :4000        │
  │  Web search +   │   │  Autonomous code     │  │  Model router   │
  │  RAG retrieval  │   │  agent (Codex)       │  │  generation     │
  └────────┬────────┘   └──────────┬──────────┘  └────────┬────────┘
           │                       │                       │
           └───────────────────────┼───────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │      NORMALIZE RESPONSE              │
                    │  Standard shape regardless of agent  │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │      QDRANT SHARED MEMORY            │
                    │  collection: swarm_memory            │
                    │  vector: nomic-embed-text (768d)     │
                    │  All agents read + write here        │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │         RESPONSE TO CALLER           │
                    │  { taskId, agent, model,             │
                    │    complexity, result,               │
                    │    timestamp }                       │
                    └─────────────────────────────────────┘
```

---

## Complexity Routing Table

| Complexity | Trigger | Agent | Model |
|---|---|---|---|
| **tiny** | < 15 words, no heavy keywords | LiteLLM | `qwen2.5:7b` |
| **medium** | 15–60 words, general task | LiteLLM | `qwen2.5:32b` |
| **heavy** | 60+ words or architecture/build keywords | OpenHands | `qwen2.5-coder:14b` |
| **search** | search/find/news/web keywords | Perplexica | SearXNG search |
| **code** | code/bug/script/deploy keywords | OpenHands | `OPENHANDS_MODEL` |

---

## How to Use

### Option 1: Direct API call
```bash
# Simple question → LiteLLM tiny tier
curl -X POST http://localhost:5678/webhook/swarm \
  -H 'Content-Type: application/json' \
  -d '{"task": "What is 2+2?"}'

# Web search
curl -X POST http://localhost:5678/webhook/swarm \
  -H 'Content-Type: application/json' \
  -d '{"task": "Search for latest AI news today"}'

# Code task → OpenHands
curl -X POST http://localhost:5678/webhook/swarm \
  -H 'Content-Type: application/json' \
  -d '{"task": "Write a Python script to monitor CPU usage and alert if over 80%"}'

# Force a specific agent
curl -X POST http://localhost:5678/webhook/swarm \
  -H 'Content-Type: application/json' \
  -d '{"task": "Explain Docker networking", "agent": "litellm"}'
```

### Option 2: wizard CLI (after Phase 1 wiring)
```bash
wizard swarm "your task here"
```

### Option 3: n8n UI
Open http://localhost:5678 → Workflows → 🐝 Swarm Coordinator → Test with input

---

## Response Shape
```json
{
  "taskId": "swarm_1746278400_abc123",
  "agent": "litellm",
  "model": "qwen2.5:32b",
  "complexity": "medium",
  "result": "The answer is...",
  "timestamp": "2026-05-03T09:06:00.000Z"
}
```

---

## Shared Memory Schema (Qdrant: `swarm_memory`)

```json
{
  "id": "swarm_1746278400_abc123",
  "vector": [768-dimensional nomic-embed-text vector],
  "payload": {
    "task": "original task text",
    "result": "agent result (max 2000 chars)",
    "agent": "litellm | perplexica | openhands",
    "model": "qwen2.5:32b",
    "complexity": "tiny | medium | heavy",
    "tags": [],
    "timestamp": "ISO 8601",
    "source": "swarm-coordinator"
  }
}
```

---

## Import to n8n

```bash
# From your home-ai-elite directory:
docker exec -it n8n n8n import:workflow \
  --input=/home/node/.n8n/workflows/swarm-coordinator.json

docker exec -it n8n n8n import:workflow \
  --input=/home/node/.n8n/workflows/swarm-memory-writer.json
```

Or manually: n8n UI → Workflows → Import from File → select each JSON.

---

## Phase Roadmap

| Phase | What | Status |
|---|---|---|
| **Phase 1** | Swarm coordinator + shared memory writes | ✅ Done |
| **Phase 2** | LiteLLM complexity routing rules (config) | 🔜 Next |
| **Phase 3** | Cross-agent memory reads (RAG context injection) | 🔜 After |

---

## Credit

Architecture inspired by [Ruflo v3.5](https://github.com/ruvnet/ruflo) by
[Reuven Cohen](https://github.com/ruvnet) — the Claude Code multi-agent
orchestrator. Wizard AI reimplements the core patterns locally on Ollama
with no cloud dependency.
