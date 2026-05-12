# 2026-05-11 - Package Install Python 3.9 Runtime Fix

## Target

Fix the task API failure discovered during a real admin-password `.pkg` install
verification run.

## Starting Point

- Starting commit: `5c3aed9dc4de4f66b85ffb0b356a0dd466584f45`
- Package install command launched in a real macOS Terminal:

```bash
bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

## Evidence

Local generated evidence log:

```text
docs/release/evidence/local/pkg-install-verification-2026-05-12-012653Z.log
```

The package installed successfully:

```text
installer: The install was successful.
```

The verifier passed package receipt, package payload, user runtime folder,
install log, dependency manifest, launchd registration, Dashboard, Open WebUI,
LiteLLM, Qdrant, Ollama, and the Merlin status API.

The verifier failed on the Merlin task API:

```text
FAIL Merlin task API is not reachable yet (http://localhost:8766/status/routes, HTTP 000)
```

Task API log root cause:

```text
ImportError: cannot import name 'UTC' from 'datetime'
```

After replacing `datetime.UTC`, the Python 3.9 import check exposed a second
runtime compatibility issue:

```text
ImportError: cannot import name 'ParamSpec' from 'typing'
```

## Root Cause

The package-created runtime used the system Python 3.9 interpreter. Some Merlin
runtime modules assumed newer Python behavior:

- `datetime.UTC` is not available in Python 3.9.
- `ParamSpec` must come from `typing_extensions` on Python 3.9.
- Pydantic also needs `eval_type_backport` to evaluate newer style annotations
  under Python 3.9.

## Fix

- Replaced Merlin runtime `from datetime import UTC` imports with
  `timezone.utc` constants compatible with Python 3.9+.
- Changed `merlin/policy_engine.py` to import `ParamSpec` from
  `typing_extensions`.
- Added runtime dependencies:
  - `eval_type_backport>=0.2,<1`
  - `typing_extensions>=4.10,<5`
- Updated the installer dependency check so existing virtualenvs install the
  compatibility packages when missing.
- Updated package smoke tests to prevent regression.
- Updated package postinstall to sync package code into an existing
  `~/merlin-ai` runtime instead of skipping copy on reinstall.

## Validation

```bash
/Users/kevinmedeiros/merlin-ai/.venv/bin/python -m pip install 'eval_type_backport>=0.2,<1'
/Users/kevinmedeiros/merlin-ai/.venv/bin/python -m pip install 'typing_extensions>=4.10,<5'
PYTHONPATH=/Users/kevinmedeiros/home-ai-elite /Users/kevinmedeiros/merlin-ai/.venv/bin/python -c 'import merlin.task_endpoint'
bash tests/pkg-readiness-smoke.sh
bash -n install.sh pkg/scripts/postinstall merlin/policy_engine.py
git diff --check
```

Result:

```text
task endpoint import ok on package Python
PASS: package readiness checks are valid
```

## Remaining Work

Rebuild `merlin-ai-0.8.6.pkg`, reinstall with
`bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg`, and verify
the task API now passes from the package-installed runtime.

## Follow-Up Package Verification

After applying the fix, the package was rebuilt and reinstalled through the
guided runner:

```bash
bash pkg/build-pkg.sh
bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

Evidence log:

```text
docs/release/evidence/local/pkg-install-verification-2026-05-12-013812Z.log
```

Installer result:

```text
installer: The upgrade was successful.
```

Final verifier result:

```text
Summary: 17 pass, 0 warn, 0 fail
Merlin package install verification passed.
Finished: 2026-05-12T01:39:22Z
```

Services verified by the guided runner:

- Package receipt: `com.merlin.ai`
- System payload: `/usr/local/merlin-ai`
- User runtime: `~/merlin-ai`
- Install log: `/tmp/merlin-ai-install.log`
- Dependency manifest: `~/.merlin/install-manifest.json`
- Launchd agents:
  - `com.merlin.docker`
  - `com.merlin.stack`
  - `com.merlin.status-api`
  - `com.merlin.task-api`
- Local endpoints:
  - Dashboard `http://localhost:8888`
  - Open WebUI `http://localhost:3000`
  - LiteLLM `http://localhost:4000/health/readiness`
  - Qdrant `http://localhost:6333/healthz`
  - Ollama `http://localhost:11434/api/tags`
  - Merlin status API `http://localhost:8765/healthz`
  - Merlin task API `http://localhost:8766/status/routes`

CI:

```text
25707902971 - success
```
