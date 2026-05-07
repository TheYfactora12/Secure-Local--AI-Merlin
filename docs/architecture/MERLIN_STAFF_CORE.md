# Merlin Staff Core

Last updated: 2026-05-06

Merlin Staff Core is the local-first runtime layer that turns a user task into a policy-aware staff decision: route, staff mode, model alias, approval gates, prompt context, and audit trail. It sits above the protected installer and wraps the existing local stack instead of replacing Ollama, LiteLLM, Open WebUI, n8n, or Qdrant.

## Phase 2E Completion Note

Issue #60 adds the final staff-router integration boundary:

- `merlin/swarm_coordinator.py` converts a resolved `RouteDecision` into immutable `SwarmContext`.
- `tests/test_router.py` covers all six staff modes, low-memory fallback, cloud approval blocking, audit write flags, default fallback, and swarm context immutability.
- `wizard mode status` shows the active staff mode, preferred/selected model, fallback state, agent target, approval requirement, confidence, and UTC resolution time.

The coordinator is intentionally pure wiring. It performs no model calls, network calls, filesystem writes, service starts, or n8n execution. Execution remains outside this boundary and must stay policy-gated.

## Staff Modes

| Staff mode | Focus | Model alias |
|---|---|---|
| `architect` | Architecture, scalability, service boundaries | `deepseek` |
| `ai_engineer` | Model routing, embeddings, RAG, evals | `qwen-coder` |
| `software_engineer` | Code, tests, CI, scripts | `qwen-coder` |
| `security_reviewer` | Secrets, permissions, risk review | `deepseek` |
| `product_designer` | Dashboard and user flows | `qwen7b` |
| `operator` | Health, upgrades, logs, hardware tiers | `mistral` |

Low-memory hardware falls back to `mistral` for heavy non-default staff models.

## Boundaries

- No cloud calls by default.
- No autonomous execution.
- No raw input in route/audit logs.
- No memory writes without approval.
- No dashboard privileged mutation in v1.
- Port `8765` remains the legacy read-only status server.
- Port `8766` remains the FastAPI task/status surface.
