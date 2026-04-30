#!/usr/bin/env bash
cat <<'TXT'

========================================
  Home AI Elite — Manual Setup Checklist
========================================

1. Open WebUI first account
   - Go to: http://localhost:3001
   - Create your admin user
   - Settings > Connections: confirm Ollama URL = http://host.docker.internal:11434
   - Select your default local model

2. n8n owner account
   - Go to: http://localhost:5678
   - Create the owner account
   - Add credentials for OpenAI / Perplexity / Anthropic if you provided API keys
   - Import starter workflow: n8n-workflows/ai-router-starter.json

3. Qdrant (optional manual check)
   - Go to: http://localhost:6333/dashboard
   - Confirm collections are accessible

4. Perplexity MCP (optional — later step)
   - Open Perplexity Mac app
   - Settings > Connectors
   - Add connector pointing to your local MCP server

5. Run a health check
   - ./scripts/status.sh

========================================
TXT
