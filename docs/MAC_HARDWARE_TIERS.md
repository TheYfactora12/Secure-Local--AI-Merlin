# Mac Hardware Tiers

Last updated: 2026-05-06

The 8GB Mac is the entry point and design floor. It is not the target for the full stack. If v1 works there in low/core mode, it can scale up by enabling profiles, services, and larger models as hardware allows. If v1 assumes workstation resources, it will fail the users who need safe defaults most.

## Tier Table

| Tier | RAM | Mode | Default Models | Quantization | Services | Magic Mode | Warnings |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tier 1 | 8-15GB | Light | 7B or smaller plus embeddings | Q4 preferred | Core only | Plan-only | Avoid OpenHands, n8n, full search, 14B+ |
| Tier 2 | 16-24GB | Standard | 7B-13B | Q4/Q5 | Core plus optional search | Plan-only; limited agents | One heavy task at a time |
| Tier 3 | 32-64GB | Pro | 14B-32B | Q4/Q5/Q6 | Core, search, automation, limited coding | Supervised execution can be tested | Watch parallel memory/model load |
| Tier 4 | 96GB+ | Elite | 32B-70B where practical | Q4/Q5+ | Full stack intentional | Parallel supervised workflows | Still approval-gated |

## Tier 1: M1/M2 8GB

- Safe default: `core`.
- Entry point only: no expectation that every capability runs here.
- One model active at a time.
- No automatic large downloads.
- No heavy background services.
- No parallel agents.
- Light memory only.
- Magic Mode plan-only.
- Fallback: degraded message plus next command.

Test cases:

- Core install completes without model pulls.
- Doctor reports low tier.
- Full/coding profiles warn before start.
- Large model pull requires confirmation.
- Memory write does not auto-run.

## Tier 2: 16GB-24GB

- Safe default: `core`.
- Optional search.
- 7B-13B quantized models.
- Limited RAG.
- Limited supervised agents after approval.
- Fallback: warn when multiple heavy services are active.

Test cases:

- Search profile can start with warnings.
- OpenHands remains opt-in.
- Router avoids high-memory model aliases.

## Tier 3: 32GB-64GB

- Safe default: `core`, with search/automation recommended by user intent.
- Stronger local models.
- Heavier RAG.
- Limited parallel agents after approval.
- Supervised execution can be introduced after v1.

Test cases:

- Automation profile starts independently.
- Memory indexing warns on large jobs.
- Magic Mode still asks before execution.

## Tier 4: 96GB+

- Full stack available intentionally.
- Larger local models and memory indexes are practical.
- Parallel workflows can be tested.
- Approval gates remain mandatory.

Test cases:

- Full profile can run with explicit user selection.
- Parallel agents never start without approval.
- Cloud remains off by default.

## Dashboard Behavior

- Always show tier.
- Explain that 8GB is entry-level low/core mode, not full-stack mode.
- Explain why services are disabled.
- Warn before model pulls.
- Warn before starting optional heavy profiles.
- Show degraded mode without blaming the user.
