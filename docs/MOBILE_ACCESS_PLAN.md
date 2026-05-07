# Mobile Access Plan

Status: v1.1 design. No runtime behavior changes are included in this issue.

Home AI Elite remains localhost-only by default. Mobile, LAN, and remote access
are optional modes that must be explicitly enabled by the user after install.
The installer must not expose Merlin, Open WebUI, n8n, LiteLLM, Ollama, Qdrant,
OpenHands, or the dashboard to the LAN by default.

## Goals

- Let a user eventually reach Merlin from trusted mobile workflows such as a
  phone browser, iOS Shortcuts, or a local-network webhook.
- Preserve local-first security defaults on 8GB entry hardware and larger Macs.
- Expose the smallest possible surface when LAN mode is enabled.
- Keep cloud/tunnel behavior off unless the user deliberately enables it.
- Make rollback obvious: return every bind to `127.0.0.1` and restart services.

## Default Mode: Localhost Only

Default mode is `local_only`.

- Docker services bind to `127.0.0.1` by default through `*_BIND` variables.
- `scripts/doctor.sh` fails if a checked bind value is `0.0.0.0`.
- Port `8765` remains the read-only Merlin status API. It must keep
  `execution_allowed=false`.
- Port `8766` remains the execution-aware Merlin task API and Phase 2 status
  panel surface.
- n8n keeps `N8N_SECURE_COOKIE=false` only for local browser use. It must not be
  exposed over LAN or internet with that setting.

## Safe Entry Points

### MVP: Same-Machine Access

The supported v1.0/v1.1 baseline remains same-machine access:

- Dashboard: `http://localhost:8888`
- Open WebUI: `http://localhost:3000`
- Merlin status API: `http://localhost:8765`
- Merlin task API: `http://localhost:8766`

This is the only mode the installer should configure automatically.

### v1.1 Candidate: Opt-In LAN Gateway

LAN access should be a separate opt-in profile, not a broad bind change across
all services. The preferred design is a single gateway surface that can proxy a
small allowlist:

- Read-only dashboard/status views.
- Merlin Chat through `POST /task` on port `8766` or a future gateway route.
- Approval responses for already proposed actions.

Do not expose these services directly to the LAN:

- Qdrant
- Ollama
- LiteLLM
- n8n
- OpenHands
- Docker socket or container admin endpoints
- Raw memory collections
- Raw logs that may contain paths or redacted runtime details

If LAN gateway mode is implemented later, it must require:

- Explicit user command, such as a future `wizard mobile enable --lan` command.
- Auth token or passphrase setup before binding beyond localhost.
- Clear dashboard warning that LAN access is active.
- Audit log entry when the mode is enabled or disabled.
- `wizard doctor` visibility for every non-local bind.

### Future: Remote Tunnel

Remote access over the internet is not part of v1.1 runtime scope. A future
remote mode must be treated as a high-risk feature and require a separate
security review before implementation.

Minimum requirements for any future tunnel mode:

- TLS.
- Authentication.
- Rate limiting.
- Explicit cloud/tunnel provider approval.
- Clear data-flow disclosure.
- Audit logging.
- One-command disable.
- No direct exposure of Qdrant, Ollama, LiteLLM, n8n, or OpenHands.

## Approval Gates

Mobile/LAN work maps to existing policy gates. The design should fail closed if
policy cannot be loaded.

| Action | Required gates |
|---|---|
| Enable LAN gateway | `external_network`, `service_start` |
| Change a bind from `127.0.0.1` to `0.0.0.0` | `external_network`, `service_start` |
| Use a mobile webhook to start automation | `external_network`, `service_start`, `api_key_use` when token-protected |
| Write memory from a mobile session | `memory_write` |
| Read or manage secrets for mobile auth | `secret_access`, `api_key_use` |
| Call cloud or remote tunnel provider | `cloud_model_call`, `external_network`, `api_key_use` |

Drift note: earlier planning references a `webhook_execution` gate, but the live
policy contract currently has 14 gates and does not include that gate. Until a
dedicated policy issue adds it, webhook exposure must be guarded by the
combination of `external_network`, `service_start`, `api_key_use`, and the
action-specific gate such as `memory_write`.

## iOS Shortcuts Shape

The safest first mobile workflow is an iOS Shortcut that calls a local-network
Merlin endpoint only after the user has explicitly enabled LAN gateway mode.

Request shape should be narrow:

```json
{
  "input": "string, max 4000 chars",
  "session_id": "optional mobile session id"
}
```

Response shape should stay close to the current task API:

```json
{
  "response": "string",
  "route": {},
  "approved": false,
  "session_id": "string",
  "memory_written": false
}
```

The shortcut must not carry raw API keys. A future gateway token should be
stored in the mobile OS secure credential store and revocable from Merlin.

## Manual Test Plan

Run these before any LAN/mobile implementation is considered releasable:

```bash
bash scripts/doctor.sh
curl -fsS --max-time 3 http://127.0.0.1:8765/healthz
curl -fsS --max-time 3 http://127.0.0.1:8766/status/routes
docker compose config | grep '127.0.0.1'
```

Expected default result:

- `doctor` has zero failures.
- Port `8765` reports `execution_allowed=false`.
- Port `8766` exposes `/status/routes` locally.
- Compose output shows localhost binds for default services.
- No `*_BIND=0.0.0.0` value is present in `.env` unless the user explicitly set
  LAN mode for a future test.

Future LAN mode tests must also verify:

- One gateway is reachable from a trusted phone on the same subnet.
- Qdrant, Ollama, LiteLLM, n8n, and OpenHands are not reachable directly.
- Disabling LAN mode returns all binds to localhost.
- Dashboard clearly shows LAN mode is active while enabled.
- No cloud calls occur unless cloud behavior is separately approved.

## Rollback

Rollback for this design issue is documentation-only. For a future LAN
implementation, rollback must:

1. Reset all `*_BIND` values to `127.0.0.1`.
2. Stop the LAN gateway service.
3. Re-run `bash scripts/doctor.sh`.
4. Confirm all direct service URLs are reachable only from localhost.

