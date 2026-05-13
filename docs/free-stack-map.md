# Free Stack Map

Status: v1.2 planning baseline. This map explains what each local component is
for and which paid/cloud product category it can replace.

Merlin AI is not trying to clone every cloud product feature. It wraps a
small local-first stack and adds Merlin policy, memory, routing, approvals, and
dashboard visibility.

| Need | Merlin AI component | Paid/cloud equivalent | v1 status |
|---|---|---|---|
| Chat UI | Open WebUI | ChatGPT UI, Claude UI | Installed in core |
| Local model runtime | Ollama | OpenAI/Anthropic hosted models | Installed in core |
| Model proxy/router | LiteLLM | OpenAI-compatible API gateway | Installed in core |
| Local memory/vector DB | Qdrant | Pinecone, Weaviate Cloud | Installed in core |
| Dashboard | Wizard HQ | SaaS admin dashboard | Installed in core |
| Health/diagnostics | `wizard doctor` | Managed support health check | Installed in core |
| Private web search | SearXNG + Perplexica | Perplexity, Google AI search | Optional `search` profile |
| Automation | n8n | Zapier, Make | Optional `automation` profile |
| Coding agent | OpenHands | Copilot Workspace/Codex-style agent | Optional `coding` profile |
| **Local Claude Code CLI** | Claude Code CLI + Ollama (loopback only) | Anthropic Claude Code cloud billing | **Future** — after `coding` profile is stable; see `FUTURE_IDEAS.md` |
| **AI design/artifact generator** | Open Design (nexu-io/open-design) | Claude Design (Anthropic Labs) | **Future** — after `coding` profile is stable; see `FUTURE_IDEAS.md` |
| Policy-gated AI brain | Merlin Core | Local assistant safety layer | Built in Phase 2 |
| Session memory bridge | n8n session memory workflow | Hosted agent memory | Importable, inactive by default |
| Magic Mode | Merlin plan-first orchestration | Autonomous agent platforms | Plan-only today |
| Voice | Future local STT/TTS adapter | ChatGPT Voice | Future; see `docs/product/FUTURE_IDEAS.md` |
| Image generation | Future local image adapter | Midjourney, DALL-E, Firefly | Future; see `docs/product/FUTURE_IDEAS.md` |
| Document ingestion | Future Docling/Unstructured-style adapter | ChatGPT file upload, NotebookLM | Future; see `docs/product/FUTURE_IDEAS.md` |

## What Stays Optional

- Search stack.
- n8n automation.
- OpenHands coding profile.
- Claude Code local CLI adapter.
- Open Design artifact generator.
- Voice.
- Image generation.
- Large document ingestion.
- Cloud model providers.

Optional means:

- Not enabled by the installer by default.
- Not required on 8GB.
- Must be visible in `wizard doctor` and the dashboard when enabled.
- Must preserve local-only defaults unless a user explicitly opts into external
  behavior.

## What We Wrap Instead Of Rebuild

- Ollama for local model serving.
- Open WebUI for the existing chat surface.
- LiteLLM for OpenAI-compatible local routing.
- Qdrant for vector memory.
- n8n for importable automation workflows.
- OpenHands for high-risk supervised coding workflows.
- Claude Code CLI (future) pointed at Ollama loopback — zero cloud egress.
- Open Design (future) using the user's own coding agent CLI — BYOK, local-first, Apache-2.0.

Merlin adds the product layer above them: policy gates, route decisions, local
memory rules, audit traces, hardware-tier warnings, and a clean command center.

## Platform Notes

- **Primary target: Apple Silicon Mac (2020+).** The Claude Code local stack
  (nicedreamzapp/claude-code-local) uses MLX and is Apple Silicon native.
  Open Design auto-detects Claude Code, Cursor, Codex, and 13 other CLI agents.
- **Windows / Linux:** Deferred to v2.0/v2.5 per the milestone ladder. The
  Ollama+Claude Code CLI path works cross-platform once those installers exist.
