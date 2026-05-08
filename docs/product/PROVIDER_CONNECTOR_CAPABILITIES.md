# Provider Connector Capabilities

**Status:** Current read-only capability map for #117.
**Updated:** 2026-05-08

Wizard HQ should let users see every known brain connector, decide whether a
provider is allowed or not allowed, and later enter provider credentials through
a policy-gated setup flow. The first implementation is intentionally read-only:
Merlin reports connector families, API key presence, and allow state without
displaying key values or enabling cloud by default.

## Current Rule

- Local connectors are allowed by default.
- External providers are not allowed by default.
- External providers require explicit user allow plus policy approval before
  use.
- API key values are never returned to Wizard HQ.
- Model examples are catalog hints, not live availability claims.
- Browser-side toggles are visual state only until #117 adds a backend-gated
  setup flow.

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

## Setup UX Direction

The Wizard HQ Settings surface should eventually render each external provider
as:

- Allow toggle: off by default.
- Setup button: opens a policy-gated flow.
- Key status: missing or present only.
- Model selector: populated from known catalog or later live model discovery.
- Risk summary: cloud, external network, token spend, and data exposure.
- Confirmation: explicit user approval before any external call.

Do not add live key entry, external model calls, or browser execution controls
until the backend storage, approval, audit, and rollback path exists.

## Source Notes

This map is based on current official provider documentation:

- OpenAI Responses API: <https://platform.openai.com/docs/api-reference/responses>
- Anthropic Messages API and auth: <https://docs.anthropic.com/en/api/messages-examples>
- Gemini API reference: <https://ai.google.dev/api>
- Perplexity Sonar API: <https://docs.perplexity.ai/guides/chat-completions-guide>
- Mistral chat completions: <https://docs.mistral.ai/studio-api/conversations/chat-completion>
- OpenRouter chat completions: <https://openrouter.ai/docs/api-reference/chat-completion>
- Ollama chat API: <https://docs.ollama.com/api/chat>

