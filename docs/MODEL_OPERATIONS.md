# Model Operations Notes

Last updated: 2026-05-04

## Decision

Run local models on demand, keep default routes on base-tier models, and provide an explicit cooldown switch for stuck or expensive generations.

Use:

```bash
wizard brain status
wizard brain stop
wizard brain start
```

`wizard brain stop` is the safe cooling action when the machine starts running hot.

## Reasoning Summary

On macOS, Ollama runs natively so Apple Metal acceleration is available. That is fast, but a single 7B request can still pin CPU/GPU while generating. Larger models increase memory pressure and can make the machine feel unusable on 16 GB hardware.

The v1.6 base tier should prefer:

- General: `qwen2.5:7b`
- Coding: `qwen2.5-coder:7b`
- Reasoning fallback: `deepseek-r1:7b`
- Embeddings: `nomic-embed-text`

Avoid routing default aliases to 14B, 32B, or 70B models unless the installer selected the matching RAM tier and the model is actually pulled.

## Risks / Unknowns

- Browser dashboards and chat UIs can leave a generation running even after the visible page looks idle.
- `ollama stop <model>` may not clear a stuck runner if a request is still attached.
- Stopping native Ollama makes AI calls fail until it is started again, but the Docker stack can stay up.
- Long context windows and large token outputs are the main causes of runaway local load.

## Next Actions

When the computer runs hard:

```bash
wizard brain status
wizard brain stop
```

When ready to use models again:

```bash
wizard brain start
wizard brain status
```

For future optimization work:

- Add per-request `keep_alive` controls to LiteLLM or dashboard calls.
- Add max token defaults per route.
- Add a dashboard "Stop Brain" button wired to a local helper endpoint or CLI bridge.
- Add `wizard doctor` checks for hot Ollama runners and model/RAM mismatch.

## Validation

Healthy idle state:

- `wizard brain status` shows the API running or stopped intentionally.
- `curl http://localhost:11434/api/ps` shows no loaded models when idle.
- `ps` does not show an Ollama runner using high CPU.
- Docker containers remain low CPU in `docker stats --no-stream`.
