# macOS Smoke Test Evidence - 2026-05-03

## Decision

Preserve sanitized smoke-test logs on a dedicated evidence branch, separate from `main`, so review tools can inspect installer behavior without mixing runtime artifacts into release code.

## Reasoning Summary

These logs capture the local macOS installer validation that led to the `v1.6-smoke-pass` tag and later model-routing/runtime-hygiene fixes. Raw runtime logs can include host paths, tokens, cookies, generated secrets, or environment values, so this folder contains redacted copies only.

Source directory:

```text
/private/tmp/home-ai-elite-realtest-logs
```

Branch:

```text
evidence/2026-05-03-macos-smoke
```

## Contents

- `install.log` - installer history from the local macOS test machine
- `current-wizard-install.log` - latest `~/.wizard/install.log` snapshot after follow-up checks
- `docker-compose-ps.txt` - Compose service state captured after install
- `docker-compose-logs-tail200.txt` - tail of stack logs after install
- `endpoint-probes.txt` - HTTP endpoint probe results
- `e2e-test.txt` - local end-to-end test output
- `ollama-list.txt` - locally installed Ollama model list

## Risks / Unknowns

- Redaction is pattern-based and should be reviewed before wider sharing.
- Logs are evidence from one Mac, not a universal guarantee across hardware.
- Runtime warnings in logs may reflect transient container startup state.
- This branch should not be merged into `main` unless the project intentionally adopts an evidence archive policy.

## Next Actions

Use these files for AI-assisted review of:

- installer failure history and final pass state
- model tier alignment
- n8n and dashboard startup behavior
- Docker Compose service health
- follow-up tickets for operational hardening

## Validation

Before committing, the evidence folder was scanned for common sensitive-value patterns and known project credential variable names.
