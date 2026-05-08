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

Implemented optional local profile:

- `docker-compose.observability.yml` defines Langfuse web/worker plus Postgres,
  ClickHouse, Redis, and MinIO under the `observability` profile only.
- `configs/langfuse/langfuse.env.example` lists required local env keys without
  secret values.
- `wizard start observability` calls `scripts/start-observability.sh`, refuses
  to start on RAM below 16GB unless `HOME_AI_ALLOW_LOW_TIER_OBSERVABILITY=true`
  is explicitly set, and starts the override profile intentionally.
- Langfuse binds to `http://localhost:3010` by default. Open WebUI keeps port
  `3000`.
- `scripts/healthcheck.sh` checks Langfuse only when the observability profile
  is active; otherwise it skips that health check.

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

7-day local quality trend:

```bash
wizard score
wizard score --days 7
```

`wizard score` reads local JSONL only. It reports outcome counts, success rate,
benchmark recall, low-confidence successes, approval-required trace counts, and
a blended quality score when enough data exists. It does not require Langfuse.

Local trace inspection:

```bash
wizard trace <trace_id>
wizard trace <approval_request_id>
wizard trace <user_goal_hash>
```

`wizard trace` reads local route, approval, and outcome JSONL records. It prints
redacted metadata only, supports direct trace/approval IDs and hashed user-goal
lookups, and does not require Langfuse or live services.

Plan optional Langfuse export:

```bash
wizard observability export --dry-run
```

`wizard observability export --dry-run` reads route, approval, outcome,
benchmark, and memory read/write JSONL records and prints planned export counts
without network calls. It does not require Langfuse or live services.

Exported memory fields are metadata-only: collection, memory type, adapter,
policy decision, result status, result count, Qdrant read/write status,
dimension guard status, and optional score/latency fields if present. Raw memory
text, query previews, retrieved chunks, document content, secrets, credentials,
tokens, and API keys are never exported.

Runtime health:

```bash
wizard doctor
wizard merlin status-api status
wizard merlin task-api status
wizard start observability
```

After explicitly starting the optional profile, open:

```bash
http://localhost:3010
```

Live export is explicit and localhost-only:

```bash
wizard observability export --live \
  --langfuse-url http://localhost:3010 \
  --public-key "$LANGFUSE_PUBLIC_KEY" \
  --secret-key "$LANGFUSE_SECRET_KEY"
```

The exporter refuses hosted/cloud Langfuse URLs and exports only redacted
metadata. It skips gracefully if local Langfuse is not reachable.

## Optional n8n Trace Emission

`n8n-workflows/07-local-langfuse-trace-emitter.json` is an importable workflow
for n8n execution traces. It ships with `active: false` and does nothing unless
a user imports and activates it manually.

Webhook path:

```text
POST /webhook/swarm/observability/trace
```

Trace emission is allowed only when the observability profile is active. The
workflow checks `HOME_AI_OBSERVABILITY_PROFILE_ACTIVE=true` or an explicit
`observability_active: true` request field before attempting to post. When the
profile is inactive, it returns a skipped response and the calling workflow can
continue normally.

Allowed trace metadata is limited to operational fields such as workflow ID,
execution ID, route ID, agent target, selected model alias, status, duration,
approval gates, and `user_goal_hash`. Raw prompts, raw inputs, outputs,
documents, secrets, credentials, API keys, and tokens are not exported.

The trace emitter posts only to local Langfuse endpoints:

- `http://langfuse-web:3000`
- `http://localhost:3010`
- `http://127.0.0.1:3010`

Hosted Langfuse URLs are refused. If local Langfuse is unavailable, the HTTP node
uses `continueOnFail: true` and returns a degraded response instead of failing
the workflow. Langfuse write credentials are read from the n8n environment only;
they are not accepted in webhook request bodies.

Longer-term automation runtime strategy lives in
`docs/architecture/AUTOMATION_RUNTIME_STRATEGY.md`. The native runtime is a
last-mile commercial milestone, not part of the v1.6 trace-emission work.

## Test Contract

`tests/observability-design-smoke.sh` proves the v1.6 design boundary:

- this guide exists,
- JSONL is the default sink,
- `configs/merlin/trace.yaml` remains local-file and redacted,
- LiteLLM telemetry remains disabled,
- Docker Compose has no default Langfuse service,
- any future Langfuse service must be profile-gated and not use port `3000`,
- the roadmap points to #36 as the design parent and #8 as optional child work.

`tests/merlin-score-smoke.sh` proves the JSONL baseline is operational:

- `scripts/merlin-score.sh` reads local outcome, trace, and benchmark JSONL,
- `wizard score` works without Langfuse,
- no external telemetry or live services are required.

`tests/merlin-trace-view-smoke.sh` proves the local trace viewer is operational:

- `scripts/merlin-trace-view.sh` reads local trace, approval, and outcome JSONL,
- `wizard trace <id>` works without Langfuse,
- hash-based lookup can connect route, approval, and outcome records,
- no external telemetry or live services are required.

`tests/langfuse-observability-profile-smoke.sh` proves the optional Langfuse
profile is gated:

- default `docker-compose.yml` has no Langfuse services,
- all Langfuse services live in `docker-compose.observability.yml` under the
  `observability` profile,
- all published ports bind to `127.0.0.1`,
- Langfuse uses host port `3010`, not Open WebUI port `3000`,
- the start script has a low-RAM guard and explicit override,
- healthcheck skips Langfuse unless the profile is active.

`tests/merlin-observability-export-smoke.sh` proves the optional exporter is
safe:

- dry-run reads local JSONL and performs no network calls,
- memory read/write events export metadata only,
- hosted/cloud Langfuse URLs are refused,
- unreachable localhost Langfuse is skipped gracefully in explicit live mode,
- `wizard observability export --dry-run` works without live services.

`tests/n8n-local-langfuse-trace-smoke.sh` proves n8n trace emission is optional
and local-only:

- `07-local-langfuse-trace-emitter.json` ships inactive,
- emission is gated on the observability profile,
- hosted Langfuse URLs are refused,
- local Langfuse failure degrades gracefully,
- raw payloads and secrets are not exported.

## Rollback

Stop the optional profile:

```bash
docker compose -f docker-compose.yml -f docker-compose.observability.yml --profile observability down
```

Then revert the optional override/config/script changes if needed. The existing
JSONL traces, `wizard score`, `wizard trace`, and status endpoints remain
unchanged.
