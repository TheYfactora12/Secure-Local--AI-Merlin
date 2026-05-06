# Architecture Challenge — Merlin Platform

> **Canonical reference.** Merged from `ARCHITECTURE_CHALLENGE.md` (v1 decisions) and `MERLIN_ARCHITECTURE_CHALLENGE.md` (v2+ direction and gap analysis).
> Last updated: 2026-05-06

---

## 1. What The Current Repo Is

The current repo is an installer-led local AI stack. Its strengths are practical: it can install dependencies, generate secrets, start Docker services, run native Ollama on macOS, pull RAM-tier models, run a dashboard, and expose a CLI.

It is not yet a true Merlin brain. Today, Merlin/Wizard is a naming layer across installer output, dashboard labels, `cli/wizard`, n8n workflows, and LiteLLM aliases. The actual orchestration logic is split across LiteLLM config, n8n workflows, dashboard JavaScript, and CLI shell functions.

It is already an early platform, but the product surface is not unified yet. The gap is not infrastructure — the gap is a clean v1 user loop.

---

## 2. What Should Remain Simple

- Installer
- Profile selection
- `wizard doctor`
- Local model setup
- Core dashboard status
- Magic Mode v1
- Memory approval flow

These should be boring, predictable, and easy to recover.

---

## 3. What Should Become Modular

- Provider registry
- Model routing
- Memory adapters
- Agent adapters
- Policy decisions
- Audit logging
- Dashboard status panels

These will change as hardware, model providers, and local AI tools evolve.

---

## 4. What Should Be Wrapped, Not Rebuilt

- Ollama — local models
- LiteLLM — gateway behavior
- Open WebUI — rich chat UI
- Qdrant — vector memory
- n8n — optional workflow automation
- OpenHands — optional coding execution
- SearXNG/Perplexica — local search
- gitleaks — secret scanning

Merlin provides policy, consent, routing, and UX around them.

---

## 5. What Must NOT Be Built In v1

- Custom model runtime
- Custom vector database
- Custom workflow engine
- Custom browser automation framework
- Custom coding agent
- Fine-tuning / self-training system
- Multi-user enterprise RBAC
- Always-on background agent swarm
- Cloud sync
- Public remote access

---

## 6. Architecture Options

### A. Simple Installer Wrapper
**Pros:** Fastest to stabilize. Lowest code burden. Uses proven tools.
**Cons:** Merlin stays a brand, not a coherent brain. Policy, memory, routing stay scattered.

### B. True Merlin Orchestration Layer
**Pros:** Real central API and policy layer. Unifies routing, memory, approvals, logging, dashboard.
**Cons:** Easy to overbuild. Could break installer if introduced too early.

### C. Dashboard-First Control Center
**Pros:** Best UX for non-technical users. Makes status, tiers, approvals, memory visible.
**Cons:** Without a backend policy API, can only call existing services directly.

### D. Modular Agent/Memory/Model Platform
**Pros:** Best match for full product vision. Provider-agnostic, supports RAG, agents, MCP.
**Cons:** Highest risk of architectural churn. Needs staged adoption.

### E. Hybrid ✅ Recommended

Use the working installer as the baseline. Add profile-aware startup and a small Merlin core interface. Keep Open WebUI / LiteLLM / Qdrant / Ollama as the core. Treat n8n, OpenHands, Perplexica, SearXNG, nginx, watchtower, MCP, and launchd as optional capability profiles. Introduce a Merlin orchestration layer only after health checks and profile selection are reliable.

**Final orchestration decision:** Merlin should use a hybrid architecture. The Merlin control plane should be a lightweight local controller or CLI facade responsible for status, policy evaluation, route decisions, approval requests, route traces, LiteLLM calls, and approved Qdrant memory access. n8n remains an optional workflow engine. LangGraph/OpenAI Agents SDK-style frameworks remain optional future references, not v1 dependencies. This decision is captured in `configs/merlin/orchestration.yaml`.

**Critical risk:** n8n must not remain Merlin's primary brain. It is acceptable as a Phase 1 workflow surface, but Phase 2 must make the Python Merlin control plane the primary policy/routing/memory brain, with n8n as an optional execution adapter only.

**Configuration root decision:** One canonical config tree — `configs/`. Merlin product configs → `configs/merlin/`. Model manifests → `configs/models/`. MCP templates → `configs/mcp/`. A root `config/` directory is intentionally forbidden before Phase 2 loader work.

---

## 7. Gap Analysis

| Area | Current State | Gap |
|---|---|---|
| Installer | Working baseline | Needs profile selection, not rewrite |
| Service profiles | Partial: Docker Ollama/fail2ban | Heavy services still default-on |
| Model routing | LiteLLM config exists | No policy-aware task router |
| Hardware tiers | Installer RAM tiers exist | Dashboard/CLI do not enforce or explain limits |
| Memory | Qdrant exists | Schema and collection naming inconsistent |
| Agents | n8n swarm + OpenHands exist | No unified safety/approval layer |
| Magic Mode | Conceptual via swarm/dashboard | No plan/status/approval/stop model |
| Dashboard | Static dashboard exists | No backend, auth, approvals, or service control |
| Security | Good secret rotation + localhost binds | OpenHands/docker.sock need stronger gates |
| Tests | e2e smoke exists | No profile, router, memory approval, or no-cloud tests |

---

## 8. Fastest Path to Working Merlin v1

1. Freeze current installer as baseline
2. Add docs and baseline tests
3. Add profile model: `core`, `search`, `automation`, `coding`, `security`, `ops`, `full`
4. Change default startup to `core` only after tests prove parity
5. Add `wizard doctor`
6. Normalize model and memory config
7. Add thin Merlin router facade that calls LiteLLM and logs decisions
8. Add memory approval rules before automatic writes
9. Add Magic Mode MVP as planned workflow with approval gates — not open-ended automation

---

## 9. Overengineering Risks

- Adding LangGraph/MCP/OpenAI Agents SDK before the core user loop is proven
- Building a custom dashboard chat instead of using Open WebUI
- Building a custom model gateway instead of LiteLLM
- Building a custom memory database instead of Qdrant
- Making Magic Mode an execution engine too early
- Designing enterprise features before a single-user v1 works
- Using high-end Mac assumptions that break M1 8GB installs

---

## 10. Underbuilding Risks

- Leaving the user confused about what Merlin is
- Too many entrypoints: Open WebUI, `wizard ask`, swarm, dry-run, task API
- Failing to show approvals and local-only state clearly
- Not proving memory consent
- Not testing 8GB Macs
- Not explaining degraded mode

---

## 11. Architecture Reference Table

| Reference | Pattern To Borrow | Avoid Copying |
|---|---|---|
| Open WebUI | Unified chat UX, local/cloud provider selection, model listing | Making UI the only control plane |
| AnythingLLM | Document/RAG UX patterns | Adding another full UI stack |
| LocalAI | Model-agnostic local inference, OpenAI-compatible surfaces | Replacing Ollama/LiteLLM immediately |
| Ollama | Simple local model lifecycle, Mac-friendly runtime | Assuming Ollama alone is the orchestration layer |
| LangChain/LangGraph | Tool calling, graphs, stateful agent flows | Heavy framework lock-in before Merlin v1 |
| OpenAI Agents SDK | Agents, tools, handoffs, tracing, guardrails | Cloud-first assumptions |
| LiteLLM | Provider abstraction and routing config | Treating static YAML as full policy engine |
| MCP-style tools | Tool contracts and integration boundary | Exposing filesystem/GitHub tools without policy |
| Qdrant/Chroma/SQLite | Local memory and retrieval patterns | "Embed everything" without audit, schemas, deletion |
| Msty | Consumer-grade local AI UX | Depending on closed app behavior |

---

## 12. Most Defensible Architecture

A local-first command center:

- Installer delivers profiles
- Merlin Core routes and enforces policy
- Existing tools do specialized work
- Magic Mode plans before executing
- Dashboard explains health, risk, and approvals
- Cloud and execution are opt-in, visible, and audited

That architecture is secure, explainable, testable, and shippable.

---

## 13. v2 Direction

- Small local Merlin API service
- Dashboard-backed service/profile control
- Policy-managed tool registry
- Memory schemas and audit UI
- Offline/online mode toggle
- Provider/plugin abstraction
- Profile-specific tests and upgrades

## 14. v3 Direction

- Multi-agent graph orchestration
- Local fine-tuning or preference learning
- Voice companion mode
- Document ingestion pipelines
- Personal assistant behavior
- Multi-machine memory sync
- Advanced observability/tracing
