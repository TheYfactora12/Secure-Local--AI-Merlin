# Merlin AI Architecture

Merlin AI, also called Merlin/Wizard in parts of the repo, is intended to be a local-first AI platform that can scale from a small laptop to a home server or workstation. The design goal is not "run every AI service all the time." The design goal is a flexible install that starts with a reliable core and enables heavier capabilities by profile.

## Product Goal

Merlin AI should provide:

- Local chat over user-owned models
- A unified model gateway for local and optional cloud models
- Vector memory/RAG
- Optional private web search
- Optional workflow automation
- Optional coding/agent workflows
- A dashboard and CLI that make the system understandable
- Secure defaults where data stays local unless the user explicitly enables and approves an external provider

## Architecture Principles

### 1. Core First

The default install must boot on ordinary hardware before optional services are enabled.

Core services:

- Native Ollama on macOS
- Open WebUI
- LiteLLM
- Qdrant
- Wizard dashboard

Optional services belong behind profiles:

- Search: Perplexica + SearXNG
- Automation: n8n + workflow import
- Coding: OpenHands
- Security/proxy: nginx + fail2ban
- Ops: watchtower + launchd + scheduled backups

### 2. Scalable by Install Type

The same repo should support multiple deployment shapes:

| Install type | Intended machine | Default profiles |
|---|---|---|
| Small laptop | 8-15 GB RAM | `core` |
| Developer laptop | 16-23 GB RAM | `core`, optional `search` or `coding` |
| Workstation | 24-47 GB RAM | `core`, `search`, optional `automation` |
| High-end workstation | 48+ GB RAM | Most profiles available |
| Home server | Always-on Mac/Linux box | `core`, `search`, `automation`, `security`, `ops` |
| Custom | Advanced user | Explicit profile selection |

The installer should infer a safe default from RAM, OS, and Docker availability, but the user must be able to override profiles.

### 3. Model-Agnostic Routing

Merlin AI should not hardcode one model or provider as the system brain. LiteLLM is the current gateway and should be treated as the compatibility layer for:

- Local Ollama models
- OpenAI-compatible APIs
- Optional external providers gated by policy and user approval
- Future local runtimes such as MLX, llama.cpp, vLLM, or LocalAI-style backends

Open WebUI remains the primary user-facing chat UI, while LiteLLM provides a stable model endpoint for apps and agents.

### 4. Hardware-Aware Defaults

The installer should choose models conservatively:

| RAM | Tier | Default behavior |
|---|---|---|
| 8-15 GB | Low | 7B Q4-class models only, no OpenHands by default |
| 16-23 GB | Base | 7B chat + 7B coder models |
| 24-47 GB | Mid | 14B/32B models where practical |
| 48+ GB | High | Larger models and heavier profiles allowed |

On macOS, Ollama should run natively for Metal acceleration. Docker Ollama should only run on Linux or when explicitly selected.

### 5. Agent Orchestration Is a Profile

"Magic Mode" or swarm orchestration should be designed as an optional agent layer, not as a requirement for the first install.

The agent layer should eventually provide:

- Task classification
- Specialist routing for research, code, automation, and general chat
- Shared Qdrant memory
- Tool permissions and human approval for sensitive actions
- Traceable logs of agent decisions

Candidate orchestration approaches include n8n workflows, LangGraph-style state machines, OpenAI Agents SDK-style tool calls, or a small custom controller. The repo should not commit to a heavy agent framework until the core stack is stable.

### 6. Security Defaults

Local-first does not automatically mean safe. Secure defaults are required:

- Bind service ports to `127.0.0.1` by default
- Do not expose n8n, Ollama, Qdrant, OpenHands, or LiteLLM on LAN by accident
- Keep external providers disabled unless API keys are explicitly configured and policy approval is granted
- Keep `.env` out of git and chmod it to `600`
- Require user approval for file writes, shell commands, code execution, or networked agent actions
- Treat OpenHands and future code-execution tools as high-risk profiles
- Add `wizard doctor` checks for insecure bindings and missing secrets

### 7. Observability and Recovery

The system should explain itself when it fails.

Required operational pieces:

- `wizard doctor`
- Profile-specific health checks
- Backup and restore tested against current Qdrant collections
- Upgrade with rollback
- Logs that identify the failing service and next command
- Clear dashboard states for core/search/automation/coding profiles

## Target Command Shape

The final UX should look like this:

```bash
bash install.sh --profile core
bash install.sh --profile developer
bash install.sh --profile workstation
bash install.sh --profile server
bash install.sh --profile custom
```

And after install:

```bash
wizard doctor
wizard start
wizard start search
wizard start automation
wizard start coding
wizard start full
wizard status
wizard backup
wizard upgrade
```

## Reference Projects to Study

These projects are useful comparison points, but Merlin AI should not copy their complexity blindly:

- LocalAI: model-agnostic local inference and OpenAI-compatible APIs
- Open WebUI: unified local/cloud model chat UI
- LibreChat: multi-provider chat UI patterns
- DreamServer-style stacks: local AI bundles with chat, workflows, RAG, agents, and media tools
- LangChain/LangGraph: agent and state-machine patterns
- OpenAI Agents SDK: tool, tracing, guardrail, and multi-agent concepts
- n8n/Node-RED: visual automation patterns

## Codex Review Prompt

Use this prompt when asking an AI coding assistant to review the repo:

```text
You are reviewing Merlin AI, a self-hosted local AI platform also called Merlin/Wizard. Treat the project as a scalable install system, not a single full-stack bundle.

Review the repo as five specialists:

1. Local AI systems architect
2. macOS/Linux performance engineer
3. security engineer
4. agent orchestration engineer
5. product/UX engineer

Focus on:

- Whether the default install is laptop-safe
- Whether services are properly separated into profiles
- Whether local model routing is model-agnostic
- Whether macOS uses native Ollama and avoids Docker Ollama conflicts
- Whether low-RAM systems avoid heavy models and heavy services
- Whether OpenHands, n8n, Perplexica, SearXNG, nginx, fail2ban, and watchtower are optional
- Whether Qdrant memory and backup/restore are aligned
- Whether cloud APIs are optional and explicit
- Whether ports bind to localhost by default
- Whether the dashboard and CLI make state understandable

Compare the design with LocalAI, Open WebUI, LibreChat, LangGraph, OpenAI Agents SDK-style orchestration, n8n, and similar local AI stacks. Do not recommend adding more features until core install, doctor checks, profile startup, backup/restore, and tests are reliable.

Return:

- top architecture risks
- concrete code/config changes
- profile design proposal
- security fixes
- test plan
- documentation updates
```
