# Dashboard Product Spec — Merlin Command Center

Last updated: 2026-05-07

## Product Goal

The dashboard is the user-facing command center for Home AI Elite. It should make Merlin feel like a private, local-first AI assistant with the polish of a modern chat product and the control surface of a secure workstation.

The v2.1 product name for this surface is **Wizard HQ**. The brand direction is
tracked in `docs/product/MERLIN_BRAND_UX_SPEC.md`, with the current concept image
at `docs/product/assets/wizard-hq-concept.png`.

Open WebUI can remain available as a proven chat UI, but the Home AI Elite dashboard should become the Merlin-native experience: chat, Magic Mode planning, memory review, model status, approvals, and local system health in one place.

## User Promise

- "I can talk to Merlin like a strong ChatGPT-style assistant."
- "I can see exactly what model, route, and staff mode Merlin chose."
- "I know whether anything is leaving my machine."
- "I can review what Merlin remembers and delete it."
- "Magic Mode plans before acting, and risky actions wait for me."
- "On an 8 GB Mac, Merlin warns me before trying heavy work."

## MVP Scope

MVP dashboard is read-only and command-center-first while the task execution
surface remains approval-gated behind Merlin APIs:

- Startup Readiness surface that computes ready/degraded/fix-needed states from
  live localhost GET checks instead of hardcoded success.
- Status panels from port 8765 and `/status/*` panels from port 8766.
- Active route, staff mode, selected model, fallback state, and approval state.
- Local-only/cloud-disabled indicator.
- Hardware tier and low-memory warnings.
- Memory collection health and approved memory status.
- Brain Status, Memory Vault, Agent Control, Sovereignty Status, Knowledge Graph
  placeholder, and System Doctor panels.
- Security/approval gate summary.

## Out Of Scope For MVP

- Autonomous execution.
- Browser chat submission or task execution from the static dashboard.
- Browser or shell control.
- Dashboard-driven package installs.
- Automatic cloud routing.
- Automatic model downloads.
- Enterprise RBAC.
- Multi-user administration.
- Editing secrets or showing key values.
- Static "ready" language that is not backed by live status checks.

## Data Sources

| Need | Source | Notes |
|---|---|---|
| Legacy read-only health | `http://localhost:8765/status` | Security contract: read-only only |
| Task route/status panels | `http://localhost:8766/status/*` | Execution-aware FastAPI app |
| Future chat/task response | `POST http://localhost:8766/task` | Not used by read-only v2.1 launch dashboard |
| Open WebUI | `http://localhost:3000` | External chat UI remains linked |
| Ollama model list | `http://localhost:11434/api/tags` | Localhost only |
| Qdrant health | `http://localhost:6333/healthz` | Local memory |

## Product Risks

- Dashboard becomes a second execution surface before policy gates are ready.
- Users confuse plan-only Magic Mode with autonomous execution.
- UI hides local-only/cloud state too deeply.
- 8 GB users see options their machine cannot safely run.
- The static dashboard drifts from Python router/task API truth.

## Guardrails

- Dashboard v1 may display and request; it must not perform privileged actions directly.
- Every risky action must route through policy gates and audit logging.
- Secrets are presence-only.
- Raw user input is not stored in dashboard logs.
- The 8765 status server remains read-only and separate from 8766.

## Success Criteria

- User can open `http://localhost:8888` and understand what Merlin can do right now.
- User can see the Wizard HQ command center and understand what Merlin can do right now.
- User can see local-only/cloud disabled without opening settings.
- User can tell whether the system is healthy, degraded, or blocked.
- User never sees local model or system readiness marked ready unless the
  underlying localhost status checks pass.
- User can preview Magic Mode without any action executing.
- UI works on 8 GB Macs without encouraging heavy profiles.
