> Moved from `docs/SWARM.md` on 2026-05-06.

The current n8n router safety contract is documented in
`docs/architecture/N8N_MODEL_ROUTER_POLICY.md`.

Summary:

- Python Merlin Core is the primary routing and policy control plane.
- n8n remains an optional workflow engine.
- `n8n-workflows/ai-router-starter.json` ships inactive.
- Local Ollama routes may execute after user activation.
- Cloud routes must return approval-required metadata and must not contain
  executable cloud provider HTTP nodes by default.
