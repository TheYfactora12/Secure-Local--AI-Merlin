# Dashboard Product Spec — Merlin Command Center

Last updated: 2026-05-06

## Product Goal

The dashboard is the user-facing command center for Home AI Elite. It should make Merlin feel like a private, local-first AI assistant with the polish of a modern chat product and the control surface of a secure workstation.

Open WebUI can remain available as a proven chat UI, but the Home AI Elite dashboard should become the Merlin-native experience: chat, Magic Mode planning, memory review, model status, approvals, and local system health in one place.

## User Promise

- "I can talk to Merlin like a strong ChatGPT-style assistant."
- "I can see exactly what model, route, and staff mode Merlin chose."
- "I know whether anything is leaving my machine."
- "I can review what Merlin remembers and delete it."
- "Magic Mode plans before acting, and risky actions wait for me."
- "On an 8 GB Mac, Merlin warns me before trying heavy work."

## MVP Scope

MVP dashboard is read-mostly and conversation-first:

- Merlin Chat connected to the local task API on port 8766.
- Status panels from port 8765 and `/status/*` panels from port 8766.
- Active route, staff mode, selected model, fallback state, and approval state.
- Local-only/cloud-disabled indicator.
- Hardware tier and low-memory warnings.
- Memory collection health and approved memory status.
- Magic Mode plan-only view.
- Security/approval gate summary.

## Out Of Scope For MVP

- Autonomous execution.
- Browser or shell control.
- Dashboard-driven package installs.
- Automatic cloud routing.
- Automatic model downloads.
- Enterprise RBAC.
- Multi-user administration.
- Editing secrets or showing key values.

## Data Sources

| Need | Source | Notes |
|---|---|---|
| Legacy read-only health | `http://localhost:8765/status` | Security contract: read-only only |
| Task route/status panels | `http://localhost:8766/status/*` | Execution-aware FastAPI app |
| Chat/task response | `POST http://localhost:8766/task` | Approval gates return 403 |
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
- User can start a Merlin chat from the first screen.
- User can see local-only/cloud disabled without opening settings.
- User can tell whether the system is healthy, degraded, or blocked.
- User can preview Magic Mode without any action executing.
- UI works on 8 GB Macs without encouraging heavy profiles.
