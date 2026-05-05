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
