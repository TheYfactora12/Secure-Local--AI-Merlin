# Inventor Record — merlin-ai

**Document Version:** 2.1
**Inventor:** Kevin Paul Medeiros Jr
**GitHub Username:** TheYfactora12
**Repository:** [TheYfactora12/Secure-Local--AI-Merlin](https://github.com/TheYfactora12/Secure-Local--AI-Merlin)
**Jurisdiction:** United States (USPTO)
**Date of Initial Conception:** 2026-04-30 (first public commit establishing core architecture)
**Date of Formal Inventor Record Creation:** 2026-05-07
**Date of Last Revision:** 2026-05-08

---

> **Legal Notice:** This document constitutes a contemporaneous inventor record under 35 U.S.C. § 111 establishing conception and reduction-to-practice dates for the inventive elements described below. It is intended to support USPTO provisional patent applications (35 U.S.C. § 111(b)) and non-provisional utility patent applications. All architectural decisions, system design choices, claim-relevant algorithm parameters, and the choice to implement each gate, constraint, and pipeline stage as a mandatory architectural control — rather than a UI advisory — were made by the inventor named above. Portions of source code were written with AI coding assistance; all inventive direction, parameter selection, and system design choices were made by the human inventor. Per the USPTO's November 28, 2025 Revised Inventorship Guidance for AI-Assisted Inventions, inventorship is determined solely by human conception under traditional Federal Circuit precedent.

> **Witness Notice:** To maximize corroborative evidentiary weight under Federal Circuit precedent (*Mahurkar v. C.R. Bard, Inc.*, 79 F.3d 1572 (Fed. Cir. 1996)), this record should be disclosed to and signed by at least one non-inventor witness who understands the technology. Witness signature block is provided at the end of this document.

---

## Table of Contents

1. [AI Tool Usage Disclosure](#ai-tool-usage-disclosure)
2. [Inventive Elements Summary](#inventive-elements-summary)
3. [Element 1 — Consent-Gated Behavioral Preference Learning Pipeline](#element-1)
4. [Element 2 — Retrieval-Augmented Routing with Time-Decay Outcome Weighting](#element-2)
5. [Element 3 — Negation-Aware Confidence Suppression Function](#element-3)
6. [Element 4 — Four-Stage Session Reflection Pipeline with Human Promotion Gate](#element-4)
7. [Element 5 — MerlinFlow: Self-Generating Workflow Engine via Execute-Summarize Pattern](#element-5)
8. [Use Case Claim Charts](#use-case-claim-charts)
9. [Prior Art Search Record](#prior-art-search-record)
10. [Alice § 101 Eligibility Defense Summary](#alice-101-eligibility-defense)
11. [Filing Strategy and Provisional Timeline](#filing-strategy)
12. [Witness Signature Block](#witness-signature-block)
13. [Revision History](#revision-history)

---

## AI Tool Usage Disclosure

Portions of the source code in this repository were authored with AI coding assistance (including but not limited to LLM-based code generation tools). Per the USPTO's November 28, 2025 Revised Inventorship Guidance for AI-Assisted Inventions (rescinding the February 2024 guidance in its entirety):

- All **architectural decisions** were made by the human inventor.
- All **claim-relevant algorithm parameters** (e.g., `suppression_weight = 0.15`, `token_window = 5`, blending weights `KEYWORD_WEIGHT = 0.6` / `RETRIEVAL_WEIGHT = 0.4` in `_final_confidence()`, `OUTCOME_DECAY_DAYS = 30`) were selected and validated by the human inventor.
- The choice to implement consent gates, approval pipelines, and no-retraining constraints as **mandatory architectural controls** rather than optional UI features was a deliberate inventive decision by the human inventor.
- AI tools were used as implementation assistants, not as inventors. No AI system is named as a co-inventor.
- Under the USPTO's November 2025 guidance, the controlling inventorship standard is: *"the ability of the inventor to describe the invention with particularity"* (traditional Federal Circuit conception standard). This inventor can so describe each element herein.

---

## Inventive Elements Summary

| # | Element | Conception Date | Implemented | Patent Candidate | Key Files |
|---|---------|----------------|-------------|-----------------|-----------|
| 1 | Consent-Gated Behavioral Preference Learning Pipeline | 2026-04-30 | ✅ Yes | Provisional A, Claims 1–2 | `preference_extractor.py`, `policy_engine.py` |
| 2 | Retrieval-Augmented Routing w/ Time-Decay Outcome Weighting | 2026-04-30 | ✅ Yes | Provisional A, Claim 4 | `router.py`, `routes.yaml` |
| 3 | Negation-Aware Confidence Suppression Function | 2026-05-07 | ✅ Yes | Provisional A, Claim 3 | `preference_extractor.py` |
| 4 | Four-Stage Session Reflection Pipeline w/ Human Promotion Gate | 2026-04-30 | ✅ Yes | Provisional A, Claims 1–2 (system claim) | `session_reflector.py`, `policy_engine.py` |
| 5 | MerlinFlow: Self-Generating Workflow Engine via Execute-Summarize | 2026-05-07 | 🔲 Spec filed (Issue #84) | Provisional B / CIP | `workflow_synthesizer.py` (pending) |

---

## Element 1 — Consent-Gated Behavioral Preference Learning Pipeline {#element-1}

**Conception Date:** 2026-04-30
**Reduction to Practice Date:** 2026-04-30 (constructive — first commit with architecture; actual reduction to practice upon passing test suite)
**First Committed Evidence:** Initial repository commit establishing `merlin/` module structure and `policy_engine.py` approval gate architecture.
**Related Issues:** #82, #83, #31
**Related Files:** `merlin/preference_extractor.py`, `merlin/policy_engine.py`, `configs/merlin/policy.yaml`
**Patent Candidates:** Provisional A — Claims 1 and 2

### Conception Narrative

On 2026-04-30, the inventor conceived of and implemented a system in which no behavioral preference extracted from user conversations can be stored in a persistent vector database until it has passed through: (a) a negation-aware confidence scoring function that degrades — but does not invert — confidence scores for negated preference statements, and (b) an explicit human approval gate enforced as a mandatory pipeline stage, not a UI control.

Inventive direction included:
- The choice to use confidence **suppression** rather than semantic inversion for negated statements
- The specific default suppression weight of **0.15**
- The **5-token look-back window** for negation detection
- The architectural requirement that the gate be enforced at the **write boundary of the vector store** rather than as an advisory warning
- The decision to queue suppressed candidates for human review rather than discard them

### Specific Technical Improvement

This pipeline-enforced consent gate eliminates false-positive preference persistence by requiring explicit human approval before any vector store write. This is architecturally distinct from UI-based feedback mechanisms that update preference models without a mandatory write gate.

### Use Cases (Claim-Linking)

| Use Case | User Action | System Response | Claim Element |
|----------|-------------|-----------------|---------------|
| **UC-1A** — Normal preference extraction | User states "I prefer dark mode" | System scores confidence > threshold, queues for approval | Extraction stage of four-stage pipeline |
| **UC-1B** — Negated preference | User states "I don't want email notifications" | System scores confidence × 0.15, flags as negated, queues for human review rather than discarding | Negation suppression gate (Claim 3 overlap) |
| **UC-1C** — Human approval | Operator reviews queued candidate, approves | System writes preference to Qdrant vector store | Mandatory write gate (Claim 2 core) |
| **UC-1D** — Human rejection | Operator rejects candidate | Candidate discarded; no vector store write | Mandatory write gate (Claim 2 core) |
| **UC-1E** — Bypass attempt | Code attempts direct vector write without approval token | Gate enforces rejection at write boundary | Architectural control (vs. UI advisory) |

---

## Element 2 — Retrieval-Augmented Routing with Time-Decay Outcome Weighting {#element-2}

**Conception Date:** 2026-04-30
**Reduction to Practice Date:** 2026-04-30 (constructive); Qdrant task-signature retrieval: 2026-05-08 (commit `29035ed`)
**First Committed Evidence:** `merlin/router.py` — `route_task()` dispatch and `_final_confidence()` blending formula. `configs/merlin/routes.yaml` — `cloud_allowed: false` local-first constraint.
**Auditability Commits:** `bc10616` (claim-relevant constants with patent notice comments; `telemetry: disabled` added); `29035ed` (Qdrant task-signature vector retrieval and approved outcome signature writes)
**Related Issues:** #81, #83, #29
**Related Files:** `merlin/router.py`, `configs/merlin/routes.yaml`
**Patent Candidates:** Provisional A — Claim 4

### Conception Narrative

On 2026-04-30, the inventor conceived of a routing method in which AI agent task routing decisions improve over time by blending real-time keyword match confidence with time-decay-weighted historical routing outcome confidence — without any model retraining.

### Implemented Formula

```
C_final = KEYWORD_WEIGHT × C_keyword + RETRIEVAL_WEIGHT × C_retrieval
```

where:
- `KEYWORD_WEIGHT = 0.6` (named module-level constant, commit `bc10616`)
- `RETRIEVAL_WEIGHT = 0.4` (named module-level constant, commit `bc10616`)
- `C_retrieval` = weighted average of approved historical outcomes, decayed by `exp(−days_since_outcome / OUTCOME_DECAY_DAYS)`
- `OUTCOME_DECAY_DAYS = 30` (named module-level constant, commit `bc10616`)
- `NO_RETRAINING_CONSTRAINT = True` (named module-level constant, commit `bc10616`)

### Implemented Architectural Constraints

- `cloud_allowed: false` in `routes.yaml` — all routing is local hardware only
- `telemetry: disabled` in `routes.yaml` — no telemetry transmitted externally
- Qdrant task-signature vector retrieval implemented as of commit `29035ed`
- Approved task outcome signature writes implemented as of `29035ed`; raw task signature is not stored in the Qdrant payload — only hashed/redacted operational metadata

### Use Cases (Claim-Linking)

| Use Case | Scenario | System Behavior | Claim Element |
|----------|----------|-----------------|---------------|
| **UC-2A** — First-time task | New task type, no historical outcomes | Routes by keyword confidence only (`C_final = 0.6 × C_keyword`) | Blending formula baseline |
| **UC-2B** — Repeated approved task | Same task type, 5 approved outcomes on record | `C_retrieval` computed from decay-weighted outcomes; routing confidence improves | Time-decay outcome weighting (core claim) |
| **UC-2C** — Stale outcomes | Last approved outcome 45 days ago | Exponential decay reduces `C_retrieval` contribution — router reverts toward keyword-only weighting | Decay function prevents stale signal dominance |
| **UC-2D** — Cloud-blocked environment | Routing attempted with `cloud_allowed: false` | All routing executes locally; no external API calls | Local-only hard constraint |
| **UC-2E** — Outcome rejection | Operator rejects a routing outcome | Rejected outcome excluded from `C_retrieval` computation | Consent gate applies to outcome feedback loop |
| **UC-2F** — Qdrant unavailable | Qdrant service down | Router falls back to JSONL outcome records | JSONL fallback implementation |

### Differentiation from Kount US12335276B2

Kount's exponential decay is applied to fraud and network access control variables using cloud-based telemetry. This system applies time-decay weighting exclusively to AI agent task routing decisions on local hardware with no cloud transmission and no model retraining. Domain, architecture, purpose, and hardware constraint are all distinct.

---

## Element 3 — Negation-Aware Confidence Suppression Function {#element-3}

**Conception Date:** 2026-05-07
**Reduction to Practice Date:** 2026-05-07 (actual — function committed in `dab3271`)
**First Committed Evidence:** `merlin/preference_extractor.py` commit `dab3271` (2026-05-07) adding `negation_suppressed_confidence()` with `NEGATION_SUPPRESSION_WEIGHT = 0.15` and `NEGATION_TOKEN_WINDOW = 5` as named module-level constants.
**Related Issues:** #82, #83
**Related Files:** `merlin/preference_extractor.py`
**Patent Candidates:** Provisional A — Claim 3

### Conception Narrative

On 2026-05-07, the inventor directed the design of a named, testable negation suppression function — `negation_suppressed_confidence()` — that scans a configurable token window preceding a candidate preference term for negation markers (e.g., "don't", "never", "avoid", "stop") and, upon detection, multiplies the raw confidence score by a configurable suppression weight (default: **0.15**) rather than inverting the semantic meaning of the preference.

Key inventive decisions by the inventor:
- `suppression_weight = 0.15` (specific numeric selection)
- `token_window = 5` (specific window size selection)
- Architectural decision: suppression **degrades confidence** while preserving the candidate in staging queue for human review, rather than discarding or inverting

### Differentiation from Negation-as-Inversion Approaches

Standard NLP negation handling inverts the semantic polarity of a statement (e.g., "don't like X" → store preference against X). This function instead reduces extraction confidence and defers the ambiguous case to human review — a distinct technical improvement over silent semantic inversion, which can generate incorrect behavioral signals from misinterpreted negation.

### Use Cases (Claim-Linking)

| Use Case | Input Statement | System Behavior | Claim Element |
|----------|----------------|-----------------|---------------|
| **UC-3A** — Direct negation | "I never want notifications" | Token window scans 5 tokens before "notifications", detects "never", applies `× 0.15` to confidence | Core suppression function |
| **UC-3B** — Contraction negation | "Don't send me emails" | "Don't" detected in window, suppression applied | Negation marker set |
| **UC-3C** — No negation | "I prefer dark mode" | No negation marker found in window; full confidence passed to staging queue | Function confirms clean extraction |
| **UC-3D** — Ambiguous negation | "Stop suggesting that option" | "Stop" in negation marker set triggers suppression; candidate queued with low confidence for human review | Human-in-the-loop safety net |
| **UC-3E** — Window boundary | Negation word is 6 tokens before preference term | Window = 5 does NOT fire; full confidence used | Window boundary constraint |

---

## Element 4 — Four-Stage Session Reflection Pipeline with Human Promotion Gate {#element-4}

**Conception Date:** 2026-04-30
**Reduction to Practice Date:** 2026-04-30 (constructive — `session_reflector.py` establishes pipeline architecture)
**First Committed Evidence:** `merlin/session_reflector.py` establishing the four-stage pipeline architecture.
**Related Issues:** #83, #31, #32
**Related Files:** `merlin/session_reflector.py`, `merlin/policy_engine.py`
**Patent Candidates:** Provisional A — Claims 1–2 (system claim)

### Conception Narrative

On 2026-04-30, the inventor conceived of and implemented a four-stage behavioral safety pipeline — **(1) extraction → (2) candidate queue → (3) human review → (4) vector store write** — in which no behavioral preference can propagate to the AI routing layer without traversing all four stages.

Key inventive decisions by the inventor:
- The staging queue is **physically isolated** from the live routing layer
- No candidate preference can influence routing behavior until it receives an explicit **human promotion token** from `policy_engine.py`
- The pipeline enforces this traversal at the architectural level, not as a configurable option

### Specific Technical Improvement

The four-stage traversal requirement provides a measurable guarantee that no unreviewed behavioral signal can modify system routing behavior. This is architecturally distinct from real-time in-session implicit intent detection, which does not provide a staging queue or mandatory human promotion gate.

### Use Cases (Claim-Linking)

| Use Case | Scenario | System Behavior | Claim Element |
|----------|----------|-----------------|---------------|
| **UC-4A** — End-of-session reflection | User session ends | `session_reflector.py` triggers extraction stage | Stage 1 trigger |
| **UC-4B** — Candidate queuing | 3 candidate preferences extracted | All 3 placed in isolated staging queue; routing layer unaffected | Stage 2 isolation |
| **UC-4C** — Partial approval | Operator approves 2 of 3 candidates | Only 2 approved preferences write to vector store; 1 rejected candidate discarded | Stage 3 → Stage 4 gate |
| **UC-4D** — Session restart before review | New session begins before operator reviews | Old candidates remain in queue; routing layer continues using only previously approved preferences | Physical isolation enforced |
| **UC-4E** — Audit trail | Compliance officer requests evidence of a past routing decision | JSONL records show which approved preferences contributed to routing; full four-stage provenance traceable | Auditability as technical benefit |

---

## Element 5 — MerlinFlow: Self-Generating Workflow Engine via Execute-Summarize Pattern {#element-5}

**Conception Date:** 2026-05-07
**Reduction to Practice:** 🔲 Not yet implemented — specification filed as Issue #84 (2026-05-07). Reduction to practice target: upon completion of `merlin/workflow_synthesizer.py`.
**First Committed Evidence:** Issue #84 filed 2026-05-07, specifying the MerlinFlow architecture, `workflow_synthesizer.py`, causal pruning algorithm, and prior art differentiation table.
**Related Issues:** #84, #83, #81, #35
**Related Files (pending creation):** `merlin/workflow_synthesizer.py`, `merlin/workflow_store.py`, `configs/merlin/policy.yaml` (add `workflow_write`, `workflow_execute` gates)
**Patent Candidates:** Provisional B (standalone) or CIP of Provisional A

### Conception Narrative

On 2026-05-07, the inventor conceived of a system in which an AI agent observes its own LLM execution traces and, via causal pruning and structural pattern extraction, proposes reusable structured workflow definitions — stored only after passing through the existing human approval gate (`policy_engine.py`, `workflow_write` gate) and never transmitted outside the local device.

Key inventive decisions by the inventor:
1. **Causal pruning:** `synthesize_workflow_from_trace()` removes steps whose `tool_name` contains markers in `CAUSAL_PRUNE_MARKERS` ("retry", "debug", "fallback", "error_handle") before proposing the workflow. Primary structural distinction from FlowMind (arxiv 2602.11782), which records full traces without pruning.
2. **Type-only schema extraction:** Input/output schemas capture Python type names only (`str`, `int`, `list`, `dict`) — no user content, credentials, or personal data. Enforced structurally at synthesis time, not by post-processing redaction.
3. **Workflow confidence decay:** Stored workflows use `time_decay_weight()` (from Element 2). Confidence decaying below threshold downgrades the workflow to "pending re-approval" rather than deleting it.
4. **Local-only hard constraint:** `ProposedWorkflow.local_only = True` is a struct-level constant, not a configuration option.
5. **Approval-required hard constraint:** `ProposedWorkflow.requires_approval = True` is a struct-level constant. No workflow executes without an `approval_token` from the policy engine write gate.

### Use Cases (Claim-Linking)

| Use Case | Scenario | System Behavior | Claim Element |
|----------|----------|-----------------|---------------|
| **UC-5A** — First observation | Agent completes multi-step file analysis task for first time | `workflow_synthesizer.py` observes execution trace | Execute-Summarize observation trigger |
| **UC-5B** — Causal pruning | Trace includes 2 retry steps and 1 error handler | `CAUSAL_PRUNE_MARKERS` removes retry/error steps; 5-step clean workflow proposed | Causal pruning (core novelty) |
| **UC-5C** — Schema extraction | Trace steps use file paths (strings) and token counts (ints) | Schema captures `{input: str, output: int}` — no file paths or user data in payload | Type-only schema extraction (privacy guarantee) |
| **UC-5D** — Approval gate | System proposes workflow to operator | No execution until `approval_token` from `policy_engine.py` write gate is received | Mandatory approval constraint |
| **UC-5E** — Stale workflow | Approved workflow last used 90 days ago | Decay function downgrades to "pending re-approval"; cannot auto-execute | Workflow confidence decay |
| **UC-5F** — Workflow reuse | Agent encounters same task type again | Approved workflow retrieved; route dispatched via workflow definition rather than ad-hoc LLM generation | Reuse loop (efficiency improvement) |
| **UC-5G** — Cloud block | Workflow proposes API call to external service | `local_only = True` struct constant blocks external transmission at synthesis time | Local-only hard constraint |

### Prior Art Differentiation Table

| Prior Art | What It Covers | What It Does NOT Cover |
|-----------|---------------|------------------------|
| Microsoft US20250200475A1 | LLM generates workflow via 3-prompt method | Requires human-supplied prompts; no self-observation from agent trace |
| ServiceNow US20250265521A1 | Templates from text input via workflow pattern clusters | Templates built from human-designed workflows, not agent execution traces |
| Cumulus Digital US20250156783A1 | LLM workflow from schema-constrained prompts | Cloud-based; no local privacy constraint; no approval gate on persistence |
| UiPath US12204295B2 | RPA digital assistant observes user actions | Observes human actions, not agent execution traces |
| FlowMind arxiv 2602.11782 | Execute-Summarize academic framework | Academic only; no local privacy constraint; no consent gate; not filed |

**The defensible gap:** No filed patent covers an AI agent that (a) observes its own LLM execution traces, (b) proposes a reusable workflow specification via **causal pruning** of those traces, (c) stores that workflow only after human consent via an existing approval gate, and (d) does all of this locally with no cloud training or transmission.

---

## Use Case Claim Charts {#use-case-claim-charts}

This section provides cross-element system-level claim charts for the anticipated independent claims in Provisional A.

### System Claim S-1: End-to-End Preference Learning with Consent Gate

> *A computer-implemented system for behavioral preference learning in an AI assistant, comprising: (a) a preference extraction module configured to extract candidate behavioral preferences from conversation transcripts; (b) a negation-aware confidence scoring function configured to detect negation markers within a configurable token window and reduce — without inverting — the confidence score of candidate preferences associated with negated statements; (c) a human approval gate enforced as a mandatory pipeline stage at the write boundary of a local vector database; and (d) a local vector database configured to accept preference writes only upon receipt of an explicit approval token from the approval gate.*

| Claim Element | Source | Commit Evidence | Issue |
|---------------|--------|-----------------|-------|
| (a) Preference extraction module | `preference_extractor.py` | First commit 2026-04-30 | #82 |
| (b) Negation-aware confidence scoring | `negation_suppressed_confidence()` | `dab3271` 2026-05-07 | #82 |
| (c) Human approval gate at write boundary | `policy_engine.py` | First commit 2026-04-30 | #83 |
| (d) Local vector database with gate enforcement | Qdrant local instance, `routes.yaml: cloud_allowed: false` | `bc10616`, `29035ed` | #29 |

### Method Claim M-1: Routing with Time-Decay Outcome Weighting

> *A method for routing AI agent tasks in a hardware-constrained local environment, comprising: (a) computing a keyword match confidence score for an incoming task; (b) retrieving historical routing outcome records for the matched route from a local data store; (c) computing a decay-weighted retrieval confidence score by applying an exponential time-decay function with a configurable decay period to each historical outcome; (d) computing a final routing confidence score as a weighted sum of the keyword match confidence and the decay-weighted retrieval confidence; (e) selecting a routing destination based on the final routing confidence score; and (f) storing the routing outcome locally without transmitting task data to any external service.*

| Claim Element | Source | Commit Evidence | Issue |
|---------------|--------|-----------------|-------|
| (a) Keyword match confidence | `route_task()` in `router.py` | First commit 2026-04-30 | #81 |
| (b) Historical outcome retrieval | JSONL records + Qdrant | `29035ed` 2026-05-08 | #89 |
| (c) Exponential decay function | `exp(-days/OUTCOME_DECAY_DAYS)` in `router.py` | `bc10616` 2026-05-07 | #81 |
| (d) Weighted blending formula | `_final_confidence()`: `0.6 × Ck + 0.4 × Cr` | `bc10616` 2026-05-07 | #81 |
| (e) Routing destination selection | `route_task()` dispatch | First commit 2026-04-30 | #29 |
| (f) Local-only storage, no external transmission | `cloud_allowed: false`, `telemetry: disabled` in `routes.yaml` | `bc10616` 2026-05-07 | #29 |

---

## Prior Art Search Record {#prior-art-search-record}

Documenting prior art searches conducted by the inventor supports USPTO disclosure obligations and strengthens the prosecution record.

### Patents Searched and Distinguished

| Patent / Publication | Title | Distinguishing Factor |
|---------------------|-------|----------------------|
| Kount US12335276B2 | Fraud Detection with Exponential Decay | Decay applied to fraud/access control variables; cloud-based; not AI routing |
| Kount US20250274461A1 | Network Access Control with Decay | Cloud-based telemetry; not local hardware AI routing |
| Microsoft US20250200475A1 | LLM Workflow Generation (3-Prompt) | Requires human-supplied prompts; no agent self-observation |
| ServiceNow US20250265521A1 | Workflow Templates from Text Input | Human-designed workflow templates; not agent trace synthesis |
| Cumulus Digital US20250156783A1 | LLM Workflow from Schema-Constrained Prompts | Cloud-based; no consent gate; no local constraint |
| UiPath US12204295B2 | RPA Digital Assistant Observing User Actions | Observes human actions, not agent execution traces |

### Non-Patent Literature Searched and Distinguished

| Reference | Source | Distinguishing Factor |
|-----------|--------|-----------------------|
| FlowMind Execute-Summarize | arxiv 2602.11782 | Academic; no local privacy constraint; no consent gate; not filed |
| LangGraph workflow documentation | LangChain docs | Requires explicit developer-defined workflow graphs; no self-synthesis from trace |
| AutoGen framework | Microsoft Research | Multi-agent orchestration; no causal pruning; no consent gate on persistence |

### Search Databases Used

- USPTO Patent Full-Text Database (patents.google.com)
- Google Patents
- arXiv (cs.AI, cs.SE)
- Semantic Scholar
- Searches conducted: 2026-04-30 and 2026-05-07

---

## Alice § 101 Eligibility Defense Summary {#alice-101-eligibility-defense}

Per the USPTO's August 2025 Director Memorandum, November 2025 Revised Inventorship Guidance, and the September 2025 *Ex parte Desjardins* precedential decision (improvements to machine learning model functioning can constitute practical applications under § 101):

### Per-Element Alice Step 2B Language

| Element | Abstract Idea Risk | Step 2A Practical Application | Step 2B Inventive Concept |
|---------|-------------------|-------------------------------|---------------------------|
| **1** — Consent-Gated Pipeline | "Collecting and storing user preferences" | Enforces consent gate as mandatory architectural control at vector store write boundary — cannot be practically performed in the human mind | Specific technical improvement: eliminates false-positive preference persistence via pipeline-enforced write gate, not mere UI advisory |
| **2** — Time-Decay Routing | "Routing based on historical data" | Implements routing on hardware-constrained local device with specific decay formula and named constants — all computationally specific | Technical improvement: routing accuracy improves on repeated patterns without model retraining; `NO_RETRAINING_CONSTRAINT = True` is a specific architectural limitation |
| **3** — Negation Suppression | "Adjusting confidence based on negation" | Applied to AI preference extraction with specific numeric parameters (0.15, window=5) on a specific data structure | Technical improvement: reduces false positive preference writes caused by misinterpreted negated statements; specific implementation not performable mentally |
| **4** — Four-Stage Pipeline | "Multi-stage review process" | Pipeline physically isolates staging queue from live routing layer — a structural, computational implementation | Technical improvement: provides measurable guarantee (audit trail in JSONL) that no unreviewed signal modifies routing behavior |
| **5** — MerlinFlow | "Generating workflows from observations" | Causal pruning algorithm operates on execution trace data structures; type-only schema extraction enforced at synthesis time; all on local hardware | Technical improvement: causal pruning removes non-reproducible steps from trace, yielding reusable workflows where prior art yields non-deterministic full traces |

### SMED Readiness Statement

The inventor is prepared to submit a Subject Matter Eligibility Declaration confirming that the claimed limitations of each element above cannot practically be performed in the human mind:
- The negation suppression function operates on tokenized NLP data structures with millisecond precision at scale
- The decay-weighted blending formula operates on timestamped outcome records across concurrent task routing decisions
- The causal pruning algorithm operates on structured execution trace objects with defined field schemas
- None of these operations are feasible for a human to perform at the speed and scale required by the claimed system

---

## Filing Strategy and Provisional Timeline {#filing-strategy}

### Recommended Filing Sequence

| Step | Action | Target Date | Priority |
|------|--------|-------------|----------|
| **1** | File **Provisional A** — covers Elements 1, 2, 3, 4 | **ASAP** — every day of delay is a day a competitor can file first | 🔴 Critical |
| **2** | Witness signs this inventor record | Within 7 days | 🔴 Critical for corroboration |
| **3** | Begin `workflow_synthesizer.py` implementation (Element 5) | Within 30 days | 🟡 High |
| **4** | File **Provisional B** — covers Element 5 (MerlinFlow) | Within 60 days, or as CIP of Provisional A | 🟡 High |
| **5** | File **Non-Provisional A** (based on Provisional A) | Within 12 months of Provisional A filing date | 🟠 Required to preserve provisional priority |

### Prior Art Citations to Include in Nonprovisional Specification

- Kount US12335276B2
- Kount US20250274461A1
- Microsoft US20250200475A1
- ServiceNow US20250265521A1
- Cumulus Digital US20250156783A1
- UiPath US12204295B2
- FlowMind arxiv 2602.11782

### Key Risk: Public Disclosure Grace Period

Under 35 U.S.C. § 102(b)(1), the inventor's own public disclosures (including this public GitHub repository) cannot be used as prior art against the inventor if a patent application is filed within **12 months** of the first public disclosure. The first public commit was **2026-04-30**. Provisional A must be filed **no later than 2027-04-30** to preserve this grace period. **Earlier filing is strongly preferred.**

### USPTO Fee Note (2026)

Micro-entity status (37 C.F.R. § 1.29) reduces USPTO provisional filing fees by 80%. Verify current fee schedule at [USPTO Fee Schedule](https://www.uspto.gov/learning-and-resources/fees-and-payment/uspto-fee-schedule).

---

## Witness Signature Block {#witness-signature-block}

Per Federal Circuit precedent (*Mahurkar v. C.R. Bard, Inc.*, 79 F.3d 1572 (Fed. Cir. 1996)), inventor records are strengthened by the signature of at least one non-inventor witness who understood the invention at the time of conception.

---

**Witness Declaration**

I, the undersigned, am not a co-inventor of the inventive elements described in this document. I have read and understood the inventive elements described above as of the date of my signature below, and I understand the technology as described herein.

**Witness Full Legal Name:** ___________________________________

**Witness Title / Relationship to Inventor:** ___________________________________

**Date Reviewed:** ___________________________________

**Signature:** ___________________________________

**Contact (optional, for future corroboration):** ___________________________________

---

*A second witness signature is recommended for maximum evidentiary weight.*

**Witness 2 Full Legal Name:** ___________________________________

**Witness 2 Title / Relationship to Inventor:** ___________________________________

**Date Reviewed:** ___________________________________

**Signature 2:** ___________________________________

---

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2026-05-07 | Initial creation — all five elements documented; conception dates established | TheYfactora12 |
| 2026-05-07 | Set inventor legal name: Kevin Paul Medeiros Jr | TheYfactora12 |
| 2026-05-07 | Corrected Element 2: split implemented vs. design target; removed overclaimed constants; JSONL outcome retrieval confirmed as implemented baseline. Validated by external AI review. | TheYfactora12 |
| 2026-05-07 | Updated AI Tool Disclosure; updated Element 3 first-committed-evidence to cite commit dab3271 | TheYfactora12 |
| 2026-05-07 | Promoted Element 2 constants and telemetry field to implemented evidence after commit bc10616; Qdrant vector retrieval remains separate future work tracked by #89. | TheYfactora12 |
| 2026-05-08 | Promoted Qdrant task-signature retrieval and approved signature outcome writes to implemented Element 2 evidence after commit `29035ed`; JSONL remains fallback. | TheYfactora12 |
| 2026-05-08 | v2.1 — Full stress-test review: added Table of Contents, use case claim charts, per-element claim chart tables, prior art search record section, Alice Step 2B per-element defense table, SMED readiness statement, witness corroboration block (×2), filing timeline table with grace period risk date, reduction-to-practice dates per element, UC-2E/2F, UC-4E audit trail, UC-5F/5G, System Claim S-1 and Method Claim M-1 cross-reference charts. | TheYfactora12 |
