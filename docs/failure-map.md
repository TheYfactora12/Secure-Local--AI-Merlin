# Wizard AI — Self-Hosted AI Failure Map & Gap Targets
**Research Date:** May 2, 2026 | **Owner:** TheYfactora12 | Oxford, MA
**Purpose:** Map 20 documented failure patterns across real self-hosted AI projects so Wizard avoids each one.

---

## Executive Summary

Gartner predicts 60% of AI projects will be abandoned through 2026. MIT research puts generative AI pilot failure at 95%. Among self-hosted home AI projects specifically, the failure rate is even higher — most never survive first real-world use beyond the builder. These aren't model quality failures. They are engineering, architecture, and UX failures. Every pattern below is sourced from documented community failures, GitHub issues, and production postmortems.

---

## Failure Category Map

### Category A — Infrastructure & Connectivity (Failures 1–5)

#### Failure 1: Ollama ↔ Open WebUI Hostname Death Spiral
Ollama listens on `127.0.0.1` by default. Docker containers can't reach localhost — need `host.docker.internal` or `OLLAMA_HOST=0.0.0.0`. Most stacks ship wrong defaults. Users see "Failed to fetch models", give up.
**Wizard fix:** `install.sh` sets `OLLAMA_HOST=0.0.0.0`. `wizard doctor` validates every hostname/port at preflight.

#### Failure 2: n8n + Ollama "Context Canceled" Crash
n8n Ollama node cancels mid-stream on longer outputs → HTTP 500 "context canceled" → Structured Output Parser throws format error. Production workflows silently fail.
**Wizard fix:** v1.3 — retry logic on all n8n Ollama nodes, `wizard test-workflows` CLI command.

#### Failure 3: n8n v2.0 Workflow Crashes & Rollback Horror
n8n 2.0 broke AI Agent workflows. A critical bug silently rolled back all self-hosted workflows to a 2-week-old state with no warning — wiping weeks of development.
**Wizard fix:** `scripts/upgrade.sh` pins n8n to tested version. Backup runs before every upgrade.

#### Failure 4: Docker Port Conflicts (Silent)
Home AI stacks hit conflicts with existing homelab services on common ports. Services start but don't respond. No preflight check catches this.
**Wizard fix:** `wizard doctor` checks all 8 Wizard ports for conflicts before compose up.

#### Failure 5: TLS/SSL Internal Service Breakage
Self-signed TLS breaks internal service-to-service communication. Stack runs but services can't talk.
**Wizard fix:** Internal Docker network uses HTTP only. TLS terminates at Nginx edge. v0.7.

---

### Category B — Memory & Data Architecture (Failures 6–10)

#### Failure 6: RAG Memory Stores Too Much, Retrieves Wrong Context
500 agent memory experiments (Apr 2026): memories too vague to change behavior. "Embed everything" produces noise. Retrieval scores improve but answer quality doesn't.
**Wizard fix:** v1.3 — structured Qdrant memory schema: what gets stored, when it expires, what triggers update. `wizard memory clean` CLI.

#### Failure 7: No Cross-Session Identity ("Amnesia AI")
Every new chat starts cold. Cloud tools remember context across sessions. Local stacks require explicit engineering most projects never implement.
**Wizard fix:** v1.3 — `n8n-workflows/06-session-memory-bridge.json` auto-injects top-5 relevant memories into every new Open WebUI session.

#### Failure 8: Vector DB Memory Drift (Stale Context Poisoning)
Qdrant accumulates stale embeddings. Old roles, outdated prefs, previous errors all still score high. Model retrieves them with fresh context → plausible-but-wrong answers.
**Wizard fix:** v1.3 daily pruning. `wizard memory clean` CLI command.

#### Failure 9: Qdrant Distributed Mode Performance Collapse
Projects cargo-cult enterprise Qdrant configs. Distributed mode adds severe overhead. Single-node with adequate RAM outperforms for single-machine use.
**Wizard fix:** Single-node Qdrant by design. No distributed mode.

#### Failure 10: No Document Ingestion Pipeline
Users want to ingest PDFs, Word docs, web content. Most stacks have no document processor.
**Wizard fix:** v1.2 — Docling/Unstructured in compose optional profile. `wizard ingest <file>` CLI.

---

### Category C — Model Quality & Routing (Failures 11–14)

#### Failure 11: Wrong Model for Task (The 7B Perception Gap)
Users pull `llama3:7b`, use it for everything, compare to GPT-4o, conclude local AI is inferior, quit.
**Wizard fix:** v1.3 — `install.sh` RAM-aware tier auto-selects `qwen2.5:32b` on Tier 2+ hardware.

#### Failure 12: No Task-Based Model Routing
One model handles all task types — mediocre at all of them.
**Wizard fix:** LiteLLM config + n8n smart router. Already in v0.2/v0.9.

#### Failure 13: Sensitive Data Leaks to Cloud APIs
Stacks with cloud fallback keys send sensitive queries to OpenAI/Anthropic with no routing enforcement.
**Wizard fix:** SENSITIVE class hardcoded to local-only. Not configurable. v0.9.

#### Failure 14: Web Search Returns Links, Not Answers
SearXNG returns raw results. No synthesis layer. Experience feels like worse Google.
**Wizard fix:** Perplexica synthesis layer + v1.3 cross-encoder reranker + source freshness filter.

---

### Category D — UX, Complexity & Abandonment (Failures 15–18)

#### Failure 15: Setup Takes Hours, Users Quit Before First Chat
The #1 abandonment trigger. Port conflicts, wrong hostnames, missing env vars, compose errors — no diagnostic tool. Users debug Docker for hours instead of chatting.
**Wizard fix:** `wizard doctor` preflight diagnostic. install.sh health checks + startup dashboard.

#### Failure 16: No Dashboard — "Is It Running?" Is Unanswerable
Projects expose 6–8 services with no unified status view.
**Wizard fix:** `dashboard/index.html` — Wizard HQ. v0.8.

#### Failure 17: Stack Goes Stale — Models & Services Never Update
Users run 6-month-old models. New models (qwen2.5, deepseek-r1) are materially better but never pulled.
**Wizard fix:** `scripts/upgrade.sh` + `wizard upgrade` extends to pull latest models from `models.json`.

#### Failure 18: No Mobile/Remote Access
Powerful local AI stack can't be accessed from phone or other machines. Becomes a desktop toy.
**Wizard fix:** v1.1 — iOS shortcut → n8n webhook → Wizard brain. Nginx proxy already in v0.7.

---

### Category E — Governance & Sustainability (Failures 19–20)

#### Failure 19: No Roadmap → Feature Creep Kills the Core
60–95% of AI projects lose their defined objective. Home AI projects get sidetracked. The core never finishes.
**Wizard fix:** `ROADMAP.md` is single source of truth. Nothing enters sprint without a roadmap entry.

#### Failure 20: No Backup → One Volume Wipe Destroys Everything
A `docker volume prune` or botched upgrade wipes months of Qdrant memories and n8n workflows permanently.
**Wizard fix:** `backup/backup.sh` + daily launchd timer + backup-before-upgrade in `scripts/upgrade.sh`.

---

## Competitive Gap Table

| # | Failure Pattern | Category | Wizard Fix Status | Roadmap |
|---|---|---|---|---|
| 1 | Ollama ↔ WebUI hostname mismatch | Infrastructure | ✅ install.sh | v1.3 `wizard doctor` |
| 2 | n8n + Ollama context canceled | Infrastructure | ⚠️ Partial | v1.3 Gap 2 |
| 3 | n8n v2.0 workflow rollback | Infrastructure | ✅ version pin + backup | v0.4 |
| 4 | Docker port conflicts | Infrastructure | ⚠️ Partial | v1.3 `wizard doctor` |
| 5 | TLS internal service breakage | Infrastructure | ✅ Nginx edge design | v0.7 |
| 6 | RAG memory too vague | Memory | ⚠️ Partial | v1.3 Gap 1 |
| 7 | No cross-session identity | Memory | ⚠️ Partial | v1.3 Gap 3 |
| 8 | Stale context poisoning | Memory | ⚠️ Partial | v1.3 pruning |
| 9 | Qdrant distributed collapse | Memory | ✅ single-node design | v0.3 |
| 10 | No document ingestion | Memory | 🔲 Not yet | v1.2 Docling |
| 11 | Wrong model / 7B trap | Model Quality | ⚠️ Partial | v1.3 Gap 6 |
| 12 | No task routing | Model Quality | ✅ LiteLLM + n8n router | v0.2/v0.9 |
| 13 | Sensitive data leaks to cloud | Model Quality | ✅ hardcoded SENSITIVE routing | v0.9 |
| 14 | Web search = raw links only | Model Quality | ✅ Perplexica synthesis | v0.2 |
| 15 | Setup complexity → abandonment | UX | ⚠️ Partial | v1.3 `wizard doctor` |
| 16 | No health dashboard | UX | ✅ Wizard HQ | v0.8 |
| 17 | Stack goes stale | UX | ✅ upgrade.sh | v0.4/v1.3 |
| 18 | No mobile access | UX | 🔲 Planned | v1.1 |
| 19 | No roadmap → feature creep | Governance | ✅ ROADMAP.md rule | All versions |
| 20 | No backup → data loss | Governance | ✅ backup.sh + launchd | v0.7/v0.8 |

**Legend:** ✅ Fixed | ⚠️ Partial (roadmap item exists) | 🔲 Not yet built

---

## Priority Build Order (by failure frequency + abandonment impact)

1. **`wizard doctor` / `scripts/doctor.sh`** — Closes Failures 1, 4, 15. Highest ROI single item.
2. **n8n Ollama retry logic** — Closes Failure 2. Prevents silent production failures.
3. **Structured Qdrant memory schema** — Closes Failures 6, 7, 8. Makes AI feel smart across sessions.
4. **Docling document ingestion** — Closes Failure 10. Unlocks "my AI knows my documents" use case.
5. **`install.sh` model tier auto-selection** — Closes Failure 11. Prevents 7B perception gap trap.
6. **Mobile access** — Closes Failure 18. Moves AI from desktop toy to personal assistant.

---

*Rule: Any new failure pattern discovered gets added here AND to ROADMAP.md before code is written.*
*Maintained by: TheYfactora12 | Oxford, MA | home-ai-elite*
