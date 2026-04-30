#!/usr/bin/env bash
# Install optional MCP servers for Perplexity and Codex integration
set -euo pipefail

echo "Installing MCP server dependencies..."
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-github

echo "Installing Qdrant MCP via uv..."
uv tool install mcp-server-qdrant || pip install mcp-server-qdrant || true

echo ""
echo "MCP servers installed."
echo ""
echo "To register with Perplexity:"
echo "  1. Open Perplexity > Settings > Connectors"
echo "  2. Add connector: npx @modelcontextprotocol/server-filesystem ~/Projects"
echo "  3. Add connector: uvx mcp-server-qdrant (env: QDRANT_URL=http://localhost:6333)"
echo "  4. Add connector: npx @modelcontextprotocol/server-github (env: GITHUB_PERSONAL_ACCESS_TOKEN=<your_token>)"
