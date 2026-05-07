# Inventor Record

**Inventor:** Kevin Paul Medeiros Jr
**GitHub Username:** TheYfactora12
**Repository:** TheYfactora12/home-ai-elite
**Date of Initial Conception:** 2026-04-30 (first public commit establishing the core architecture)
**Date of Formal Inventor Record Creation:** 2026-05-07
**Jurisdiction:** United States

> **Legal Notice:** This document constitutes a contemporaneous inventor record establishing conception dates for the inventive elements described below. It is intended to support USPTO provisional and non-provisional patent filings. All architectural decisions, system design choices, claim-relevant algorithm parameters, and the choice to implement each gate, constraint, and pipeline stage as a mandatory architectural control rather than a UI advisory were made by the inventor named above. Portions of source code were written with AI coding assistance; all inventive direction, parameter selection, and system design choices were made by the inventor.

---

## AI Tool Usage Disclosure

Portions of the source code in this repository were authored with AI coding assistance (including but not limited to LLM-based code generation tools). Per USPTO guidance on AI-assisted inventions:

- All **architectural decisions** were made by the human inventor.
- All **claim-relevant algorithm parameters** (e.g., `suppression_weight = 0.15`, `token_window = 5`, blending weights `0.6`/`0.4` in `_final_confidence()`, `OUTCOME_DECAY_DAYS = 30`) were selected and validated by the human inventor.
- The choice to implement consent gates, approval pipelines, and no-retraining constraints as **mandatory architectural controls** rather than optional UI features was a deliberate inventive decision by the human inventor.
- AI tools were used as implementation assistants, not as inventors.

---

## Inventive Elements

### Element 1 — Consent-Gated Behavioral Preference Learning Pipeline

**Conception Date:** 2026-04-30
**First Committed Evidence:** Initial repository commit establishing `merlin/` module structure and `policy_engine.py` approval gate architecture.
**Related Issues:** #82, #83, #31
**Related Files:** `merlin/preference_extractor.py`, `merlin/policy_engine.py`, `configs/merlin/policy.yaml`
**Patent Candidates:** Candidate 1 (Consent-Gated Loop), Candidate 3 (Negation Suppression)

On 2026-04-30, I conceived of and implemented a system in which no behavioral preference extracted from user conversations can be stored in a persistent vector database until it has passed through: (a) a negation-aware confidence scoring function that degrades — but does not invert — confidence scores for negated preference statements, and (b) an explicit human approval gate enforced as a mandatory pipeline stage, not a UI control. I directed all key design decisions for this pipeline, including the choice to use confidence suppression rather than semantic inversion for negated statements, the specific default suppression weight of 0.15, the 5-token look-back window, and the architectural requirement that the gate be enforced at the write boundary of the vector store rather than as an advisory warning.

**Specific Technical Improvement:** This pipeline-enforced consent gate achieves a specific technical improvement — eliminating false-positive preference persistence — by requiring explicit human approval before any vector store write. This is architecturally distinct from UI-based feedback mechanisms that update preference models without a mandatory write gate.

---

### Element 2 — Retrieval-Augmented Routing with Time-Decay Outcome Weighting

**Conception Date:** 2026-04-30
**First Committed Evidence:** `merlin/router.py` — `route_task()` routing dispatch and `_final_confidence()` blending formula. `configs/merlin/routes.yaml` — `cloud_allowed: false` local-first constraint.
**Auditability Evidence:** `bc10616` — claim-relevant constants named with patent notice comments; `routes.yaml` adds `telemetry: disabled`.
**Related Issues:** #81, #83, #29
**Related Files:** `merlin/router.py`, `configs/merlin/routes.yaml`
**Patent Candidates:** Candidate 2 (Routing with Decay)

#### Currently Implemented (code matches claim as of 2026-04-30)

On 2026-04-30, I conceived of and implemented a routing method in which AI agent task routing decisions improve over time by blending real-time keyword match confidence with time-decay-weighted historical routing outcome confidence.

**Implemented formula in `_final_confidence()`:**

```
C_final = 0.6 × C_keyword + 0.4 × C_retrieval
```

where `C_retrieval` is the weighted average of approved historical outcomes for the matched route, decayed by `exp(−days_since_outcome / OUTCOME_DECAY_DAYS)` with `OUTCOME_DECAY_DAYS = 30`. Historical outcomes are stored in local JSONL files keyed by `route_id`. Routing executes entirely on local hardware; `configs/merlin/routes.yaml` enforces `cloud_allowed: false` and `telemetry: disabled`.

**Implemented architectural constraints:**
- `KEYWORD_WEIGHT = 0.6` and `RETRIEVAL_WEIGHT = 0.4` are named module-level constants in `merlin/router.py` as of `bc10616`.
- `OUTCOME_DECAY_DAYS = 30` is a named module-level constant in `merlin/router.py` as of `bc10616`; the implemented decay formula is `exp(-days_since_outcome / OUTCOME_DECAY_DAYS)`.
- `NO_RETRAINING_CONSTRAINT = True` is a named module-level constant in `merlin/router.py` as of `bc10616`. Routing accuracy improves only via JSONL outcome retrieval feedback. Zero gradient descent. Zero model retraining.
- All routing decisions are local. `cloud_allowed: false` and `telemetry: disabled` in `routes.yaml` are the current enforcement fields as of `bc10616`.

**Specific Technical Improvement:** Routing confidence improves on repeated approved task patterns without any model retraining, on hardware-constrained local devices, with full decision traceability through local JSONL outcome records rather than opaque model weights.

**Differentiation from Kount US12335276B2:** Kount's exponential decay is applied to fraud and network access control variables using cloud-based telemetry. This system applies time-decay weighting exclusively to AI agent task routing decisions on local hardware with no cloud transmission and no model retraining. The domain, architecture, purpose, and hardware constraint are all distinct.

#### Design Targets — Conceived, Not Yet Implemented

The following elements are part of the conceived invention but are **not yet present in committed code**. They are claim-hardening targets tracked in issue #81. Do not cite these as implemented evidence until the corresponding commit SHA is recorded here.

No remaining design targets for the implemented JSONL outcome-feedback routing baseline. Qdrant vector retrieval of task signatures is a separate later milestone tracked by #89, not implemented evidence for the current claim baseline.

**Patent filing note:** Claims based on currently implemented code (JSONL outcome feedback, time-decay weighting, local-only constraint, no-telemetry config field, no-retraining invariant, and `_final_confidence()` blending formula) are supportable today. Claims requiring Qdrant vector retrieval must await implementation before the nonprovisional is filed. The provisional may describe Qdrant vector retrieval as conceived but not yet implemented.

---

### Element 3 — Negation-Aware Confidence Suppression Function

**Conception Date:** 2026-05-07
**First Committed Evidence:** `merlin/preference_extractor.py` commit dab3271 (2026-05-07) adding `negation_suppressed_confidence()` with `NEGATION_SUPPRESSION_WEIGHT = 0.15` and `NEGATION_TOKEN_WINDOW = 5` as named module-level constants.
**Related Issues:** #82, #83
**Related Files:** `merlin/preference_extractor.py`
**Patent Candidates:** Candidate 1 (Claim 3)

On 2026-05-07, I directed the design of a named, testable negation suppression function — `negation_suppressed_confidence()` — that scans a configurable token window preceding a candidate preference term for negation markers (e.g., "don't", "never", "avoid", "stop") and, upon detection, multiplies the raw confidence score by a configurable suppression weight (default: 0.15) rather than inverting the semantic meaning of the preference. I selected the specific default values — `suppression_weight = 0.15` and `token_window = 5` — and the architectural decision that suppression degrades confidence while preserving the candidate in the staging queue for human review. This is the implementation of Patent Provisional A, Claim 3.

**Differentiation from negation-as-inversion approaches:** Standard NLP negation handling inverts the semantic polarity of a statement. This function instead reduces extraction confidence and defers the ambiguous case to human review, which is a distinct and specific technical improvement over silent semantic inversion.

---

### Element 4 — Four-Stage Session Reflection Pipeline with Human Promotion Gate

**Conception Date:** 2026-04-30
**First Committed Evidence:** `merlin/session_reflector.py` establishing the four-stage pipeline architecture.
**Related Issues:** #83, #31, #32
**Related Files:** `merlin/session_reflector.py`, `merlin/policy_engine.py`
**Patent Candidates:** Candidate 4 (Session Reflector)

On 2026-04-30, I conceived of and implemented a four-stage behavioral safety pipeline — extraction → candidate queue → human review → vector store write — in which no behavioral preference can propagate to the AI routing layer without traversing all four stages. I directed the key design decision that the staging queue is physically isolated from the live routing layer, such that a candidate preference cannot influence routing behavior until it has received an explicit human promotion token. This is architecturally distinct from real-time in-session implicit intent detection, which does not provide a staging queue or mandatory human promotion gate.

**Specific Technical Improvement:** This pipeline achieves a concrete technical improvement to AI behavioral safety and auditability: the four-stage traversal requirement provides a measurable guarantee that no unreviewed behavioral signal can modify system routing behavior.

---

### Element 5 — MerlinFlow: Self-Generating Workflow Engine via Execute-Summarize Pattern

**Conception Date:** 2026-05-07
**First Committed Evidence:** Issue #84 filed 2026-05-07 specifying the MerlinFlow architecture, `workflow_synthesizer.py`, causal pruning algorithm, and prior art differentiation table.
**Related Issues:** #84, #83, #81, #35
**Related Files:** `merlin/workflow_synthesizer.py` (to be created), `merlin/workflow_store.py` (to be created), `configs/merlin/policy.yaml` (`workflow_write`, `workflow_execute` gates)
**Patent Candidates:** Candidate 5 (MerlinFlow)

On 2026-05-07, I conceived of a system in which an AI agent observes its own LLM execution traces and, via causal pruning and structural pattern extraction, proposes reusable structured workflow definitions — stored only after passing through the existing human approval gate (`policy_engine.py`, `workflow_write` gate) and never transmitted outside the local device. I directed all key design decisions, including:

1. **Causal pruning:** The `synthesize_workflow_from_trace()` function removes steps whose `tool_name` contains markers in `CAUSAL_PRUNE_MARKERS` ("retry", "debug", "fallback", "error_handle") before proposing the workflow. This is the primary structural distinction from FlowMind (arxiv 2602.11782), which records full traces without pruning.
2. **Type-only schema extraction:** Input and output schemas capture Python type names only (`str`, `int`, `list`, `dict`) — no user content, credentials, or personal data. This is enforced structurally at synthesis time, not by post-processing redaction.
3. **Workflow confidence decay:** Stored workflows use `time_decay_weight()` (from Element 2). Confidence decaying below threshold downgrades the workflow to "pending re-approval" rather than deleting it, preventing stale workflows from executing without supervision.
4. **Local-only hard constraint:** `ProposedWorkflow.local_only = True` is a struct-level constant, not a configuration option.
5. **Approval-required hard constraint:** `ProposedWorkflow.requires_approval = True` is a struct-level constant. No workflow can execute without an `approval_token` from the policy engine write gate.

**Differentiation from prior art:**

| Prior Art | What It Covers | What It Does NOT Cover |
|-----------|---------------|------------------------|
| Microsoft US20250200475A1 | LLM generates workflow via 3-prompt method | Requires human-supplied prompts; no self-observation from agent trace |
| ServiceNow US20250265521A1 | Templates from text input via workflow pattern clusters | Templates built from human-designed workflows, not agent execution traces |
| Cumulus Digital US20250156783A1 | LLM workflow from schema-constrained prompts | Cloud-based; no local privacy constraint; no approval gate on persistence |
| UiPath US12204295B2 | RPA digital assistant observes user actions | Observes human actions, not agent execution traces |
| FlowMind arxiv 2602.11782 | Execute-Summarize academic framework | Academic only; no local privacy constraint; no consent gate; not filed |

**The defensible gap:** No filed patent covers an AI agent that (a) observes its own LLM execution traces, (b) proposes a reusable workflow specification via causal pruning of those traces, (c) stores that workflow only after human consent via an existing approval gate, and (d) does all of this locally with no cloud training or transmission.

---

## Filing Strategy Notes

- **Provisional A** (earliest priority): Covers Elements 1, 2, 3, 4. Target filing date: as soon as possible.
- **Provisional B or CIP**: Covers Element 5 (MerlinFlow). Can be filed as continuation-in-part of Provisional A or as standalone Provisional B.
- **Alice §101 readiness**: All elements include explicit technical improvement language per USPTO 2019 Revised Guidance and 2025 Director Memorandum. See issue #83 for per-element Alice Step 2B language.
- **SMED readiness**: Inventor should be prepared to submit a Subject Matter Eligibility Declaration confirming the claimed limitations cannot practically be performed in the human mind.
- **Prior art citations to include in nonprovisional spec:** Kount US12335276B2, Kount US20250274461A1, Microsoft US20250200475A1, ServiceNow US20250265521A1, Cumulus Digital US20250156783A1, UiPath US12204295B2, FlowMind arxiv 2602.11782.
- **Claim hardening required before nonprovisional for Element 2:** Constants and local telemetry fields were added in `bc10616`. Qdrant vector retrieval is a separate, later milestone. See issue #89.

---

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2026-05-07 | Initial creation — all five elements documented; conception dates established | TheYfactora12 |
| 2026-05-07 | Set inventor legal name: Kevin Paul Medeiros Jr | TheYfactora12 |
| 2026-05-07 | Corrected Element 2: split implemented vs. design target; removed overclaimed constants (NO_RETRAINING_CONSTRAINT, KEYWORD_WEIGHT, LAMBDA_DECAY, Qdrant retrieval); JSONL outcome retrieval confirmed as implemented baseline. Validated by external AI review. | TheYfactora12 |
| 2026-05-07 | Updated AI Tool Disclosure to remove reference to non-existent named constants; updated Element 3 first-committed-evidence to cite commit dab3271 | TheYfactora12 |
| 2026-05-07 | Promoted Element 2 constants and telemetry field to implemented evidence after commit bc10616; Qdrant vector retrieval remains separate future work tracked by #89. | TheYfactora12 |
