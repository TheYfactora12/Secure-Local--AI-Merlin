# Patent Claim 4 — Retrieval Feedback Routing

**Status:** Partially implemented. Current code supports local JSONL approved
outcome retrieval with time decay. Qdrant task-signature vector retrieval is a
planned claim-hardening extension and must not be represented as implemented
until code exists.

## Hard Architectural Constraints

- `NO_RETRAINING_CONSTRAINT = True`: routing accuracy improves only via
  retrieval feedback. No gradient descent, no model fine-tuning, no
  self-training, and no model retraining.
- Routing executes on local hardware.
- No telemetry leaves the machine by default.
- JSONL outcome retrieval is the implemented baseline.
- Qdrant vector retrieval keyed by task-signature embeddings is the intended
  next implementation slice.

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
| Local-only default | `configs/merlin/routes.yaml` | `defaults.cloud_allowed: false` |

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

The implemented retrieval score uses approved local outcome records only:

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

No known cited reference covers all three implemented properties
simultaneously:

1. Time-decay weighting applied to AI agent task routing confidence.
2. Routing improvement via retrieval feedback only, with an explicit no-retraining
   architectural constraint.
3. Local-first execution with no default cloud telemetry.

## Claim-Hardening Gap

The stronger four-part gap requires implementation work before it should be used
as code evidence:

1. Time-decay weighting applied to AI agent task routing decisions.
2. Retrieval feedback only; no model retraining.
3. Local hardware execution with no cloud telemetry.
4. Retrieval key is a Qdrant vector embedding of the task signature, not a
   categorical rule or route ID.

## Required Next Implementation Issue

Complete #89, the routing claim-hardening issue, to:

- adds Qdrant task-signature vector retrieval,
- stores only hashed/redacted task metadata and local embeddings,
- preserves `NO_RETRAINING_CONSTRAINT = True`,
- keeps JSONL as fallback when Qdrant is unavailable,
- adds tests proving no cloud calls or retraining path exists,
- updates this document only after code and tests pass.

## Revision History

| Date | Change | Author |
| --- | --- | --- |
| 2026-05-07 | Initial evidence-aligned claim record for implemented JSONL retrieval feedback routing | TheYfactora12 |
