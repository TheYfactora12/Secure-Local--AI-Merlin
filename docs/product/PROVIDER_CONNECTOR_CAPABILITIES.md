# Provider Connector Capabilities

**Status:** Current capability map plus backend-only presence marker setup for #117.
**Updated:** 2026-05-09

Wizard HQ should let users see every known brain connector, decide whether a
provider is allowed or not allowed, and enter provider credentials only through
an execution-aware backend path. The current backend slice stores presence
metadata only: Merlin reports connector families, API key presence, allow state,
and storage mode without displaying or persisting raw key values and without
enabling cloud by default.

## Current Rule

- Local connectors are allowed by default.
- External providers are not allowed by default.
- External providers require explicit user allow plus policy approval before
  use.
- API key values are never returned to Wizard HQ.
- Raw API key values are not persisted by the current presence-marker store.
- Provider setup writes require an approval id and run through port 8766, not
  the read-only status API on port 8765.
- Model examples are catalog hints, not live availability claims.
- Browser-side toggles remain visual state only until Wizard HQ adds a tested
  policy-gated form.
- Cloud routing remains disabled unless a later routing/policy slice explicitly
  enables it after approval.

## Provider Families

| Provider | API family | Auth shape | Merlin state | Notes |
| --- | --- | --- | --- | --- |
| Ollama | `ollama_native` | local localhost, no provider key | allowed local | Local chat and embeddings runtime. |
| LiteLLM | `openai_compatible_gateway` | local bearer master key | allowed local | Local gateway and routing layer. |
| ChatGPT / OpenAI | `openai_responses` | bearer key | not allowed | Uses OpenAI Responses-style request/response flow. |
| Claude / Anthropic | `anthropic_messages` | `x-api-key` | not allowed | Uses Messages API shape, not OpenAI-compatible by default. |
| Perplexity Sonar | `perplexity_sonar` | bearer key | not allowed | Web-grounded Sonar/chat-completions provider. |
| Gemini / Google AI | `gemini_generate_content` | `x-goog-api-key` | not allowed | Uses `generateContent` / streaming content APIs. |
| Mistral AI | `mistral_chat_completions` | bearer key | not allowed | Chat completions family with Mistral model IDs. |
| OpenRouter | `openai_compatible_router` | bearer key | not allowed | OpenAI-compatible router across third-party models. |

## Current Backend Setup Contract

The #117 backend setup slice adds:

- `POST /status/settings/provider-connectors` on the execution-aware Task API.
- `POST /status/settings/provider-connectors/{provider_id}/disable` on the
  execution-aware Task API.
- Required `approval_id` for setup and disable requests.
- Presence-only metadata: `credential_present`, `credential_fingerprint`,
  `user_allowed`, `enabled`, `storage_mode`, and `secret_persisted=false`.
- Metadata-only audit event attempt through `merlin-audit`.

This is not a secret vault and not cloud routing. It is the minimum safe backend
contract that lets Wizard HQ later show configured/disabled/allowed states
without exposing raw keys.

## Setup UX Direction

The Wizard HQ Settings surface should eventually render each external provider
as:

- Allow toggle: off by default.
- Setup button: opens a policy-gated flow.
- Key status: missing or present only.
- Model selector: populated from known catalog or later live model discovery.
- Risk summary: cloud, external network, token spend, and data exposure.
- Confirmation: explicit user approval before any external call.

Do not add external model calls, default cloud routing, or browser execution
controls until routing policy, approval, audit, and rollback paths exist.

## Source Notes

This map is based on current official provider documentation:

- OpenAI Responses API: <https://platform.openai.com/docs/api-reference/responses>
- Anthropic Messages API and auth: <https://docs.anthropic.com/en/api/messages-examples>
- Gemini API reference: <https://ai.google.dev/api>
- Perplexity Sonar API: <https://docs.perplexity.ai/guides/chat-completions-guide>
- Mistral chat completions: <https://docs.mistral.ai/studio-api/conversations/chat-completion>
- OpenRouter chat completions: <https://openrouter.ai/docs/api-reference/chat-completion>
- Ollama chat API: <https://docs.ollama.com/api/chat>
