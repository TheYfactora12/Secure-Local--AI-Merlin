# Merlin Implementation Roadmap

## Guiding Rules

- Protect the working installer.
- Keep changes small and reviewable.
- Do not make cloud calls default.
- Do not make heavy services mandatory.
- Do not silently learn into memory.
- Do not add a heavy agent framework before core is stable.

## Milestone 0: Protect Working Installer and Document Current State

Tasks:

- Keep `install.sh` as baseline.
- Add baseline documentation.
- Add regression checklist for installer.
- Identify current service/profile assumptions.
- Capture "do not break" list.

Risks:

- Documentation drifts from code.
- Existing installer defects get mixed with new architecture work.

Tests:

- `bash -n install.sh`
- `bash -n scripts/*.sh`
- `docker compose config --quiet`
- non-interactive install smoke test when Docker is available

Acceptance criteria:

- Current behavior is documented.
- Installer protection list exists.
- No application code changed.

## Milestone 1: Add Architecture Docs, Config Model, and Health Checks

Tasks:

- Define profiles: `core`, `search`, `automation`, `coding`, `security`, `ops`, `full`.
- Define hardware tiers.
- Draft future `config/merlin/*.yaml` structure.
- Add `wizard doctor` design.
- Split test plan by profile.

Risks:

- Config model becomes too large before implementation.

Tests:

- Documentation review.
- Static config validation once config files exist.

Acceptance criteria:

- Profiles are agreed.
- Hardware tier rules are agreed.
- Health check requirements are documented.

## Milestone 2: Add Merlin Core Interface Without Changing All Existing Services

Tasks:

- Add a thin Merlin command/API facade.
- Read current `.env`, hardware tier, and service state.
- Expose status and route decision dry-run.
- Do not replace Open WebUI or LiteLLM.

Risks:

- Duplicating `wizard` CLI responsibilities.

Tests:

- Merlin status returns service/profile/tier.
- No cloud calls.
- No service startup side effects in status mode.

Acceptance criteria:

- Merlin can report system state without changing runtime behavior.

## Milestone 3: Add Model Router

Tasks:

- Keep LiteLLM as gateway.
- Add Merlin route decision logic.
- Route by task type, privacy, hardware tier, online mode, and model availability.
- Log route decisions.

Risks:

- Static LiteLLM config and Merlin router conflict.

Tests:

- Sensitive task always local.
- Offline mode never selects cloud.
- Missing local model returns clear fallback/action.
- Low tier avoids heavy models.

Acceptance criteria:

- Router chooses correct backend in dry-run and live local calls.

## Milestone 4: Add Memory Layer

Tasks:

- Define canonical Qdrant collections.
- Add memory write approval flow.
- Add memory deletion.
- Add audit trail.
- Align backup/restore with canonical collections.

Risks:

- Memory poisoning.
- Silent retention of private data.

Tests:

- Memory write requires approval.
- Memory delete works.
- Backup/restore covers canonical collections.
- RAG retrieval does not include deleted memory.

Acceptance criteria:

- Memory is explicit, auditable, and restorable.

## Milestone 5: Add Magic Mode Planner

Tasks:

- Add plan-only Magic Mode.
- Break goals into steps.
- Mark tool/action risk.
- Add approval requirements.
- Add pause/stop semantics.

Risks:

- Users mistake plan-only mode for full automation.
- Agents perform actions without policy gates.

Tests:

- Risky steps require approval.
- Stop/pause works in simulation.
- Plan is logged.

Acceptance criteria:

- Magic Mode can plan safely without executing risky actions.

## Milestone 6: Add Dashboard Improvements

Tasks:

- Show profile and hardware tier.
- Show local-only/online mode.
- Show installed models.
- Show service groups by profile.
- Add Magic Mode plan/status UI.
- Add memory approval UI once backend exists.

Risks:

- Static UI attempts privileged actions without backend policy.

Tests:

- Dashboard never displays secrets.
- Dashboard handles offline services gracefully.
- Dashboard warnings match hardware tier.

Acceptance criteria:

- Non-technical user can understand system state and next steps.

## Milestone 7: Add Security Hardening and Approval Gates

Tasks:

- Move high-risk services behind profiles.
- Add approval policy for shell, files, network, cloud, memory, OpenHands.
- Add local-only enforcement tests.
- Add token leak checks.

Risks:

- Approval prompts become annoying and users disable them.

Tests:

- No cloud calls by default.
- `0.0.0.0` bind warning.
- OpenHands disabled until coding profile enabled.
- Shell/file/network actions blocked without approval.

Acceptance criteria:

- Magic Mode and agents cannot perform risky actions silently.

## Milestone 8: Add Hardware-Tier Optimization

Tasks:

- Use detected RAM and OS to suggest profile/model tier.
- Add dashboard warnings.
- Add low-memory mode.
- Ask before large model pulls.

Risks:

- Overblocking advanced users.

Tests:

- 8 GB tier does not start heavy services.
- 16-24 GB tier defaults to core.
- User override is possible and logged.

Acceptance criteria:

- Installer scales safely from low-end to high-end Macs.

## Milestone 9: Testing, Packaging, and Release Readiness

Tasks:

- Profile-specific smoke tests.
- Installer regression tests.
- Backup/restore test.
- Upgrade/rollback test.
- Package test on clean macOS.
- Changelog and release notes.

Risks:

- Packaging hides install failures.

Tests:

- Clean install.
- Non-interactive install.
- Skip model pulls.
- Core profile.
- Optional profiles.
- Package install/uninstall.

Acceptance criteria:

- v1 release can be installed, verified, upgraded, backed up, restored, and uninstalled.

## Do Not Do Yet

- Do not replace `install.sh`.
- Do not replace LiteLLM.
- Do not replace Open WebUI.
- Do not add a mandatory LangChain/LangGraph/OpenAI Agents SDK dependency.
- Do not make OpenHands default.
- Do not make n8n required for basic chat.
- Do not enable cloud fallback by default.
- Do not auto-learn memory without approval.
- Do not implement autonomous Magic Mode before approval gates.

## Recommended First 3 GitHub Issues

1. Add profile model and core-first startup plan without changing installer behavior.
2. Add `wizard doctor` requirements and implementation.
3. Normalize Merlin memory schema and align bootstrap, CLI, backup, restore, and tests.
