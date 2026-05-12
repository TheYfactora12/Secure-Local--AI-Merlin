# Package Check System And Recovery Install Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Package

- Built package: `merlin-ai-0.8.6.pkg`
- Package size after rebuild: 8.2 MB
- Build command:

```bash
bash pkg/build-pkg.sh
```

## Install Verification

Interactive package verification was run from Terminal so macOS could request the administrator password through the Merlin prompt.

```bash
MERLIN_PKG_VERIFY_TIMEOUT_SECONDS=420 MERLIN_PKG_VERIFY_INTERVAL_SECONDS=15 \
  bash scripts/run-pkg-install-verification.sh ./merlin-ai-0.8.6.pkg
```

Local evidence log:

- `docs/release/evidence/local/pkg-install-verification-2026-05-12-041132Z.log`

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

## Installed Dashboard Verification

The installed dashboard at `http://localhost:8888` contains the latest batched onboarding copy:

- `Check System`
- `Service details`
- `Startup checks`
- `If Merlin stays warming`
- `What to send us`
- `Do not add API keys or cloud providers to fix startup`
- `tail -n 120 /tmp/merlin-ai-install.log`

## Notes

- The first verification attempts showed expected post-upgrade warmup while APIs restarted.
- Attempt 4 passed with all package, launchd, and endpoint checks green.
- Package is unsigned; Developer ID signing/notarization remains deferred by product decision.
