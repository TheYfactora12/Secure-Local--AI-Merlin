# Privacy And Memory Model

Last updated: 2026-05-06

Home AI Elite is local-first. Merlin may use memory only when the memory path is local, auditable, reversible, and approval-gated.

## Defaults

- Cloud calls are off by default.
- Memory writes require approval.
- Memory reads are local-only.
- Secrets and raw prompts are not written to logs.
- Qdrant collections must follow the dimension manifest in `configs/merlin/memory.yaml`.
- The legacy `documents` collection remains 1536d and must never receive `nomic-embed-text` 768d vectors.

## Session Memory

`merlin_session` is the short-lived session recall collection. It is for continuity, not permanent identity.

Approved session memory payloads include:

- `session_id`
- `user_id`
- `text`
- `approval_id`
- `privacy_level`
- `route_id`
- `staff_mode`
- `created_at`
- `expires_at`
- `ttl_kind`
- `source`

The n8n bridge workflow is `n8n-workflows/06-session-memory-bridge.json`.

Bridge rules:

- Recall can run without writing memory.
- Writes require `memory_write_approved=true` and a non-empty `approval_id`.
- Writes target only `merlin_session`.
- Embeddings use local Ollama `nomic-embed-text`.
- Expected vector size is 768.
- `ttl_kind=working` expires in about 4 hours.
- `ttl_kind=episodic` expires in about 30 days.
- Qdrant or Ollama failure returns degraded status and continues the session.

## Long-Term Memory

Long-term user memory belongs in `merlin_user` and must be explicit, approved, and deletable. Session memory must not be silently promoted into long-term memory.

## Audit

Memory actions should record approval identifiers and operational status without exposing secrets. Any memory bridge or adapter that can write must be covered by a smoke test proving:

- Approval gate text is present.
- `approval_id` is required.
- Local embeddings are used.
- The target collection is dimension-safe.
- Degraded mode does not throw user-facing failures.
