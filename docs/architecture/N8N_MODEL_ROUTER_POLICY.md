# n8n ModelRouter Policy

The Python Merlin router is the primary routing and policy control plane.
`merlin/router.py` reads `configs/merlin/routes.yaml`, applies local-first
defaults, carries approval gates, and writes route traces. n8n remains an
optional workflow engine for user-approved automation paths.

## Current Contract

`n8n-workflows/ai-router-starter.json` is an importable starter workflow only.
It ships with `active: false` and must not be used as the primary Merlin brain.

The workflow may execute local Ollama requests through:

- `http://host.docker.internal:11434`
- `http://ollama:11434`
- `http://localhost:11434`

The workflow must not contain executable cloud provider HTTP nodes. Cloud routes
are represented only as approval-required metadata until a user explicitly
approves the required gates:

- `cloud_model_call`
- `external_network`
- `api_key_use`

## Why Cloud Branches Are Metadata Only

The stale #6 design allowed automatic cloud escalation when local routing failed.
That conflicts with the current Merlin AI policy: local-first by default,
cloud optional, and cloud use gated by explicit user approval. A workflow JSON
that contains direct OpenAI, Perplexity, Anthropic, or Google API HTTP nodes can
be imported and accidentally activated. The safer v1.3 contract is to block the
cloud path in-workflow and return approval metadata instead of making a network
call.

## Static Gate

`tests/n8n-model-router-policy-smoke.sh` validates that:

- `ai-router-starter.json` is parseable JSON.
- The workflow ships inactive.
- No cloud provider HTTP Request node is executable.
- A local Ollama route remains available.
- The cloud approval gates are present.
- Cloud routes produce `approval_required` metadata.
- `wizard test-workflows` runs the policy smoke test.

This test is offline-safe. It does not require n8n, Ollama, Qdrant, Docker,
cloud credentials, or network access.

## Rollback

Revert `n8n-workflows/ai-router-starter.json` and
`tests/n8n-model-router-policy-smoke.sh`. This affects only an inactive n8n
starter workflow and static validation. It does not touch `install.sh`, Docker
Compose services, Merlin Python runtime, or active user data.
