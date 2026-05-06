# Current Architecture

Last updated: 2026-05-06

## What The Repo Is Today

The repo is a local-first AI stack with a protected installer plus an emerging Merlin control layer.

It is already more than a one-shot installer because it includes:

- Profile-aware service startup.
- Runtime diagnostics.
- Memory read/write tools.
- Policy-gated dry-run and approvals.
- Plan-only Magic Mode.
- Merlin Python task/status API.
- CI and security scanning.

It is not yet a polished Merlin product because the user-facing loop is still split between Open WebUI, `wizard ask`, legacy swarm/n8n paths, Merlin scripts, and the dashboard.

## Runtime Components

| Component | Current Role | State |
| --- | --- | --- |
| Installer | Sets up local stack and profiles | Working, protect |
| Docker Compose | Service graph | Working, protect |
| Ollama | Local model runtime | Working, native on macOS |
| LiteLLM | Local-first model gateway | Working |
| Open WebUI | Chat UI | Working |
| Qdrant | Vector memory | Working |
| n8n | Optional automation/swarm workflows | Existing, optional |
| OpenHands | Optional coding agent | Existing, high risk |
| Dashboard | Static local status UI | Working but not full Merlin product UI |
| Merlin scripts | Dry-run, approvals, memory, Magic plan | Useful shell control layer |
| Merlin Python core | Config/policy/router/memory/persona/task/status | Built and tested |

## Current System Diagram

```mermaid
flowchart TB
  subgraph UserLayer[User Layer]
    CLI[wizard CLI]
    UI[Dashboard :8888]
    Chat[Open WebUI :3000]
  end

  subgraph MerlinLayer[Merlin Layer]
    Shell[Merlin shell scripts]
    Core[FastAPI task/status :8766]
    Legacy[Read-only status API :8765]
    Policy[Policy + approvals]
    Router[Router]
    Memory[Memory manager]
  end

  subgraph ServiceLayer[Local Services]
    LiteLLM[LiteLLM :4000]
    Ollama[Ollama :11434]
    Qdrant[Qdrant :6333]
    WebUI[Open WebUI]
    Search[SearXNG/Perplexica]
    Automation[n8n]
    Coding[OpenHands]
  end

  CLI --> Shell
  CLI --> Core
  UI --> Legacy
  UI --> Core
  Chat --> LiteLLM
  Shell --> Policy
  Core --> Policy
  Core --> Router
  Core --> Memory
  Core --> LiteLLM
  Memory --> Qdrant
  LiteLLM --> Ollama
  Search --> LiteLLM
  Automation --> LiteLLM
  Coding --> LiteLLM
```

## Current Data Flow

```mermaid
sequenceDiagram
  participant User
  participant Wizard as wizard CLI
  participant Merlin as Merlin :8766
  participant Policy as Policy Engine
  participant LiteLLM
  participant Ollama
  participant Qdrant

  User->>Wizard: ask/status/dry-run/memory
  Wizard->>Merlin: task or status request
  Merlin->>Policy: check route gates
  alt risky route
    Policy-->>Merlin: approval required
    Merlin-->>User: blocked with gates
  else allowed local route
    Merlin->>LiteLLM: local chat completion
    LiteLLM->>Ollama: local model call
    Ollama-->>LiteLLM: response
    LiteLLM-->>Merlin: response
    opt approved memory write
      Merlin->>Policy: memory_write gate
      Merlin->>Qdrant: write/search/delete
    end
    Merlin-->>User: response + route metadata
  end
```

## Architectural Tension

The current architecture has two control layers:

- Legacy shell-first Merlin scripts.
- New Python FastAPI Merlin core.

That is acceptable during transition, but v1 should make the product entrypoint clear. The safest path is to keep shell scripts for operational tasks and use Python core for task routing, policy, persona, and status.
