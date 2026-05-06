# Merlin Architecture Challenge

## What The Current Repo Is

The current repo is an installer-led local AI stack. Its strengths are practical: it can install dependencies, generate secrets, start Docker services, run native Ollama on macOS, pull RAM-tier models, run a dashboard, and expose a CLI.

It is not yet a true Merlin brain. Today, Merlin/Wizard is a naming layer across installer output, dashboard labels, `cli/wizard`, n8n workflows, and LiteLLM aliases. The actual orchestration logic is split across LiteLLM config, n8n workflows, dashboard JavaScript, and CLI shell functions.

## Architecture Options

### A. Simple Installer Wrapper Around Existing Tools

Pros:

- Fastest to stabilize.
- Lowest custom code burden.
- Uses proven tools: Ollama, Open WebUI, LiteLLM, Qdrant, n8n, SearXNG.
- Best near-term fit for the working installer.

Cons:

- Merlin remains mostly a brand, not a coherent brain.
- Policy, memory, routing, approvals, and dashboard state stay scattered.
- Harder to create Magic Mode with consistent safety controls.

### B. True Merlin Orchestration Layer

Pros:

- Gives Merlin a real central API and policy layer.
- Can unify model routing, memory writes, agent tools, approvals, logging, and dashboard state.
- Best long-term direction.

Cons:

- Easy to overbuild.
- Could break installer if introduced as a hard dependency too early.
- Needs tests, config model, and rollback strategy before becoming critical path.

### C. Dashboard-First Local AI Control Center

Pros:

- Best user experience for non-technical users.
- Can make model status, hardware tier, offline mode, approvals, and memory visible.
- Useful even before deeper orchestration exists.

Cons:

- Dashboard without a backend policy API can only call existing services directly.
- UI polish alone will not solve routing, memory, or safety.

### D. Modular Agent/Memory/Model Platform

Pros:

- Best match for the full product vision.
- Can support provider-agnostic models, RAG, agents, MCP tools, and future Magic Mode.
- Strong separation of model, memory, tools, and policies.

Cons:

- Highest risk of architectural churn.
- Needs staged adoption so the installer remains reliable.

### E. Hybrid

Recommendation: choose the hybrid.

Use the working installer as the baseline. Add profile-aware startup and a small Merlin core interface. Keep Open WebUI/LiteLLM/Qdrant/Ollama as the core. Treat n8n, OpenHands, Perplexica, SearXNG, nginx, watchtower, MCP, and launchd as optional capability profiles. Introduce a Merlin orchestration layer only after health checks and profile selection are reliable.

Final orchestration decision: Merlin should use a hybrid architecture. The Merlin control plane should be a lightweight local controller or CLI facade responsible for status, policy evaluation, route decisions, approval requests, route traces, LiteLLM calls, and approved Qdrant memory access. n8n remains an optional workflow engine, OpenHands remains an optional high-risk coding executor, Perplexica/SearXNG remain optional search tools, and LangGraph/OpenAI Agents SDK-style frameworks remain optional future references rather than v1 dependencies. This decision is captured in `config/merlin/orchestration.yaml`.

## Architecture References

These are reference patterns, not dependencies to copy.

| Reference | Pattern to borrow | Avoid copying |
|---|---|---|
| Open WebUI | Unified chat UX, local/cloud provider selection, model listing | Making UI the only control plane |
| LocalAI | Model-agnostic local inference, OpenAI-compatible surfaces, backend flexibility | Replacing Ollama/LiteLLM immediately |
| Ollama | Simple local model lifecycle and Mac-friendly runtime | Assuming Ollama alone is the orchestration layer |
| LangChain/LangGraph | Tool calling, graphs, stateful agent flows | Heavy framework lock-in before Merlin v1 |
| OpenAI Agents SDK-style patterns | Agents, tools, handoffs, tracing, guardrails | Cloud-first assumptions |
| LiteLLM | Provider abstraction and routing config | Treating static YAML as full policy engine |
| MCP | Tool integration boundary | Exposing filesystem/GitHub tools without policy |
| Qdrant/Chroma/SQLite memory | Local memory and retrieval patterns | "Embed everything" without audit, schemas, deletion |

## Gap Analysis

| Area | Current state | Gap |
|---|---|---|
| Installer | Working baseline | Needs profile selection, but not rewrite |
| Service profiles | Partial: Docker Ollama/fail2ban profiles | Heavy services still default |
| Model routing | LiteLLM config exists | No policy-aware task router yet |
| Hardware tiers | Installer RAM tiers exist | Dashboard/CLI do not enforce or explain profile limits |
| Memory | Qdrant exists | Schema and collection naming are inconsistent |
| Agents | n8n swarm and OpenHands exist | No unified safety/approval layer |
| Magic Mode | Conceptual via swarm/dashboard | No plan/status/approval/stop model |
| Dashboard | Static dashboard exists | No backend, auth, approvals, or service control model |
| Security | Good secret rotation and localhost binds | OpenHands/docker.sock and automation need stronger gates |
| Tests | e2e smoke exists | No profile, router, memory approval, or no-cloud tests |

## Best-Fit Recommendation

Build Merlin as a small control plane, not as a replacement for the working stack.

Merlin v1 should:

1. Preserve `install.sh`.
2. Add profile-aware install/start semantics.
3. Add `wizard doctor`.
4. Define a canonical config file for profiles, tier, models, and policy.
5. Add a Merlin core API or CLI facade only after the config model is stable.
6. Keep LiteLLM as the model gateway for v1.
7. Keep Qdrant as the vector store for v1.
8. Keep Open WebUI as the primary chat UI for v1.
9. Keep n8n and OpenHands optional.
10. Use a hybrid orchestration model: lightweight Merlin control plane first, optional workflow/agent frameworks later.

## Risks of Overengineering

- Building a custom agent runtime before core install is reliable.
- Adding LangChain/LangGraph/OpenAI Agents SDK as mandatory dependencies too early.
- Replacing LiteLLM while it already solves provider abstraction.
- Creating multiple dashboards instead of a single coherent control surface.
- Treating memory as automatic learning without approval, deletion, or audit.
- Making Magic Mode autonomous before permission gates exist.
- Using high-end Mac assumptions that make M1 8GB installs fail.

## Fastest Path to Working Merlin v1

1. Freeze the current installer as baseline.
2. Add docs and baseline tests.
3. Add profile model: `core`, `search`, `automation`, `coding`, `security`, `ops`, `full`.
4. Change default startup to `core` only after tests prove parity.
5. Add `wizard doctor`.
6. Normalize model and memory config.
7. Add a thin Merlin router facade that calls LiteLLM and logs decisions.
8. Add memory approval rules before automatic writes.
9. Add Magic Mode MVP as a planned workflow with approval gates, not open-ended automation.

## v2 Direction

Merlin v2 can introduce:

- A small local Merlin API service.
- Dashboard-backed service/profile control.
- Policy-managed tool registry.
- Memory schemas and audit UI.
- Offline/online mode toggle.
- Provider/plugin abstraction.
- Profile-specific tests and upgrades.

## v3 Direction

Merlin v3 can explore:

- Multi-agent graph orchestration.
- Local fine-tuning or preference learning.
- Voice companion mode.
- Document ingestion pipelines.
- Personal assistant behavior.
- Multi-machine memory sync.
- Advanced observability/tracing.

## Decision

The repo should evolve into a hybrid: a protected installer baseline plus a modular Merlin control plane. Do not replace the installer. Do not make Magic Mode or agent frameworks mandatory for v1. Make the core reliable first, then add Merlin as a policy-aware layer above the current stack.
