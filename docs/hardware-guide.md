# Home AI Elite Hardware Guide

Status: v1.2 planning baseline. This guide documents buying and setup choices;
it does not change installer behavior.

Home AI Elite starts at 8GB RAM in low/core mode and scales upward by profile.
The entry point is intentionally modest: one small local chat model, local
embeddings, Qdrant memory, dashboard, and health tooling. The full stack is not
expected to run well on 8GB.

## Quick Decision Tree

| If you have... | Choose | Expect |
|---|---|---|
| 8-15GB unified RAM | `low` / core | Daily private chat, basic memory, dashboard, one model at a time |
| 16-23GB RAM | `base` / core + optional search | Better coding/reasoning options, one heavy task at a time |
| 24-47GB RAM | `mid` / core + search + optional automation | Stronger local models, limited supervised workflows |
| 48GB+ RAM | `high` / intentional full profiles | Large local models, heavier RAG, more services |

## Tier Details

### Tier 1: Low, 8-15GB

Best fit:

- Existing M1/M2/M3 MacBook or Mac mini with 8GB RAM.
- Users who want a private local assistant without running every service.
- Testing, demos, and safe defaults.

Recommended behavior:

- Profile: `core`.
- Models: `qwen2.5:7b` and `nomic-embed-text`.
- One model active at a time.
- No automatic large model downloads.
- No OpenHands by default.
- No full search + automation + coding stack at the same time.
- Magic Mode stays plan-only.

What will fail or feel bad:

- 14B+ models.
- Multiple parallel agents.
- OpenHands plus search plus automation at the same time.
- Large document ingestion batches.
- Long-context RAG over many PDFs.

### Tier 2: Base, 16-23GB

Best fit:

- Developer laptops.
- Users who want coding help and private search occasionally.

Recommended behavior:

- Profile: `core`, with optional `search`.
- Models: `qwen2.5:7b`, `qwen2.5-coder:7b`, `deepseek-r1:7b`,
  `nomic-embed-text`.
- One heavy profile at a time.
- Small document ingestion batches.

### Tier 3: Mid, 24-47GB

Best fit:

- Workstations and high-end laptops.
- Users who want stronger local reasoning and more frequent RAG.

Recommended behavior:

- Profile: `core`, `search`, optional `automation`.
- Models: `qwen2.5:32b`, `qwen2.5-coder:14b`, `deepseek-r1:14b`,
  `nomic-embed-text`.
- Limited supervised agent workflows after approval.
- Moderate document ingestion.

### Tier 4: High, 48GB+

Best fit:

- Mac Studio, high-memory MacBook Pro, Linux workstation, or home server.
- Users who want larger models and heavier local workflows.

Recommended behavior:

- Profile: intentionally selected full or multi-profile setup.
- Models: `llama3.3:70b`, `qwen2.5:32b`, `deepseek-r1:32b`,
  `nomic-embed-text`.
- Larger document indexes.
- More services can run together, but policy gates still apply.

## Storage And Network

Storage:

- Minimum: 50GB free for core use.
- Comfortable: 200GB+ if keeping multiple 7B/14B models.
- Heavy local RAG: 500GB+ NVMe recommended.
- Fast internal SSD or NVMe is strongly preferred. Slow external disks make
  model loads and document ingestion feel broken.

Network:

- Core local chat does not require internet after dependencies and models are
  installed.
- Initial install may need network for Homebrew, Docker images, Python packages,
  and optional model pulls.
- LAN/mobile access remains opt-in only. See `docs/MOBILE_ACCESS_PLAN.md`.
- Cloud providers remain off by default.

## Buying Guidance

| Budget | Practical choice | Why |
|---|---|---|
| Use what you own | Any Apple Silicon Mac with 8GB+ | Good enough for low/core mode |
| Best entry buy | Mac mini with 16GB+ | More headroom for search/coding than 8GB |
| Best developer buy | 24GB-36GB MacBook Pro or Mac mini | Comfortable local coding and RAG |
| Best power buy | 48GB+ Mac Studio or MacBook Pro | Larger local models and multiple profiles |
| Linux option | NVIDIA GPU workstation | Strong for model throughput, more ops burden |

The 8GB Mac remains supported as the entry point. If buying new hardware for
serious daily use, 16GB+ is the practical floor and 24GB+ is the better long-term
choice.

## Validation Commands

```bash
bash scripts/doctor.sh
bash cli/wizard merlin status
bash scripts/add-model.sh qwen2.5:7b
```

Expected on 8GB:

- Hardware tier reports `low`.
- Doctor warns about low-memory constraints but exits with zero failures when
  services are healthy.
- Model pulls are explicit; the installer does not need to pull large models
  automatically.

