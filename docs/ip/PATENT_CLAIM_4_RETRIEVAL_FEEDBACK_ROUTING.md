# Patent Claim 4 — Retrieval Feedback Routing

**Status:** Implemented. Current code supports local JSONL approved outcome
retrieval with time decay and local Qdrant task-signature vector retrieval as a
non-blocking claim-hardening extension.

## Hard Architectural Constraints

- `NO_RETRAINING_CONSTRAINT = True`: routing accuracy improves only via
  retrieval feedback. No gradient descent, no model fine-tuning, no
  self-training, and no model retraining.
- Routing executes on local hardware.
- No telemetry leaves the machine by default.
- JSONL outcome retrieval remains the fallback baseline.
- Qdrant vector retrieval keyed by task-signature embeddings is implemented as
  the preferred retrieval source when local Qdrant and local embeddings are
  available.

## Current Implemented Evidence

| Claim Element | File | Constant / Function |
| --- | --- | --- |
| Blending formula | `merlin/router.py` | `_final_confidence()` |
| Keyword weight | `merlin/router.py` | `KEYWORD_WEIGHT = 0.6` |
| Retrieval weight | `merlin/router.py` | `RETRIEVAL_WEIGHT = 0.4` |
| Outcome decay horizon | `merlin/router.py` | `OUTCOME_DECAY_DAYS = 30` |
| No-retraining constraint | `merlin/router.py` | `NO_RETRAINING_CONSTRAINT = True` |
| Local approved outcome retrieval | `merlin/router.py` | `_approved_outcomes()` |
| Time-decayed outcome scoring | `merlin/router.py` | `_retrieval_score()` |
| Qdrant task-signature retrieval | `merlin/router.py` | `_qdrant_approved_outcomes()` |
| Task-signature outcome write | `merlin/memory_manager.py` | `write_task_outcome_signature()` |
| Task-signature outcome search | `merlin/memory_manager.py` | `search_task_outcomes_by_signature()` |
| Local-only default | `configs/merlin/routes.yaml` | `defaults.cloud_allowed: false` |
| No default telemetry | `configs/merlin/routes.yaml` | `defaults.telemetry: disabled` |

## Current Formula

```text
C_final = (KEYWORD_WEIGHT * C_keyword) + (RETRIEVAL_WEIGHT * C_retrieval)
```

With current constants:

```text
KEYWORD_WEIGHT = 0.6
RETRIEVAL_WEIGHT = 0.4
OUTCOME_DECAY_DAYS = 30
```

The implemented retrieval score prefers approved local Qdrant task-signature
outcomes and falls back to approved local JSONL outcome records when Qdrant or
local embeddings are unavailable:

```text
weight = exp(-days_since_outcome / OUTCOME_DECAY_DAYS)
C_retrieval = sum(outcome_success * weight) / sum(weight)
```

## Prior Art Differentiation Table

| Prior Art | US/Arxiv | What It Covers | Domain | Cloud? | Retraining? | Covers This System? |
| --- | --- | --- | --- | --- | --- | --- |
| Kount | US12335276B2 | Exponential decay on fraud/network access control variables | Fraud detection | Yes | Yes | No — different domain, cloud-based, model retraining used |
| Kount | US20250274461A1 | Continuation of US12335276B2 | Fraud detection | Yes | Yes | No — same distinctions as above |
| Microsoft | US20250200475A1 | LLM generates workflow via 3-prompt method | Workflow generation | Yes | Yes | No — workflow generation, not routing; requires human prompts |
| ServiceNow | US20250265521A1 | Templates from text input via workflow pattern clusters | Workflow templating | Yes | N/A | No — templates from human-designed workflows, not routing |
| FlowMind | arxiv 2602.11782 | Execute-Summarize academic framework | Academic | N/A | N/A | No — academic only; no routing, no local constraint |

## Defensible Gap Today

No known cited reference covers all four implemented properties
simultaneously:

1. Time-decay weighting applied to AI agent task routing confidence.
2. Routing improvement via retrieval feedback only, with an explicit no-retraining
   architectural constraint.
3. Local-first execution with no default cloud telemetry.
4. Retrieval key is a local Qdrant vector embedding of the task signature, not a
   categorical rule table or route ID.

## Implementation Boundary

Qdrant task-signature retrieval is implemented as a non-blocking local
enhancement. It does not retrain models, does not call cloud APIs, does not
store raw user input in payloads, and does not replace JSONL fallback behavior.

## Revision History

| Date | Change | Author |
| --- | --- | --- |
| 2026-05-07 | Initial evidence-aligned claim record for implemented JSONL retrieval feedback routing | TheYfactora12 |
| 2026-05-08 | Governance alignment verified that Qdrant vector task-signature retrieval remains future work tracked by #89; implemented evidence remains JSONL retrieval plus `bc10616` constants and `telemetry: disabled`. | TheYfactora12 |
| 2026-05-08 | Implemented Qdrant task-signature retrieval and approved outcome signature writes in `2c05724`; JSONL remains fallback and no-retraining constraint remains active. | TheYfactora12 |
