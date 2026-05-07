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
