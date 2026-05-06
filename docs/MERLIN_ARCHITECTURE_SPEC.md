# Merlin Architecture Spec

Last updated: 2026-05-06

## Target Architecture

Merlin is a secure orchestration layer around existing local AI tools.

It should not replace Ollama, LiteLLM, Open WebUI, Qdrant, n8n, or OpenHands. It should wrap them with routing, policy, approvals, status, memory controls, and audit logs.

## System Diagram

```mermaid
flowchart TB
  User[User] --> Dashboard[Dashboard]
  User --> CLI[wizard CLI]
  User --> OpenWebUI[Open WebUI]

  Dashboard --> Status8765[Read-only Status API :8765]
  Dashboard --> Task8766[Merlin Task API :8766]
  CLI --> Task8766
  CLI --> Scripts[Operational Scripts]
  OpenWebUI --> LiteLLM[LiteLLM Gateway]

  subgraph MerlinCore[Merlin Core]
    Task8766 --> Router[Model Router]
    Task8766 --> Policy[Policy Engine]
    Task8766 --> Persona[Persona Injector]
    Task8766 --> Memory[Memory Manager]
    Task8766 --> Audit[Audit Logger]
    Router --> Providers[Provider Registry]
    Policy --> Approvals[Approval Gates]
    Magic[Magic Mode Planner] --> Router
    Magic --> Policy
  end

  Providers --> LiteLLM
  LiteLLM --> Ollama[Ollama Local Runtime]
  Providers -. optional explicit approval .-> Cloud[Cloud Providers]
  Memory --> Qdrant[Qdrant]
  Magic -. future approved adapter .-> N8N[n8n]
  Magic -. future approved adapter .-> OpenHands[OpenHands]
```

## Data Flow

```mermaid
flowchart LR
  A[User input] --> B[Validate input]
  B --> C[Route decision]
  C --> D[Policy gate check]
  D -->|blocked| E[Approval required response]
  D -->|allowed| F[Build Merlin prompt]
  F --> G[LiteLLM local alias]
  G --> H[Ollama model]
  H --> I[Response]
  I --> J[Trace audit]
  I --> K{Memory requested?}
  K -->|no| L[Return response]
  K -->|yes| M[memory_write approval]
  M -->|approved| N[Qdrant write]
  M -->|blocked| L
  N --> L
```

## Component Specs

| Component | Inputs | Outputs | Responsibilities | MVP Tests |
| --- | --- | --- | --- | --- |
| Merlin Core | Task request, session, config | Response, route, trace | Validate input, orchestrate router/policy/persona/model/memory | Endpoint happy/degraded/403 tests |
| Model Router | User input, routes, hardware/provider state | Route decision | Classify task, choose route/model alias, hash input logs | Route tests for all route IDs |
| Provider Registry | Config, env key presence, health | Provider availability | Track local vs optional cloud providers | Cloud disabled by default |
| Memory Manager | Text, metadata, collection | Point IDs, search results | Embed locally, validate dimensions, write/search/delete | Dimension/degraded tests |
| Agent Controller | Plan step, approval | Adapter call or blocked result | Future adapter boundary for n8n/OpenHands/tools | v1 plan-only no execution |
| Policy Engine | Action gate, policy config | Allow/block | Fail closed, require approval for risky actions | All gates enforced |
| Audit Logger | Route/policy/action events | Redacted logs | No raw input/secrets, trace outcomes | Redaction tests |
| Magic Mode | Goal, route registry | Plan steps | Plan first, no v1 execution | Plan-only smoke tests |
| Dashboard | Status APIs | UI state | Explain health, local mode, approvals, memory | UI smoke/no secret display |
| Hardware Tier Engine | RAM/OS/profile | Tier, warnings | Recommend safe defaults | 8GB low tier tests |

## Dependency Policy

- Direct dependencies are allowed only when the repo cannot reasonably wrap an existing service.
- Adapter integrations are preferred for external systems.
- Future integrations should be optional until they prove value.

| Tool/Pattern | v1 Treatment |
| --- | --- |
| Ollama | Required local runtime wrapper |
| LiteLLM | Existing gateway wrapper |
| Open WebUI | Existing UI, not replaced |
| Qdrant | Existing memory store |
| n8n | Optional adapter, no default execution |
| OpenHands | Optional high-risk adapter, no v1 execution |
| LangChain/LangGraph | Architecture reference only |
| OpenAI Agents SDK | Architecture reference only |
| MCP | Tool interface reference only |
| Chroma/SQLite memory | Reference alternatives, not added |
