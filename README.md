# Home AI Elite

A one-shot interactive installer for a local-first home AI stack on macOS Apple Silicon.

## What it installs

| Service | What it does | Port |
|---|---|---|
| Ollama | Runs local AI models | 11434 |
| Open WebUI | Chat interface — your front door | 3001 |
| n8n | Orchestration and routing switchboard | 5678 |
| Qdrant | Vector memory store | 6333 |
| OpenHands (optional) | Autonomous coding agent | 3000 |

## Quick start

```bash
git clone https://github.com/TheYfactora12/home-ai-elite.git
cd home-ai-elite
bash install.sh
```

The installer will:
1. Run preflight checks (RAM, disk, ports).
2. Prompt for install location, models, secrets, and optional API keys.
3. Install Homebrew dependencies if missing.
4. Walk you through Docker Desktop setup.
5. Pull your chosen Ollama models.
6. Start all services.
7. Print a manual checklist for the remaining in-app account setup.

## After install

| Task | URL |
|---|---|
| Open WebUI admin setup | http://localhost:3001 |
| n8n owner account | http://localhost:5678 |
| Qdrant dashboard | http://localhost:6333/dashboard |

## Scripts

```bash
./scripts/status.sh   # health check
./scripts/stop.sh     # stop all containers
./scripts/restart.sh  # restart stack
./scripts/backup.sh   # snapshot config and data
./scripts/update.sh   # pull latest images
./scripts/uninstall.sh
```

## Optional: MCP servers

```bash
bash mcp/install-mcp-servers.sh
```

Then register connectors in Perplexity Settings > Connectors.

## Architecture

```
You
 └── Open WebUI (http://localhost:3001)
      └── n8n Router (http://localhost:5678)
           ├── LOCAL: Ollama Qwen3 32B (http://localhost:11434) — free
           ├── RESEARCH: Perplexity sonar-pro API — ~$0.001/search
           ├── CODING: OpenAI API — ~$0.015/1K tokens
           └── OVERNIGHT: OpenHands agent (http://localhost:3000)
                └── Qdrant memory (http://localhost:6333)
```

## Roadmap

See [ROADMAP.md](ROADMAP.md).

## License

MIT
