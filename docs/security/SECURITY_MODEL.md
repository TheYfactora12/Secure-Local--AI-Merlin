> Moved from `docs/SECURITY_MODEL.md` on 2026-05-06 — content unchanged.

## Mobile And LAN Access Boundary

Default installs are localhost-only. Mobile, LAN, and remote access are
explicit opt-in modes and must never be enabled by the installer without user
action.

- Keep service binds on `127.0.0.1` by default.
- Do not expose Qdrant, Ollama, LiteLLM, n8n, OpenHands, Docker, raw logs, or
  raw memory collections directly to LAN clients.
- Treat any bind change to `0.0.0.0` as an `external_network` +
  `service_start` approval-gated action.
- Keep port `8765` read-only with `execution_allowed=false`.
- Keep port `8766` as the execution-aware task API; do not merge it into the
  read-only status server.
- Do not enable cloud, remote tunnel, or webhook execution behavior by default.

The v1.1 design is documented in `docs/MOBILE_ACCESS_PLAN.md`.

## Observability Boundary

Observability defaults to local redacted JSONL files. Do not add hosted
telemetry, default trace UI containers, or external trace export by default.

- Keep `logs/merlin-route-decisions.jsonl` as the default route trace sink.
- Keep approval, memory, execution, outcome, and Magic Mode records local.
- Treat any hosted telemetry endpoint as `external_network` plus
  `cloud_model_call`/`api_key_use` if model or prompt data is involved.
- Keep optional trace UIs such as self-hosted Langfuse behind explicit
  profile-gated startup.
- Do not start observability services on 8GB low/core installs.
- Never expose raw logs or trace UIs over LAN without explicit mobile/LAN
  approval.

The v1.6 design is documented in `docs/observability-guide.md`.
