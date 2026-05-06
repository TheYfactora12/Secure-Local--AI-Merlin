# Test Strategy

Last updated: 2026-05-06

## Goal

Keep the working installer safe while Merlin evolves into a local-first command center.

## Test Layers

| Layer | Purpose | Examples |
| --- | --- | --- |
| Static shell tests | Catch syntax and contract drift | `bash -n`, smoke scripts |
| Config tests | Validate canonical config and safe defaults | config loader, config-root smoke |
| Python unit tests | Validate Merlin core modules | policy, router, memory, task endpoint |
| Security tests | Prevent secret and policy regressions | gitleaks, redaction, no raw input |
| Integration tests | Validate live local services when opted in | Qdrant/Ollama/LiteLLM live tests |
| Manual tests | Validate real install and UX | clean install, dashboard, doctor |
| Release tests | Validate packaging/upgrade/rollback | package smoke, uninstall, backup/restore |

## Installer Regression

Automated:

- `bash -n install.sh`
- `docker compose config --quiet`
- profile selection smoke tests
- model pull policy smoke tests
- package readiness smoke tests

Manual:

- Clean core install.
- Non-interactive core install with model pulls skipped.
- Re-run installer after partial failure.
- Confirm `.env` secrets generated and not printed.

## Hardware Detection

Automated:

- Doctor smoke reports tier.
- 8GB low tier mapping test.
- Profile warnings for heavy services.

Manual:

- Validate on M1/M2 8GB.
- Validate on 16GB-24GB.
- Validate on 32GB+ if available.

## Doctor Command

Automated:

- `tests/doctor-smoke.sh`
- syntax checks
- log grep set-e guards

Manual:

- Run `wizard doctor` with Docker down.
- Run with Docker up.
- Run with task/status APIs down.

## Dashboard

Automated:

- dashboard smoke tests
- no-secret string scans
- status API degraded tests

Manual:

- Open dashboard with all services stopped.
- Open with core profile running.
- Confirm local-only, hardware tier, model, memory, approval, and trace states.

## Services Start/Stop

Automated:

- profile start script smoke tests.
- launchd smoke tests.

Manual:

- `wizard start core`
- `wizard start search`
- `wizard start automation`
- `wizard start coding`
- `wizard stop`

Low-memory machines should warn before optional heavy profiles.

## Local-Only Mode

Automated:

- No cloud calls by default.
- External provider disabled state.
- LiteLLM local alias tests.

Manual:

- Remove cloud keys and confirm core still works.
- Confirm dashboard says cloud disabled.

## Secret Handling

Automated:

- gitleaks.
- regex secret scan.
- redaction smoke tests.
- report-bug smoke tests.

Manual:

- Generate report with fake secrets.
- Confirm no API keys are printed in doctor/dashboard/logs.

## Memory Approval

Automated:

- Memory write requires approval.
- Denied writes nothing.
- Qdrant unreachable degrades.
- Dimension mismatch raises.
- Delete path tests.

Manual:

- Remember a preference.
- Deny a memory request.
- Delete a memory item.
- Search memory after approval.

## Magic Mode

Automated:

- Plan-only smoke tests.
- Assert no shell/file/git/n8n/OpenHands execution.
- Approval gates present in plan.

Manual:

- Plan a multi-step goal.
- Confirm every risky step is blocked.
- Confirm stop/pause language is visible.

## Model Router

Automated:

- Route all configured route IDs.
- Unknown input fallback.
- Risky routes return gates.
- Low-memory fallback/warning tests.

Manual:

- Ask general, code, search, automation, memory prompts.
- Confirm route and model alias make sense.

## Agent Permissions

Automated:

- Policy gate tests for all permissions.
- Fail-closed config tests.

Manual:

- Attempt shell/file/git/OpenHands/n8n action.
- Confirm approval required and no action happens.

## Audit Logging

Automated:

- No raw input in traces.
- Hash fields present.
- Redaction tests.

Manual:

- Review route, approval, and memory audit records.

## Performance

Automated:

- Core install budget smoke.
- Low-memory start profile checks.

Manual:

- On 8GB: core only, one 7B model, Qdrant small memory.
- On 16GB+: optional search.
- On 32GB+: automation/coding explicit tests.

## Release Readiness Checklist

- [ ] CI green.
- [ ] Secret scans green.
- [ ] Installer syntax and compose validation green.
- [ ] Python tests green.
- [ ] Static smoke tests green.
- [ ] Core install manual validation.
- [ ] Doctor manual validation.
- [ ] Dashboard manual validation.
- [ ] Backup/restore validation.
- [ ] Uninstall validation.
- [ ] Release notes updated.
