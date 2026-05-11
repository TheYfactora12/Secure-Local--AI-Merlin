# Privacy And Memory Model

Last updated: 2026-05-06

Merlin AI is local-first. Merlin may use memory only when the memory path is local, auditable, reversible, and approval-gated.

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
- `context_summary`
- `approval_id`
- `privacy_level`
- `route_id`
- `staff_mode`
- `created_at`
- `expires_at`
- `ttl_kind`
- `source`

## Session Memory Bridge (MSC-4)

**File:** `n8n-workflows/06-session-memory-bridge.json`
**Collection:** `merlin_session` (768 dimensions, `nomic-embed-text`, Cosine distance)
**Status:** Importable, ships as `active: false` and must be manually activated in n8n.

The prompt and some issue text may refer to `merlin-session`; the current Qdrant manifest and bootstrap scripts use the canonical collection name `merlin_session`. Do not rename it without a migration.

### What it does

Writes approved session context to the `merlin_session` Qdrant collection at session end or explicit approval, and reads recent session vectors at session start to provide a context prefix.

Bridge rules:

- Recall can run without writing memory.
- Writes require `approved_by: "user_explicit"` in the request body.
- Writes target only `merlin_session`.
- Embeddings use local Ollama `nomic-embed-text`.
- Expected vector size is 768.
- Working memory TTL is 4 hours (`14400` seconds).
- Episodic memory TTL is 30 days (`2592000` seconds).
- Qdrant or Ollama failure returns degraded status and continues the session.

### Approval requirement

Every write requires `approved_by: "user_explicit"`. The validation node throws if this field is absent or has another value. Automatic session memory writes are not permitted.

### Activation

1. Import `n8n-workflows/06-session-memory-bridge.json` into n8n.
2. Verify Qdrant is running with `wizard status`.
3. Activate the workflow manually in the n8n UI.
4. Test write with `POST http://localhost:5678/webhook/swarm/session/memory`.
5. Use body `{"action":"write","session_id":"test-001","user_input_hash":"test-hash","context_summary":"test context","approved_by":"user_explicit"}`.
6. Verify Qdrant collection `merlin_session` shows one point.

### Rollback

Disable or delete `06-session-memory-bridge.json` in n8n. No runtime behavior changes to any other workflow, Python module, or installer script.

## Long-Term Memory

Long-term user memory belongs in `merlin_user` and must be explicit, approved, and deletable. Session memory must not be silently promoted into long-term memory.

## Audit

Memory actions should record approval identifiers and operational status without exposing secrets. Any memory bridge or adapter that can write must be covered by a smoke test proving:

- Approval gate text is present.
- `approval_id` is required.
- Local embeddings are used.
- The target collection is dimension-safe.
- Degraded mode does not throw user-facing failures.
