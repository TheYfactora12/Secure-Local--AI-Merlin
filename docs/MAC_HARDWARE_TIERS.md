# Mac Hardware Tiers

Home AI Elite should scale from small Apple Silicon laptops to high-memory workstations. The installer should detect hardware and choose conservative defaults, while still allowing explicit user override.

## Tier Summary

| Tier | Machine | Goal | Default model size | Quantization | Services enabled | Background limits | Fallback behavior |
|---|---|---|---|---|---|---|---|
| Tier 1 | M1/M2 Mac, 8 GB RAM | Lightweight local AI | 3B-7B | Q4 preferred | core only | no heavy background services | ask before search/coding/automation; suggest cloud only if user enabled |
| Tier 2 | 16-24 GB Mac | Better local chat/code, light RAG | 7B-14B | Q4/Q5 | core, optional search | one active model runner; limited RAG | route heavy work to smaller model or ask for cloud/profile enablement |
| Tier 3 | 32-64 GB Mac | Stronger local models and Magic Mode | 14B-32B | Q4/Q5/Q6 | core + search + optional automation/coding | limited parallel agents | allow local heavier model with status warnings |
| Tier 4 | 96 GB+ Mac | Advanced local models and parallel agents | 32B-70B | Q4/Q5 or higher where practical | most profiles available | controlled parallel agents | local-first; cloud fallback rarely needed |

## Detailed Recommendations

### Tier 1: M1/M2 Mac with 8 GB RAM

Goal: lightweight local AI and safe first-run success.

Defaults:

- Install profile: `core`
- Model size: 3B-7B
- Quantization: Q4
- Context: small/medium context; avoid very long prompts
- Services enabled:
  - native Ollama
  - Open WebUI
  - LiteLLM
  - Qdrant only if memory is explicitly enabled or low-footprint
  - dashboard
- Services disabled by default:
  - OpenHands
  - n8n
  - Perplexica
  - SearXNG
  - nginx
  - watchtower
  - fail2ban

Dashboard warnings:

- "Low-memory mode: coding agents and full search stack are disabled by default."
- "Use 7B-class local models. Large models may cause swap and poor performance."

Fallback behavior:

- Ask before enabling cloud.
- Ask before pulling any model larger than 7B.
- Ask before starting coding or automation profiles.

### Tier 2: 16 GB to 24 GB Mac

Goal: local chat/code, light RAG, and optional search.

Defaults:

- Install profile: `core`
- Optional suggested profile: `search`
- Model size: 7B-14B
- Quantization: Q4/Q5
- Context: moderate, with summarization for long tasks
- Services enabled:
  - native Ollama
  - Open WebUI
  - LiteLLM
  - Qdrant
  - dashboard
- Optional:
  - SearXNG/Perplexica
  - n8n only after user chooses automation
  - OpenHands only with warning

Dashboard warnings:

- "Developer laptop tier: run one heavy model or agent task at a time."
- "OpenHands can be memory-intensive; enable only when needed."

Fallback behavior:

- Prefer local 7B coder/general models.
- If a task is too large, ask to enable cloud or defer to a larger local model.

### Tier 3: 32 GB to 64 GB Mac

Goal: stronger local models, better RAG, and controlled Magic Mode.

Defaults:

- Install profile: `workstation`
- Model size: 14B-32B
- Quantization: Q4/Q5/Q6 depending on RAM
- Context: larger local context, but still summarize long documents
- Services enabled:
  - core
  - search
  - optional automation
- Services optional:
  - OpenHands
  - nginx/security
  - watchtower/ops

Dashboard warnings:

- "Workstation tier: Magic Mode can run, but file/shell/network actions still require approval."
- "Parallel agents may slow local inference."

Fallback behavior:

- Route most tasks locally.
- Ask before cloud fallback.
- Allow larger model pull after confirmation.

### Tier 4: 96 GB+ Mac

Goal: advanced local AI, heavier RAG, and stronger local agents.

Defaults:

- Install profile: `server` or `workstation`, user-selected
- Model size: 32B-70B
- Quantization: Q4/Q5 and higher where practical
- Context: large local context, still avoid unbounded prompts
- Services enabled:
  - core
  - search
  - automation
  - optional coding
  - optional ops/security

Dashboard warnings:

- "High-memory tier: full stack is available, but approval gates still apply."
- "Watchtower and launchd are operational choices, not required for local chat."

Fallback behavior:

- Prefer local models.
- Cloud only for user-approved tasks or unavailable capabilities.

## Config Recommendations

Future config should express tier behavior explicitly:

```yaml
hardware_tiers:
  low:
    ram_gb_min: 8
    ram_gb_max: 15
    default_profile: core
    max_model_class: 7b
    allow_background_agents: false
  base:
    ram_gb_min: 16
    ram_gb_max: 24
    default_profile: core
    suggested_profiles: [search]
    max_model_class: 14b
  mid:
    ram_gb_min: 32
    ram_gb_max: 64
    default_profile: workstation
    suggested_profiles: [search, automation]
    max_model_class: 32b
  high:
    ram_gb_min: 96
    default_profile: server
    suggested_profiles: [search, automation, coding, ops]
    max_model_class: 70b
```

## Installer Behavior

Required:

- Detect RAM.
- Detect macOS version.
- Detect Apple Silicon vs Intel.
- Detect Docker Desktop.
- Detect native Ollama.
- Recommend profile and models.
- Ask before pulling large models.
- Ask before enabling heavy profiles.
- Write chosen tier/profile to `.env` or future `configs/merlin/profiles.yaml`.

Do not:

- Start OpenHands by default on Tier 1.
- Pull 14B+ models on Tier 1.
- Start full stack by default on low-memory machines.
- Enable cloud fallback without explicit user choice.
