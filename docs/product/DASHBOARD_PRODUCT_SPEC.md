# Dashboard Product Spec — Merlin Command Center

Last updated: 2026-05-09

## Product Goal

The dashboard is the user-facing command center for Home AI Elite. It should make Merlin feel like a private, local-first AI assistant with the polish of a modern chat product and the control surface of a secure workstation.

The v2.1 product name for this surface is **Wizard HQ**. The brand direction is
tracked in `docs/product/MERLIN_BRAND_UX_SPEC.md`, with the current concept image
at `docs/product/assets/wizard-hq-concept.png`.

Open WebUI can remain available as a proven chat UI, but the Home AI Elite dashboard should become the Merlin-native experience: chat, Magic Mode planning, memory review, model status, approvals, and local system health in one place.

The v3.1 product correction is that Merlin must become the chat and context
surface itself. Open WebUI, Qwen/Ollama, LiteLLM, and optional APIs are engines
or connectors underneath Merlin, not the experience the user should feel they
are using.

## User Promise

- "I can talk to Merlin like a strong ChatGPT-style assistant."
- "My chat history is saved locally into Rooms I control."
- "I can choose which Room Merlin may reference."
- "I can see exactly what model, route, and staff mode Merlin chose."
- "I know whether anything is leaving my machine."
- "I can review what Merlin remembers and delete it."
- "Magic Mode plans before acting, and risky actions wait for me."
- "On an 8 GB Mac, Merlin warns me before trying heavy work."

## MVP Scope

MVP dashboard is command-center-first. Status surfaces remain read-only, while
native chat is allowed to submit exactly one policy-gated request path through
Merlin Task API `/task`:

- Startup Readiness surface that computes ready/degraded/fix-needed states from
  live localhost GET checks instead of hardcoded success.
- Status panels from port 8765 and `/status/*` panels from port 8766.
- Merlin Chat surface with active route, staff mode, selected model, fallback
  state, response state, and approval state.
- Rooms design surface: active Room, storage location, reference policy, and
  save-to-Room status. Runtime file/index work is tracked by #135 and must not
  be implied until implemented.
- Local-only/cloud-disabled indicator.
- Hardware tier and low-memory warnings.
- Memory collection health and approved memory status.
- Brain Status, Memory Vault, Agent Control, Sovereignty Status, Knowledge Graph
  placeholder, and System Doctor panels.
- Security/approval gate summary.

## v3.0 Front-Door Direction

Wizard HQ should become the default Merlin AI product surface, not a companion
page beside Open WebUI. Open WebUI, Qwen, other Ollama models, LiteLLM routes,
and optional cloud providers are "brains" or connector options that Merlin can
use, not the product identity the user should feel they are using.

The v3.0 front-door layout should use an Apple-level, tabbed product shell:

- **Merlin Chat:** the main conversation surface. Early versions may link to the
  local chat workspace, but the target is a Merlin-native chat that routes
  through the Merlin task API with staff mode/model/approval metadata visible.
- **Rooms:** local chat history and project-context containers, backed by
  `docs/architecture/MERLIN_ROOMS.md`. A Room can be a
  project, topic, person, or purpose. Users choose where Room files live, decide
  whether Merlin can reference active/selected/all Rooms, and approve any
  memory extraction separately from saving transcript history.
- **Brains:** local model/provider registry. Shows Ollama/Qwen, other local
  models, Open WebUI workspace, LiteLLM aliases, and optional cloud providers as
  disabled/offline/available/approval-required. No API key values are displayed.
- **Memory:** approved memory, pending review, collection health, and delete
  paths once policy-gated backend flows are ready.
- **Agents:** research, coding, automation, and Magic Mode surfaces, all
  guarded. Plan-only behavior remains the default until execution gates are
  proven.
- **Security:** local-only state, telemetry off, cloud disabled, approval gates,
  audit summaries, and secrets-protected status.
- **System:** startup readiness, hardware tier, service health, doctor output,
  and low-memory warnings.
- **Settings:** future safe configuration surface for providers, models,
  privacy, brain storage location, backups, and advanced developer controls.

MVP for this front-door slice should be status-first and tightly scoped: tabs,
information architecture, provider/model status cards, clear empty states, safe
links, and one Merlin Chat request path through `/task`. It must not add model
downloads, direct model backend calls, cloud routing, API key submission, memory
writes, approval execution, shell/browser/file actions, or autonomous Magic
Mode execution until those flows have separate policy-gated backend issues and
tests.

## Out Of Scope For MVP

- Autonomous execution.
- Direct browser calls to model backends or unsafe execution endpoints.
- Browser or shell control.
- Dashboard-driven package installs.
- Automatic cloud routing.
- Automatic model downloads.
- Enterprise RBAC.
- Multi-user administration.
- Editing secrets or showing key values.
- Silent transcript-to-memory learning.
- Automatic Room sync to cloud.
- Referencing all Rooms without visible user policy.
- Static "ready" language that is not backed by live status checks.

## Data Sources

| Need | Source | Notes |
|---|---|---|
| Legacy read-only health | `http://localhost:8765/status` | Security contract: read-only only |
| Task route/status panels | `http://localhost:8766/status/*` | Execution-aware FastAPI app |
| Native Merlin Chat | `POST http://localhost:8766/task` | Only allowed browser POST; policy-gated by Merlin Task API |
| Rooms / chat history | Future #135 local files + local index | Not implemented yet; must distinguish transcript, index, and approved memory |
| Open WebUI | `http://localhost:3000` | Current local chat bridge remains linked until native Merlin Chat is policy-gated |
| Ollama model list | `http://localhost:11434/api/tags` | Localhost only |
| Qdrant health | `http://localhost:6333/healthz` | Local memory |
| Brain storage manifest | `http://localhost:8766/status/settings` | Read-only #130 storage paths and locked migration state |

## Product Risks

- Dashboard bypasses Merlin Task API and becomes a second direct execution surface.
- Users confuse plan-only Magic Mode with autonomous execution.
- UI hides local-only/cloud state too deeply.
- 8 GB users see options their machine cannot safely run.
- The static dashboard drifts from Python router/task API truth.

## Guardrails

- Dashboard v1 may display and request; it must not perform privileged actions directly.
- Every risky action must route through policy gates and audit logging.
- Secrets are presence-only.
- Raw user input is not stored in dashboard logs.
- Chat transcript storage must be local and user-visible.
- Saved transcripts do not become reusable memory until the user approves
  extraction.
- Brain/context storage location must be visible before change-location controls
  exist. Changing that location requires a future backend policy gate,
  migration validation, rollback, and audit trail.
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
