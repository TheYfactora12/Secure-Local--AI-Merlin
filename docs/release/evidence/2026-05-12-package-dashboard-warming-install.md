# Package Dashboard Warming Install Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Package

- Built package: `merlin-ai-0.8.6.pkg`
- Build command:

```bash
bash pkg/build-pkg.sh
```

## Install Verification

Interactive package verification was run from Terminal so macOS could request the administrator password through the Merlin prompt.

```bash
MERLIN_PKG_VERIFY_TIMEOUT_SECONDS=420 MERLIN_PKG_VERIFY_INTERVAL_SECONDS=15 \
  bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

Local evidence log:

- `docs/release/evidence/local/pkg-install-verification-2026-05-12-025045Z.log`

Final verification result:

- Package receipt found: `com.merlin.ai`
- System payload exists: `/usr/local/merlin-ai`
- User runtime folder exists: `~/merlin-ai`
- Install log exists and contains completion/progress markers.
- Dependency install manifest exists.
- Launchd agents registered:
  - `com.merlin.docker`
  - `com.merlin.stack`
  - `com.merlin.status-api`
  - `com.merlin.task-api`
- Final summary: `17 pass, 0 warn, 0 fail`

## Endpoint Verification

After package install verification, these installed-runtime endpoint checks returned HTTP 200:

```text
200 http://localhost:8888
200 http://localhost:3000
200 http://localhost:4000/health/readiness
200 http://localhost:6333/healthz
200 http://localhost:11434/api/tags
200 http://localhost:8765/healthz
200 http://localhost:8766/status/routes
```

## Dashboard Payload Verification

The installed dashboard at `http://localhost:8888` contains the new warming/onboarding surface:

- `startup-warming-card`
- `Merlin is warming up`
- `Merlin can start chat`
- `renderStartupWarming`
- `data-start-chat-action`

## Status API Privacy Check

Installed status API reported:

- `privacy_mode`: `local_only`
- `cloud_allowed`: `false`
- `online_mode`: `false`
- `execution_allowed`: `false`
- `active_profile`: `core`

## Notes

- The first three verification attempts showed expected warmup behavior while APIs restarted after package upgrade.
- Attempt 4 passed with all package, launchd, and endpoint checks green.
- Package is unsigned; Developer ID signing/notarization remains deferred by product decision.
