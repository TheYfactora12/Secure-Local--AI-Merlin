# Memory Benchmarking

Merlin AI memory must be measurable before it becomes more autonomous.
The v1.5 benchmark harness starts with deterministic offline fixtures so CI can
gate memory changes without live Qdrant, Ollama, LiteLLM, n8n, Docker, cloud
credentials, or network access.

## Command

```bash
wizard benchmark run --suite epbench
wizard benchmark run --suite all --profile offline
```

Direct script:

```bash
bash scripts/run-benchmarks.sh --suite all --profile offline
```

## Suites

| Suite | Current v1.5 profile | What it measures |
| --- | --- | --- |
| EpBench | Offline deterministic fixtures | Episodic recall, event ordering, temporal grounding |
| MemoryArena | Offline deterministic fixtures | Multi-session dependency recall |
| AMA-Bench | Offline deterministic fixtures | Long-horizon policy and causal recall |

## Metrics

The shared harness reports:

- `hit_at_k`
- `recall_at_k`
- `f1_at_k`
- `layer_accuracy`
- `contradiction_drift_rate`
- latency `p50_ms` and `p95_ms`

The first merge gate is EpBench `recall_at_k >= 0.75` at `top_k=5`.

## Current Scope

The current harness does not create Qdrant collections, call Ollama, or mutate
memory. It validates the scoring contract and command surface first. Live
Qdrant/Ollama benchmark profiles must be added behind
`MERLIN_INTEGRATION_TESTS=1` in a later issue.

## Collection Policy

The original #7 text referenced `wizard_working`, `wizard_episodic`,
`wizard_semantic`, and `wizard_action`. That naming is stale. The current memory
manifest uses canonical Merlin collections in `configs/merlin/memory.yaml`:

- `merlin_session`
- `merlin_user`
- `merlin_documents`
- `merlin_tools`
- `merlin_audit`

Do not rename live or canonical collections without migration scripts, restore
tests, and explicit approval.

## CI

`tests/benchmark-smoke.sh` runs in the static smoke suite. It verifies the
benchmark files exist, all three suites run offline, deterministic recall is
reported, and `wizard benchmark run` is wired to `scripts/run-benchmarks.sh`.

## Rollback

Revert the benchmark harness files, `wizard benchmark` wiring, and the CI smoke
entry. This does not affect installer behavior, live Qdrant data, n8n workflows,
Merlin runtime APIs, or Docker services.
