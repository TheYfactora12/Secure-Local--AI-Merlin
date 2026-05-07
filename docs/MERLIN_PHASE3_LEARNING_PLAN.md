# Merlin Phase 3 Learning Plan

Phase 3 adds review-first learning loops on top of the Phase 2 Merlin Staff Core. It must not introduce autonomous learning, self-training, hidden memory writes, cloud routing, or policy bypasses.

## Build Order

1. `Phase 3A` — `merlin/outcome_observer.py`
   - Capture task outcome events after routing and response attempts.
   - Store raw prompt only as `sha256` hash.
   - No memory writes without the existing `memory_write` approval gate.
   - Status: started in #65 with JSONL outcome logging, optional approved
     `merlin_audit` writes, routing-gap records, and Task API integration.
2. `Phase 3B` — router retrieval upgrade
   - Blend keyword routing with approved outcome retrieval.
   - Formula: `final_score = (0.6 * keyword_score) + (0.4 * retrieval_score)`.
   - Keyword score stays dominant so retrieval improves routing without taking over.
   - Status: implemented in #66 with approved-outcome JSONL reads, recency
     decay, cold-start preservation, trace fields, and no memory writes.
3. `Phase 3C` — `merlin/preference_extractor.py`
   - Extract explicit or strongly implied user preferences for review.
   - Do not write preferences automatically.
   - Status: implemented in #67 as a deterministic, offline, review-only
     extractor. Candidates include category, confidence, short redacted
     evidence, and `write_eligible`; no Qdrant writes, model calls, cloud calls,
     or config edits occur.
4. `Phase 3D` — `merlin/session_reflector.py`
   - Build short-lived session summaries for continuity.
   - Summaries expire by default; Merlin session memory is intentionally temporary.
   - Status: implemented in #68 as a deterministic, offline, review-only
     reflector. It summarizes existing outcome and preference records, produces
     a 90-day expiry, redacts emitted strings, and performs no Qdrant writes,
     model calls, cloud calls, or config edits.
5. `Phase 3E` — skill scores in `memory_manager.py`
   - Compute local skill confidence from recent approved outcome history.
   - Skill scores inform routing visibility but never bypass approval gates.

## Outcome Event Contract

```json
{
  "event_type": "task_outcome",
  "task_hash": "sha256(user_input)",
  "route_id": "code|general|memory|search|automation",
  "staff_mode": "software_engineer|operator|architect|ai_engineer|security_reviewer|product_designer",
  "agent_target": "openhands|litellm|n8n|merlin-core",
  "confidence_at_routing": 0.75,
  "outcome_status": "success|failure|timeout|rejected|degraded",
  "latency_ms": 1240,
  "keyword_matches": ["code", "python"],
  "hardware_tier": "low|base|mid|high",
  "user_feedback": "positive|negative|none",
  "created_at": "2026-05-06T21:16:00Z",
  "approval_id": null
}
```

Rules:

- `task_hash` only; never store raw user input in outcome events.
- `approval_id` is required before writing any persistent memory derived from an outcome.
- `outcome_status=rejected` means a policy gate blocked the route and no action executed.
- `outcome_status=degraded` means Merlin continued without a dependency such as LiteLLM or Qdrant.

## Retrieval Score

Phase 3B retrieval score uses recent approved outcomes:

```text
recency_weight = exp(-days_since_outcome / 30)
retrieval_score = sum(outcome.success * recency_weight) / sum(recency_weight)
final_score = (0.6 * keyword_score) + (0.4 * retrieval_score)
```

Rules:

- `outcome.success` is `1` for success and `0` for failure, timeout, rejected, or degraded.
- Use a 30-day decay window so stale outcomes fade naturally.
- If no approved outcome history exists, retrieval score is `0.0`.
- Cloud outcomes must not be mixed with local outcomes unless explicitly tagged and approved.

## Low-Confidence Review Item

```json
{
  "task_hash": "...",
  "routed_to": "general",
  "confidence": 0.42,
  "outcome": "success",
  "matched_keywords": ["how"],
  "candidate_keywords": [],
  "suggested_route": null,
  "flagged_at": "..."
}
```

Rules:

- Create review items for route confidence below `0.6`.
- `candidate_keywords` and `suggested_route` are human-review fields.
- Merlin may recommend changes, but it must not edit routing config automatically.

## Preference Extractor Prompt

```text
System: You are extracting user preferences from a conversation.
Return ONLY a JSON array. Each item must have:
  - "preference_text": one sentence, third-person, factual
  - "category": one of [coding_style, tool_preference, communication_style, workflow_pattern, domain_expertise]
  - "confidence": float 0.0-1.0
  - "evidence": verbatim quote from conversation (max 80 chars)

Rules:
- Only extract preferences explicitly stated or strongly implied
- Do not infer from a single passing remark
- Confidence < 0.85 means DO NOT write; include in output for review only
- Maximum 3 preferences per session
- Return [] if nothing qualifies

Conversation: {session_text}
```

Rules:

- Preference writes require `memory_write` approval.
- Evidence must stay short and redacted.
- The extractor output is review input, not persistent memory by itself.

## Session Reflection Contract

```json
{
  "session_id": "uuid4()",
  "summary_text": "...",
  "tasks_attempted": 4,
  "tasks_succeeded": 3,
  "routes_used": ["code", "general"],
  "low_confidence_routes": ["general"],
  "preferences_extracted": 1,
  "staff_modes_used": ["software_engineer", "operator"],
  "hardware_tier": "low",
  "session_duration_s": 847,
  "created_at": "...",
  "expires_at": "+90 days"
}
```

Rules:

- `summary_text` is a two-to-four sentence natural language summary.
- `low_confidence_routes` contains routes with confidence below `0.6`.
- Session summaries are short-lived and deletable.

## Skill Score Memory Contract

```json
{
  "memory_type": "skill_score",
  "skill_key": "software_engineer::code",
  "rolling_success_rate": 0.87,
  "sample_count": 34,
  "last_updated": "...",
  "approval_id": "MERLIN_OUTCOME_APPROVAL_ID"
}
```

Rules:

- Compute from the last 50 approved outcome records.
- `skill_key` is `staff_mode::task_type`.
- Skill scores never authorize execution, cloud calls, shell commands, file writes, memory writes, or model downloads.

## Memory Index Requirements

`configs/merlin/memory.yaml` must keep these indexes on `merlin_audit`:

- `event_type`
- `approval_id`
- `actor`
- `created_at`
- `route_id`
- `outcome_status`

The `route_id` and `outcome_status` indexes enable retrieval-augmented routing and success-rate calculations without scanning every audit payload.
