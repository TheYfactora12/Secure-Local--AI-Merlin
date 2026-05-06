# Architecture Challenge

Last updated: 2026-05-06

## 1. Is This Just An Installer, Or Already A Platform?

It is already an early platform, but the product surface is not unified yet.

The installer is real and useful. Merlin Core, policy, memory, status, Magic plan, approvals, CI, and dashboard status are also real. The gap is not infrastructure; the gap is a clean v1 user loop.

## 2. What Should Remain Simple?

- Installer.
- Profile selection.
- `wizard doctor`.
- Local model setup.
- Core dashboard status.
- Magic Mode v1.
- Memory approval flow.

These should be boring, predictable, and easy to recover.

## 3. What Should Become Modular?

- Provider registry.
- Model routing.
- Memory adapters.
- Agent adapters.
- Policy decisions.
- Audit logging.
- Dashboard status panels.

These should be modular because they will change as hardware, model providers, and local AI tools evolve.

## 4. What Should Be Wrapped Instead Of Rebuilt?

- Ollama for local models.
- LiteLLM for gateway behavior.
- Open WebUI for rich chat.
- Qdrant for vector memory.
- n8n for optional workflow automation.
- OpenHands for optional coding execution.
- SearXNG/Perplexica for local search.
- gitleaks for secret scanning.

Merlin should provide policy, consent, routing, and UX around them.

## 5. What Should Not Be Built At All In v1?

- Custom model runtime.
- Custom vector database.
- Custom workflow engine.
- Custom browser automation framework.
- Custom coding agent.
- Fine-tuning/self-training system.
- Multi-user enterprise RBAC.
- Always-on background agent swarm.
- Cloud sync.
- Public remote access.

## 6. Fastest Path To Useful Merlin v1

The fastest useful v1 is:

1. `wizard merlin ask`.
2. Read-only dashboard Merlin panel.
3. Explicit memory approval flow.
4. Plan-only Magic Mode.

This makes Merlin visible without touching the installer or enabling risky execution.

## 7. Overengineering Risks

- Adding LangGraph/MCP/OpenAI Agents SDK before the core user loop is proven.
- Building a custom dashboard chat instead of using Open WebUI.
- Building a custom model gateway instead of LiteLLM.
- Building a custom memory database instead of Qdrant.
- Making Magic Mode an execution engine too early.
- Designing enterprise features before a single-user v1 works.

## 8. Underbuilding Risks

- Leaving the user confused about what Merlin is.
- Keeping too many entrypoints: Open WebUI, `wizard ask`, swarm, dry-run, task API.
- Failing to show approvals and local-only state clearly.
- Not proving memory consent.
- Not testing 8GB Macs.
- Not explaining degraded mode.

## 9. Reference Architecture Comparison

| Reference | Useful Lesson | Do Not Copy |
| --- | --- | --- |
| Open WebUI | Friendly local/cloud model UI | Do not rebuild chat UI for v1 |
| AnythingLLM | Document/RAG UX patterns | Do not add another full UI stack |
| LocalAI | Local multi-backend model serving | Do not replace Ollama/LiteLLM now |
| Ollama | Simple model lifecycle | Do not rebuild model runtime |
| Msty | Consumer-grade local AI UX | Do not depend on closed app behavior |
| LangChain/LangGraph | Agent graph concepts | Do not add as mandatory v1 runtime |
| OpenAI Agents SDK | Tool approval concepts | Do not add cloud-first assumptions |
| LiteLLM-style routing | Provider abstraction | Keep LiteLLM as gateway |
| MCP-style tools | Tool contracts | Avoid server sprawl in v1 |
| Qdrant/Chroma/SQLite memory | Local memory tradeoffs | Keep Qdrant; consider SQLite only for audit/index metadata |

## 10. Most Defensible Architecture

The most defensible architecture is a local-first command center:

- Installer delivers profiles.
- Merlin Core routes and enforces policy.
- Existing tools do specialized work.
- Magic Mode plans before executing.
- Dashboard explains health, risk, and approvals.
- Cloud and execution are opt-in, visible, and audited.

That architecture is secure, explainable, testable, and shippable.
