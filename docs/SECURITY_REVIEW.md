# Security Review

Review scope: local AI risks in the current repository. This is a planning review, not a claim of production security certification.

## Summary

The repo has several good secure defaults: `.env` is generated locally, secrets are rotated, `.env` permissions are set to `600`, cloud keys are optional, and service ports are now bound to `127.0.0.1` by default in the main Compose file.

The highest risks are agent/tool execution surfaces, especially OpenHands with Docker socket access, n8n workflow endpoints, direct dashboard calls to local services, inconsistent memory handling, and upgrade/package behavior that can run broad actions without enough policy separation.

## Findings

### High: OpenHands mounts Docker socket

Evidence:

- `docker-compose.yml` mounts `/var/run/docker.sock:/var/run/docker.sock` in `openhands`.

Risk:

- Docker socket access is effectively host-level control. If OpenHands or an agent workflow is compromised, it may create privileged containers, access files, or affect other services.

Recommended fix:

- Move OpenHands behind a `coding` profile.
- Require explicit user approval to start coding profile.
- Add dashboard and `wizard doctor` warnings.
- Do not enable OpenHands on low-memory tiers by default.

Required before Merlin v1: Yes.

### High: Magic/agent actions lack a central approval policy

Evidence:

- `cli/wizard` can call n8n webhooks for swarm, ingest, training, and memory operations.
- Dashboard can POST to `http://localhost:5678/webhook/wizard-task`.
- No central policy layer currently mediates tool, file, shell, memory, or network actions.

Risk:

- Prompt injection or malicious workflow content could cause unintended tool use when agent capabilities expand.

Recommended fix:

- Add a Merlin policy layer before Magic Mode.
- Require approval for shell, file writes, network calls, memory writes, cloud API calls, and OpenHands execution.

Required before Merlin v1: Yes for Magic Mode; not required for baseline installer.

### High: n8n workflow import and endpoints are not fully governed

Evidence:

- `scripts/bootstrap.sh` and `scripts/import-n8n-workflows.sh` import workflows when `N8N_API_KEY` exists.
- Dashboard assumes `webhook/wizard-task`.
- `cli/wizard` assumes swarm and memory webhooks.

Risk:

- Workflows may become a hidden control plane without versioned permissions or approval boundaries.

Recommended fix:

- Treat n8n as optional `automation` profile.
- Document workflow permissions.
- Add workflow validation and approval tests.

Required before Merlin v1: Yes if automation profile is included.

### Medium: Dashboard directly calls local services

Evidence:

- `dashboard/index.html` fetches Ollama, n8n, Qdrant, and Open WebUI directly from browser JavaScript.

Risk:

- The dashboard cannot enforce policy, hide secrets, or gate actions. If exposed beyond localhost, it becomes a control surface.

Recommended fix:

- Keep dashboard bound to localhost.
- Add a future Merlin backend for controlled actions.
- Avoid adding secret management or risky actions to static JS.

Required before Merlin v1: Partial. Required before adding Magic Mode controls.

### Medium: API key handling is mostly local but not unified

Evidence:

- `.env.example` contains optional provider key names.
- `install.sh` prompts for OpenAI, Anthropic, Perplexity, and GitHub tokens.
- `mcp/codex-config.toml` includes placeholder `ghp_YOUR_TOKEN_HERE`.

Risk:

- Placeholder is not a live secret, but users may copy real tokens into tracked examples or configs.

Recommended fix:

- Document all token storage paths.
- Add `.gitignore` patterns for local MCP configs if users edit them.
- `wizard doctor` should detect likely real tokens in tracked files.

Required before Merlin v1: Yes.

### Medium: Upgrade script uses `eval`

Evidence:

- `scripts/upgrade.sh` implements `run()` with `eval "$*"`.

Risk:

- Current calls are internally constructed, but expanding this pattern could create command injection risk.

Recommended fix:

- Keep upgrade script isolated.
- Replace `eval` with arrays in a future hardening pass.
- Add dry-run tests.

Required before Merlin v1: Recommended.

### Medium: Memory collections and backup targets are partially aligned

Evidence:

- `bootstrap.sh` uses `home_ai_memory`.
- `config/merlin/memory.yaml` now documents canonical and legacy collections.
- `config/merlin/memory-collections.env` now provides the runtime collection manifest for bash scripts.
- `init-qdrant.sh` now creates current/legacy collections from the runtime manifest.
- `backup/backup.sh` now backs up the current legacy/default collection set and supports `MERLIN_BACKUP_COLLECTIONS`.
- `cli/wizard` uses `swarm_memory`, `conversations`, and `documents`.

Risk:

- Memory deletion and audit still cannot be trusted until bootstrap, CLI, workflows, and tests use a stable schema.

Recommended fix:

- Keep legacy collections readable through Merlin v1.
- Add tests for backup dry-run and restore against a live Qdrant instance.
- Migrate CLI and workflows only after restore coverage exists.

Required before Merlin v1: Yes.

### Medium: Watchtower can change runtime images

Evidence:

- `watchtower` service exists and watches labeled containers.

Risk:

- Auto-updates reduce reproducibility and can break a stable local AI install.

Recommended fix:

- Move watchtower to `ops` profile.
- Do not enable by default.
- Prefer explicit `wizard upgrade`.

Required before Merlin v1: Yes.

### Low: Service auth varies by component

Evidence:

- n8n has basic auth.
- Open WebUI requires first account setup but signup starts enabled.
- Qdrant and LiteLLM are bound to localhost but do not provide a full dashboard auth story.

Risk:

- Local-only is acceptable for MVP, but LAN exposure would be dangerous.

Recommended fix:

- Keep localhost binds.
- Add `wizard doctor` check for any `*_BIND=0.0.0.0`.
- Add dashboard warning if signup remains enabled after first setup.

Required before Merlin v1: Yes for doctor warnings.

### Low: Installer performs network downloads

Evidence:

- Homebrew install, brew packages, Docker image pull, Ollama model pull, MCP install, and curl one-line install path.

Risk:

- Expected installer behavior, but conflicts with "no cloud calls by default" unless documented as installation/download behavior.

Recommended fix:

- Distinguish install-time downloads from runtime cloud model calls.
- Ask before large model downloads.

Required before Merlin v1: Recommended.

## Secure Defaults Checklist

- [x] `.env` excluded from git
- [x] `.env` chmod `600`
- [x] Internal secrets auto-generated
- [x] Cloud provider keys optional
- [x] Main Compose ports bind to `127.0.0.1` by default
- [ ] OpenHands behind explicit coding profile
- [ ] n8n behind explicit automation profile
- [ ] Watchtower behind explicit ops profile
- [ ] Magic Mode approval gates
- [ ] Memory write approval
- [ ] Memory delete/audit workflow
- [ ] `wizard doctor` checks insecure binds
- [ ] `wizard doctor` checks default secrets
- [ ] `wizard doctor` checks likely committed tokens
- [ ] Dashboard does not expose secrets
- [ ] No cloud calls by default test
- [ ] Low-memory tier disables heavy services
