# 2026-05-10 Clean Install And Uninstall Progress

## Date/time

2026-05-10 22:29:37 EDT

## Branch

`main`

## Starting commit SHA

`72e925572c60b957666925610cf364806421fc98`

## Ending commit SHA

`3e2756a48f5505bfbec9933125b42bf2a0c10a4d`

## Target issue(s)

#37, #95, #134

## Scope

Validate the v1.0 trust path after the Merlin AI reset:

- purge uninstall,
- reinstall core profile,
- verify no surprise model downloads,
- explicitly add the local chat model,
- verify local services and local model routing,
- fix any uninstall defect found during the evidence pass.

## Files changed

- `pkg/scripts/uninstall.sh`
- `tests/uninstall-smoke.sh`
- `docs/release/evidence/2026-05-10-clean-install-uninstall-progress.md`

## Protected files touched

- `pkg/scripts/uninstall.sh`

Reason: a real uninstall purge defect was found during live evidence. The fix is
scoped to Ollama model-name matching during explicit `--purge-models` /
`--purge-all`; it does not change default uninstall behavior.

## Commands run

- `git status --short --branch && git rev-parse HEAD`
- `bash install.sh --help`
- `bash pkg/scripts/uninstall.sh --help`
- `bash pkg/scripts/uninstall.sh --dry-run --purge-all`
- `docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'`
- `ollama list`
- `bash pkg/scripts/uninstall.sh --yes --purge-all`
- `docker ps -a --format '{{.Names}}\t{{.Status}}' | rg 'open-webui|litellm|qdrant|swarm-dashboard|home-ai|merlin' || true`
- `docker volume ls --format '{{.Name}}' | rg 'home-ai|merlin|qdrant|open-webui' || true`
- `ls -1 ~/Library/LaunchAgents | rg 'homeai|merlin' || true`
- `curl -fsS --max-time 3 http://localhost:8888`
- `ollama rm nomic-embed-text`
- `ollama list`
- `bash -n pkg/scripts/uninstall.sh`
- `bash -n tests/uninstall-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`
- `bash tests/core-live-smoke.sh`
- `docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'`
- `python3` one-off `.env` privacy check for permissions and cloud key presence
- `curl -fsS --max-time 10 http://localhost:8888`
- `curl -fsS --max-time 10 http://localhost:3000`
- `curl -fsS --max-time 10 http://localhost:4000/health/readiness`
- `curl -fsS --max-time 10 http://localhost:6333/healthz`
- `curl -fsS --max-time 10 http://localhost:11434/api/tags`
- `bash scripts/add-model.sh qwen2.5:7b`
- `pkgutil --pkg-info com.homeai.elite`
- `bash scripts/status.sh`
- `git diff --check`
- `bash -n install.sh`
- `bash -n pkg/scripts/uninstall.sh`
- `bash -n scripts/uninstall.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/installer-model-pull-policy-smoke.sh`
- `gh run watch 25647208534 --exit-status`

## Test output summary

- Uninstall dry-run showed purge-all would remove Docker volumes/images,
  launchd agents, package receipt, and Merlin-recommended Ollama models.
- Live `bash pkg/scripts/uninstall.sh --yes --purge-all` exited 0.
- Docker containers, Merlin Docker volumes, stack images, and launchd agents
  were removed.
- Dashboard was down after purge, as expected.
- Core reinstall with
  `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`
  completed successfully.
- Reinstall started dashboard, Open WebUI, LiteLLM, Qdrant, and native Ollama.
- Reinstall explicitly skipped Ollama model pulls.
- `.env` exists with mode `600`.
- Optional cloud keys checked: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`,
  `PERPLEXITY_API_KEY`, and `GITHUB_TOKEN` were not set.
- First `bash tests/core-live-smoke.sh` after reinstall: 15 passed, 2 warnings,
  0 failures. Warnings were expected because purge removed all generation
  models and reinstall did not surprise-download models.
- Explicit `bash scripts/add-model.sh qwen2.5:7b` downloaded the local chat
  model.
- Second `bash tests/core-live-smoke.sh`: 18 passed, 0 warnings, 0 failures.
- `bash scripts/status.sh` showed core services running and optional search,
  automation, and coding profiles disabled.
- `bash tests/uninstall-smoke.sh`: PASS after regression test addition.
- `bash tests/pkg-readiness-smoke.sh`: PASS.
- `bash tests/installer-model-pull-policy-smoke.sh`: PASS.
- `git diff --check`: PASS.
- GitHub Actions run `25647208534` on
  `3e2756a48f5505bfbec9933125b42bf2a0c10a4d`: PASS.

## Tests skipped and why

- Full macOS `.pkg` double-click install was not run in this pass; the evidence
  used the script path from the repo checkout.
- Developer ID/notarization validation skipped by product decision.
- Open WebUI authenticated browser chat was not validated because a clean WebUI
  state requires first-run admin account setup in browser.

## Failures found

1. `--purge-all` left `nomic-embed-text:latest` installed even though the
   uninstaller claimed Merlin-recommended Ollama models were removed when
   present.
2. `--purge-all` could not forget package receipt `com.homeai.elite` without
   admin privileges.
3. After clean reinstall with model pulls disabled, local chat generation was
   unavailable until `qwen2.5:7b` was explicitly added.

## Failure category

- Uninstall
- Ollama/native model runtime
- Non-interactive mode
- UX/readiness confusion
- Installer flow

## Root cause or current hypothesis

1. Ollama reports untagged models as `:latest` in `ollama list`. The manifest
   listed `nomic-embed-text`, while the installed model appeared as
   `nomic-embed-text:latest`, so the exact-match purge check skipped it.
2. Package receipt cleanup requires admin privileges. The uninstaller avoids
   blocking non-interactive uninstall and prints a manual `sudo pkgutil --forget`
   command instead.
3. No model after reinstall is expected degraded behavior because
   `HOME_AI_SKIP_MODEL_PULLS=true` is protected and model downloads are explicit.

## Fix applied

- Added `ollama_model_is_installed` in `pkg/scripts/uninstall.sh` so a manifest
  entry without a tag matches an installed `:latest` model.
- Added a fake-Ollama regression path in `tests/uninstall-smoke.sh` proving
  `qwen2.5:7b` and `nomic-embed-text:latest` both trigger the expected purge
  commands.
- Manually removed the leftover `nomic-embed-text` from this machine with
  `ollama rm nomic-embed-text`.

## Retest result

- `bash tests/uninstall-smoke.sh`: PASS.
- `ollama list` after manual cleanup: empty before reinstall/model add.
- Clean reinstall with model pulls disabled: PASS.
- `bash tests/core-live-smoke.sh` immediately after reinstall: PASS with 2
  expected no-model warnings.
- `bash scripts/add-model.sh qwen2.5:7b`: PASS.
- `bash tests/core-live-smoke.sh` after explicit model add: PASS, 18 passed,
  0 warnings, 0 failures.

## Regression test added or reason not added

Added a fake-Ollama regression test to `tests/uninstall-smoke.sh` to verify
untagged manifest names still remove installed `:latest` model listings.

## Follow-up issues created or recommended

Recommended:

1. Provide a user-friendly privileged uninstall path that can remove/forget the
   macOS package receipt with a clear admin prompt when running from a packaged
   installer.
2. Add onboarding copy that explains the no-model state after a clean no-pull
   install and guides the user to `bash scripts/add-model.sh qwen2.5:7b` or the
   eventual UI equivalent.
3. Run the same purge/reinstall test through the `.pkg` path before Local
   Trusted Beta signoff.

## Lesson learned

Uninstall tests must simulate real tool output, not only dry-run command text.
Ollama's `:latest` display format can hide leftovers if the test only checks
manifest command generation.

## What not to repeat next time

Do not trust a purge summary without checking post-uninstall state with
`docker ps`, `docker volume ls`, `ollama list`, launchd agent listing, and
service ports.

## Next recommended step

Commit the uninstall fix and evidence note, wait for CI, then schedule a
package-path clean install/uninstall/reinstall test.

## Local Trusted Beta impact

Improved. A real purge defect was found, fixed, regression-tested, and retested.
Core script install now has fresh evidence for no-cloud/no-surprise-model-pull
behavior and local model routing after explicit model add.

## Public Beta impact

Public Beta remains blocked. The package-path clean install/uninstall/reinstall
test and first-run browser onboarding proof still need evidence.
