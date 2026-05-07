# Observability Guide

Home AI Elite observability starts with local, redacted JSONL files. A heavier
trace UI such as self-hosted Langfuse is optional future work and must stay
profile-gated, off by default, and local-only.

## Default Baseline

Default installs use local JSONL and status endpoints:

| Signal | Default path or endpoint | Notes |
| --- | --- | --- |
| Route decisions | `logs/merlin-route-decisions.jsonl` | Redacted, append-only, prompt hash only |
| Approvals | `logs/merlin-approvals.jsonl` | Approval status, gates, execution remains false |
| Executions | `logs/merlin-executions.jsonl` | Read-only action audit for approved v0 actions |
| Magic plans | `logs/merlin-magic-plans.jsonl` | Plan-only records, no autonomous execution |
| Memory writes | `logs/merlin-memory-writes.jsonl` | Redacted audit; approved Qdrant writes are separate |
| Memory reads | `logs/merlin-memory-reads.jsonl` | Redacted query hash and retrieval status |
| Outcomes | `logs/merlin-outcomes.jsonl` | Hashed task outcomes for learning loops |
| Preference candidates | `logs/merlin-preference-candidates.jsonl` | Review-only until user approval |
| Session reflections | `logs/merlin-session-reflections.jsonl` | Redacted previews only when explicitly written |
| Status API | `http://localhost:8765/status` | Read-only, `execution_allowed=false` |
| Task API status | `http://localhost:8766/status/*` | Execution-aware status panels, localhost only |

These files and endpoints are enough for v1.6 debugging without adding a new
container or background service.

## Privacy Contract

- No hidden telemetry.
- No hosted telemetry endpoint.
- No prompt, document, secret, or credential leaves the machine by default.
- Raw user input is not stored in route traces; use `user_goal_hash`.
- Secrets are redacted before logs are written.
- Port `8765` remains read-only and keeps `execution_allowed=false`.
- Observability must never approve or execute actions.

## 8GB Low/Core Behavior

8GB Macs are the entry point. Low/core installs must not start an observability
database, trace UI, or extra background worker by default. Use JSONL plus
`wizard merlin status` and `wizard benchmark run` first.

Any future observability service must:

- be opt-in,
- be behind an explicit `observability` profile or override,
- not bind to LAN by default,
- not replace JSONL as the baseline,
- include static tests proving the default stack excludes it.

## Optional Trace UI Path

Self-hosted Langfuse or a similar trace UI may be added later only after the
#36 design contract is satisfied. The optional path must read or receive local
events only when the user intentionally enables it.

Allowed future shape:

- `docker-compose.observability.yml` or a Compose `observability` profile
- localhost-only bind
- explicit `wizard start observability` or equivalent
- `wizard score` still works from JSONL when the trace UI is disabled
- `wizard trace <session_id>` supports JSONL baseline first, optional UI second

Disallowed future shape:

- adding Langfuse to the default Compose service list,
- using port `3000`, which belongs to Open WebUI,
- sending traces to hosted Langfuse or any external telemetry endpoint,
- requiring Langfuse for 8GB installs,
- storing raw secrets or full private documents in traces.

## How To Read Current Signals

Route and approval debugging:

```bash
wizard merlin dry-run --write-trace "plan a local install"
wizard merlin status
```

Memory quality:

```bash
wizard benchmark run --suite epbench --profile offline
wizard benchmark run --suite all --profile offline
```

Runtime health:

```bash
wizard doctor
wizard merlin status-api status
wizard merlin task-api status
```

## Test Contract

`tests/observability-design-smoke.sh` proves the v1.6 design boundary:

- this guide exists,
- JSONL is the default sink,
- `configs/merlin/trace.yaml` remains local-file and redacted,
- LiteLLM telemetry remains disabled,
- Docker Compose has no default Langfuse service,
- any future Langfuse service must be profile-gated and not use port `3000`,
- the roadmap points to #36 as the design parent and #8 as optional child work.

## Rollback

Revert this guide and the design smoke test. The existing JSONL traces and
status endpoints remain unchanged.
