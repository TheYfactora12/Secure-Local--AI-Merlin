# Tests — home-ai-elite

This folder contains end-to-end validation scripts for the home-ai-elite stack.  
Run these **after** `bootstrap.sh` completes to confirm all services are healthy.

---

## e2e-test.sh

### What it checks

| Check | What it tests | Expected result |
|---|---|---|
| Docker running | Docker daemon is up | `docker info` exits 0 |
| Compose services up | All containers in `docker-compose.yml` are running | All = `running` state |
| Ollama API | `GET /api/tags` on port 11434 | HTTP 200, JSON model list |
| Open WebUI | Port 3000 responds | HTTP 200 or 302 |
| n8n | Port 5678 responds | HTTP 200 or 302 |
| Qdrant | `GET /collections` on port 6333 | HTTP 200, JSON |
| Perplexica | Port 3002 responds | HTTP 200 |
| SearXNG | Port 8080 responds | HTTP 200 |
| LiteLLM | Port 4000 responds | HTTP 200 |

### How to run

```bash
bash ~/home-ai-elite/tests/e2e-test.sh
```

### Expected output (all passing)

```
✅ Docker is running
✅ All compose services are up
✅ Ollama API healthy
✅ Open WebUI healthy
✅ n8n healthy
✅ Qdrant healthy
✅ Perplexica healthy
✅ SearXNG healthy
✅ LiteLLM healthy

🎉 All checks passed — home-ai-elite stack is healthy
```

### Interpreting failures

| Failure message | Likely cause | Fix |
|---|---|---|
| `❌ Docker is not running` | Docker Desktop not open | Open Docker Desktop, wait 30s, retry |
| `❌ Service X is not running` | Container failed to start | `docker compose logs X` to see error |
| `❌ Ollama API not responding` | Ollama not started or wrong port | Run `ollama serve` or check `.env` OLLAMA_BASE_URL |
| `❌ Open WebUI not responding` | Container still initializing | Wait 60s after bootstrap, retry |
| `❌ Qdrant not responding` | Qdrant container failed | `docker compose logs qdrant` |
| `❌ n8n not responding` | n8n port conflict or crash | Check `.env` N8N_PORT, check logs |

### Re-running after a failure

```bash
# Restart the full stack first
bash ~/home-ai-elite/scripts/restart.sh

# Then re-test
bash ~/home-ai-elite/tests/e2e-test.sh
```

---

## Adding new tests

1. Create a new `.sh` file in this folder.
2. Use the same pass/fail pattern:
   ```bash
   curl -sf http://localhost:PORT/endpoint > /dev/null \
     && echo "✅ Service healthy" \
     || { echo "❌ Service not responding"; FAIL=1; }
   ```
3. Add `bash -n tests/your-test.sh` to the `install-dryrun` job in `.github/workflows/ci.yml`.
4. Update the table above.

---

## Running tests in CI

The CI pipeline (`ci.yml`) checks all `tests/*.sh` files for syntax errors using `bash -n`.  
Full service-level tests require a running Docker environment and are run **locally** only.  
Full integration testing in CI (via Docker Compose) is planned for v0.9.

---

## memory-config-smoke.sh

This test does not require Docker. It validates that the Merlin memory runtime
manifest includes the expected legacy/current Qdrant collections and that
`backup/restore.sh --dry-run` can parse a backup archive without contacting
Qdrant.

```bash
bash tests/memory-config-smoke.sh
```

---

## doctor-model-smoke.sh

This test does not require Docker or real Ollama. It injects a fake `ollama`
command and verifies that `scripts/doctor.sh` reports installed and missing
recommended models with exact pull commands.

```bash
bash tests/doctor-model-smoke.sh
```

---

## wizard-memory-config-smoke.sh

This test does not require Docker. It loads `cli/wizard` with a temporary memory
manifest to verify the CLI can source configurable collection names without
breaking basic command loading.

```bash
bash tests/wizard-memory-config-smoke.sh
```

---

## profile-selection-smoke.sh

This test does not require Docker. It validates the shared installer profile
mapping used by `install.sh` and `scripts/bootstrap.sh`, including macOS/Linux
service lists and Linux Compose profiles.

```bash
bash tests/profile-selection-smoke.sh
```

---

## container-image-policy-smoke.sh

This test does not require Docker. It verifies that every floating container
image tag used by Compose files is documented in
`docs/CONTAINER_IMAGE_POLICY.md` with an explicit upgrade policy.

```bash
bash tests/container-image-policy-smoke.sh
```

---

## uninstall-smoke.sh

This test does not remove anything. It validates that the uninstaller has
syntax-safe help, rejects unknown flags, supports dry-run mode, keeps Docker
volumes unless `--remove-data` is explicit, and documents that Ollama models are
preserved.

```bash
bash tests/uninstall-smoke.sh
```

---

## launchd-core-smoke.sh

This test does not install launchd agents. It verifies that macOS auto-start
uses the laptop-safe core profile script and does not start the raw full Compose
stack.

```bash
bash tests/launchd-core-smoke.sh
```

---

## n8n-ollama-retry-smoke.sh

This test does not require live n8n, Ollama, Qdrant, Docker, or cloud keys. It
statically validates every n8n workflow JSON file and requires each Ollama HTTP
Request node to have:

- timeout of at least 90 seconds
- `retryOnFail: true`
- `maxTries: 3` (initial try plus two retries)
- positive `waitBetweenTries`
- `continueOnFail: true` for graceful workflow degradation

```bash
bash tests/n8n-ollama-retry-smoke.sh
wizard test-workflows
```

If a live workflow hits Ollama `context canceled` during model load, wait for
the model to finish loading and rerun the workflow. The static retry contract
means transient slow loads should retry instead of silently dropping the task.

---

## n8n-model-router-policy-smoke.sh

This test does not require live n8n, Ollama, Qdrant, Docker, cloud keys, or
network access. It statically validates `n8n-workflows/ai-router-starter.json`
as a local-first optional router starter:

- workflow ships inactive
- no executable cloud provider HTTP Request nodes
- local Ollama route remains present
- cloud model paths expose `approval_required` metadata
- required cloud gates are listed: `cloud_model_call`, `external_network`,
  `api_key_use`

```bash
bash tests/n8n-model-router-policy-smoke.sh
wizard test-workflows
```

---

## benchmark-smoke.sh

This test does not require live Qdrant, Ollama, LiteLLM, n8n, Docker, cloud
keys, or network access. It validates the offline memory benchmark harness and
the `wizard benchmark run` command.

```bash
bash tests/benchmark-smoke.sh
wizard benchmark run --suite all --profile offline
```

---

## observability-design-smoke.sh

This test validates the v1.6 observability design boundary without starting
services. It proves JSONL remains the default trace store, LiteLLM telemetry is
disabled, no default Langfuse service exists, and any future Langfuse service
must be profile-gated.

```bash
bash tests/observability-design-smoke.sh
```

---

## merlin-score-smoke.sh

This test validates `wizard score` using temporary local JSONL fixtures. It
does not require Langfuse, Qdrant, Ollama, LiteLLM, n8n, Docker, cloud keys, or
network access.

```bash
bash tests/merlin-score-smoke.sh
wizard score
```

---

## merlin-trace-view-smoke.sh

This test validates `wizard trace <id>` using temporary local JSONL fixtures.
It does not require Langfuse, Qdrant, Ollama, LiteLLM, n8n, Docker, cloud keys,
or network access.

```bash
bash tests/merlin-trace-view-smoke.sh
wizard trace <trace_id>
```

---

## langfuse-observability-profile-smoke.sh

This test validates the optional Langfuse profile without starting services. It
proves Langfuse is absent from default Compose, profile-gated in the optional
override, localhost-bound, not on Open WebUI port 3000, and protected by the
low-RAM start guard.

```bash
bash tests/langfuse-observability-profile-smoke.sh
```
