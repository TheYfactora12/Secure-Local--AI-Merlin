# AGENTS.md

## Identity
You are building and operating a local-first personal AI stack.

## Core Rules
- Default to local Ollama for all tasks.
- Escalate to Perplexity only for live web research and current-context queries.
- Escalate to OpenAI only for hard reasoning or complex coding tasks.
- Never hardcode API keys or secrets.
- Always log outputs and decisions to the local store.
- Every cloud API call should go through the n8n router.

## Memory
- Store all research summaries and decisions in Qdrant under the configured collection.
- Before any research task, query Qdrant first. Answer from cache if available.

## Code Standards
- Python 3.11 with type hints.
- Async-first where applicable.
- Tests included with any new module.
- Append completed task summaries to logs/task-log.md.
