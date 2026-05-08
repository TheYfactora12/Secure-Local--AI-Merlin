# Canonical Project State

Last verified: 2026-05-08

This document is the tie-breaker when roadmap notes, phase prompts, patent notes,
or older architecture docs disagree. Start from GitHub issue and milestone state,
then reconcile Markdown docs to that verified state.

## Source Of Truth Order

1. GitHub milestones and issues.
2. Recent commits and GitHub Actions results.
3. `docs/MASTER_CONTEXT.md`, `docs/MASTER_PROMPT.md`, and
   `CODEX_MASTER_PROMPT.md`.
4. `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`.
5. Topic docs under `docs/architecture/`, `docs/security/`, `docs/product/`,
   `docs/engineering/`, and `docs/ip/`.
6. Archived point-in-time docs under `docs/archive/`.

If a lower source conflicts with a higher source, update the lower source or
open a GitHub issue. Do not follow stale phase prompts.

## Current Product Reality

Home AI Elite has a working local-first foundation:

- protected installer and uninstall/upgrade paths,
- local Ollama, LiteLLM, Open WebUI, Qdrant, optional n8n, and Merlin APIs,
- Merlin Staff Core with config validation, policy gates, routing, memory,
  persona injection, task endpoint, and status panels,
- Phase 3 review-first learning loops,
- local JSONL observability baseline plus optional self-hosted Langfuse profile,
- Wizard HQ Merlin-native tab shell with Chat, Brains, Memory, Agents,
  Security, System, and Settings information architecture.

It is not yet the final commercial Home AI Elite product. The remaining product
gaps are first-run API persistence, dashboard command-center polish, visual
Wizard HQ validation, supervised Magic Mode UX, public packaging evidence, and a
future native automation runtime that supplements or replaces n8n after workflow
patterns are proven. Developer ID signing/notarization remains tracked by #64
but is deferred until the product surface is more complete.

## Current Architecture Diagram

This is current-state as of 2026-05-08.

```mermaid
flowchart LR
    User[User] --> Wizard[wizard CLI]
    User --> WebUI[Open WebUI :3000]
    User --> Dashboard[Dashboard :8888]

    Wizard --> Installer[Protected installer and scripts]
    Wizard --> MerlinTask[Merlin Task API :8766]
    Dashboard --> StatusAPI[Read-only Status API :8765]

    WebUI --> LiteLLM[LiteLLM :4000]
    MerlinTask --> Router[Merlin router and policy gates]
    Router --> LiteLLM
    Router --> Memory[Memory Manager]

    LiteLLM --> Ollama[Native Ollama :11434]
    Memory --> Qdrant[Qdrant :6333]

    Wizard --> N8N[n8n optional adapter :5678]
    N8N --> Qdrant
    N8N --> LocalLangfuse[Local Langfuse optional :3010]

    Router --> Audit[Local JSONL audit and traces]
    Wizard --> Audit

    classDef optional fill:#fff8dc,stroke:#c99c00,color:#111;
    class N8N,LocalLangfuse optional;
```

## Milestone Snapshot

| Milestone | State | Notes |
| --- | --- | --- |
| `v1.0 — Stable Installer Release` | Closed | Low/core 8GB Mac validation complete; Developer ID signing deferred to #64. |
| `v1.1 — Mobile Access + Remote-Safe Entry Points` | Closed | Design-only, opt-in LAN/mobile access; no default exposure. |
| `v1.2 — Hardware Guide + Document Ingestion Planning` | Closed | 8GB-first guidance and planning-only ingestion scope. |
| `v1.3 — Reliability + Memory + Router` | Closed | n8n retry contracts and local-first ModelRouter starter complete. |
| `v1.5 — Memory Benchmarking` | Closed | Offline deterministic benchmark harness complete. |
| `v1.6 — Pi Intelligence + Observability` | Complete after #8 closure | JSONL baseline, optional local Langfuse profile/export, n8n trace emission, memory/benchmark metadata export, and Qdrant task-signature retrieval are complete. |
| `v1.7 — Security Hardening` | Closed | #80 added the explicit fail-closed `webhook_execution` gate without changing webhook defaults. |
| `v2.0 — Merlin Staff Core` | Mostly complete, memory follow-ups open | Phase 2 runtime complete; stale roadmap/queue/governance issues were closed on 2026-05-08. Remaining work is explicit user-facing memory approval and memory review/delete. |
| `v2.1 — Dashboard Command Center` | Closed | Read-only Wizard HQ command center and security approvals panel complete. |
| `v2.2 — Magic Mode` | Closed | Plan-only Magic Mode and local redacted audit viewer complete. |
| `v3.0 — Public Product Release` | Active | Public packaging, onboarding, signing/notarization, installer branding, and release readiness. |
| `v3.x — Native Automation Runtime` | Future | Last-mile commercial runtime to supplement or replace n8n after core workflows prove the owned shape. |

## Active Execution Queue

1. #102: clarify Wizard HQ status API first-run persistence after clean install.
2. #101: continue Wizard HQ Merlin-native front door and Brains tab UX,
   including browser visual validation and screenshot evidence.
3. #37 and #95: public onboarding hardening and product audit evidence
   collection under v3.0.
4. #64: Developer ID signing/notarization under v3.0, deferred until the
   installer, Wizard HQ, and release evidence are otherwise product-complete.
5. #92: Native Automation Runtime in v3.x after release readiness work and
   control-plane product milestones.

Patent/IP issues #81 through #84 are cross-cutting governance work. They should
not add novel claim language to public docs unless the inventor explicitly
approves the disclosure and the relevant evidence exists in code.

## Canonical Docs

| Doc | Owner | Purpose |
| --- | --- | --- |
| `docs/CANONICAL_PROJECT_STATE.md` | Scrum master / governance | Current GitHub-aligned state, queue, and doc hierarchy. |
| `docs/MASTER_CONTEXT.md` | Session bootstrap | Full operational context and current milestone position. |
| `docs/MASTER_PROMPT.md` | Session bootstrap | Agent behavior rules and current next recommendation. |
| `CODEX_MASTER_PROMPT.md` | Root repo operating contract | High-level security, engineering, and patent-sensitive rules. Treat embedded backlog lists as subordinate to GitHub truth and this doc. |
| `docs/MERLIN_IMPLEMENTATION_ROADMAP.md` | Roadmap | Milestone ladder, issue alignment, and long-range execution plan. |
| `docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md` | Product strategy | Validated control-plane direction, current/future boundary, and v3.1-v4.x milestone ladder. |
| `docs/observability-guide.md` | v1.6 feature owner | JSONL baseline, optional local Langfuse, trace export, and related tests. |
| `docs/architecture/MERLIN_STAFF_CORE.md` | Merlin core owner | Staff router, swarm context, policy gates, team modes, and Phase 2 boundary. |
| `docs/architecture/AUTOMATION_RUNTIME_STRATEGY.md` | Product/architecture | Why n8n remains optional today and how a native runtime becomes a v3.x milestone. |
| `docs/security/SECURITY_MODEL.md` | Security reviewer | Local-first security model and observability privacy boundary. |
| `docs/ip/INVENTOR_RECORD.md` | Inventor/IP record | Implemented patent evidence and future design targets. |

## Historical And Reference Docs

- `docs/archive/**` files are point-in-time evidence. Do not update them except
  to correct factual mistakes with a dated note.
- `docs/product/**` files describe product direction and UX. They are subordinate
  to GitHub issue state when implementation status changes.
- `docs/MERLIN_PHASE3_LEARNING_PLAN.md` is the Phase 3 design record. Phase 3A
  through 3E are complete; do not use this file to restart completed work.
- `docs/ip/PATENT_CLAIM_4_RETRIEVAL_FEEDBACK_ROUTING.md` is evidence-aligned:
  JSONL retrieval and Qdrant task-signature vector retrieval are implemented;
  JSONL remains the fallback when Qdrant is unavailable.

## Diagram Rule

Architecture diagrams must be either:

- current-state diagrams that match code and GitHub issue status, or
- explicitly labeled future-state diagrams with the owning issue or milestone.

When a milestone closes, update the relevant current-state diagram or add a
dated note explaining why no diagram changed.

## Drift Handling Rule

Follow milestones in order. If related drift is found while working the active
issue, fix it in the same small slice when it is safe and testable. If the drift
belongs to another milestone, create or update an issue with evidence and return
to the active queue.
