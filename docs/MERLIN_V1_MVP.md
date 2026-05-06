# Merlin v1 MVP

Last updated: 2026-05-06

## Hard Answer

Merlin is at risk of overbuilding if v1 tries to become a fully autonomous AI operating system. The repo already has enough infrastructure. The next milestone should make Merlin useful, visible, and safe for a normal user.

## Smallest Useful Merlin v1

Merlin v1 should include:

- Hardware detection and tier warnings.
- `wizard doctor` health checks.
- Merlin config validation.
- Local-only mode by default.
- Provider registry skeleton.
- Model router skeleton using existing LiteLLM aliases.
- Dashboard status cards.
- Controlled memory design with approval.
- Magic Mode planning only.
- Approval model.
- Redacted audit log format.
- Test strategy covering installer, local-only behavior, policy, memory, and low-memory mode.

Merlin v1 is successful when a user can:

1. Install core safely.
2. See local-only status.
3. Ask Merlin a local question.
4. See routing and approval state.
5. Store memory only with approval.
6. Use Magic Mode to plan, not execute.
7. Understand what is degraded and what to do next.

## What Can Ship In One Weekend

- `wizard merlin ask` as a thin wrapper over the existing local task path.
- Clear degraded output when port 8766 or LiteLLM is down.
- Route/approval display in CLI output.
- README update showing the Merlin v1 loop.
- Smoke test with mocked/degraded expectations.

## What Can Ship In One Week

- `wizard merlin ask`.
- Read-only Merlin dashboard status panel.
- Explicit memory approval flow.
- Low-memory 8GB validation checklist.
- Demo script: install core, doctor, ask, approval block, status, sanitized report.

## Magic Mode v1

Magic Mode v1 is plan-only.

Allowed:

- Break a goal into steps.
- Assign route/staff mode.
- Show tools that would be needed.
- Show approval gates.
- Save redacted plan audit.

Blocked:

- Shell execution.
- File writes or deletes.
- Git operations.
- OpenHands execution.
- n8n workflow execution.
- Browser/computer-use automation.
- Service start/stop.
- External network calls.
- Cloud model calls.
- Automatic memory writes.

## Local-Only By Default

- Ollama.
- LiteLLM local aliases.
- Qdrant.
- Dashboard.
- 8765 read-only status.
- 8766 task/status API.
- Route traces.
- Redacted bug reports.
- Approval logs.

## Optional Cloud Behavior

Cloud behavior is optional and must require:

- User-enabled online mode.
- Provider key present.
- Clear disclosure before use.
- Approval for sensitive tasks.
- Audit record showing provider and reason without secrets.

## What Fails On M1 8GB

- Multiple LLMs loaded at once.
- 14B+ models.
- OpenHands plus full stack.
- n8n plus Perplexica plus Open WebUI plus indexing.
- Long-context RAG over large document sets.
- Parallel agents.
- Large Docker Desktop memory allocation.

Default for 8GB:

- Core profile only.
- One 7B quantized model.
- No automatic large downloads.
- No heavy background services.
- Small explicit memory operations.

## Should Never Run Automatically

- Model downloads.
- Cloud calls.
- Shell commands.
- File writes/deletes.
- Git operations.
- OpenHands tasks.
- n8n workflows.
- Browser automation.
- Package installs.
- Public network exposure.
- Memory writes.
- Background agents.

## Must Require Approval

- Shell/file/git/network/cloud/API key/secret actions.
- Memory writes and deletes.
- Service lifecycle actions.
- Model downloads.
- OpenHands.
- Any action that changes local state or sends data outside localhost.

## Wrap Instead Of Rebuild

- Ollama.
- LiteLLM.
- Open WebUI.
- Qdrant.
- n8n.
- OpenHands.
- SearXNG/Perplexica.
- gitleaks.
- Docker Compose.

## Do Not Build In v1

- Custom model runtime.
- Custom vector database.
- Custom workflow engine.
- Custom coding agent.
- Custom browser automation framework.
- Fine-tuning or self-training.
- Enterprise RBAC.
- Mobile app.
- Cross-device sync.
- Always-on autonomous swarm.

## First PR Recommendation

First implementation slice:

**Add `wizard merlin ask` as a thin local wrapper.**

Why:

- Uses existing Merlin Phase 2 work.
- Does not touch installer.
- Works on 8GB Macs.
- Requires no cloud keys.
- Introduces no autonomous execution.
- Can be tested in one PR.
- Rollback is simple: remove the wrapper and test.
