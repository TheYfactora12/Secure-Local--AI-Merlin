#!/usr/bin/env bash
# Home AI Elite — Pull a new Ollama model
# Usage: bash scripts/add-model.sh <model-name>
# Browse: https://ollama.com/library

if [[ -z "${1:-}" ]]; then
  echo "Usage: bash scripts/add-model.sh <model-name>"
  echo ""
  echo "Popular models:"
  echo "  bash scripts/add-model.sh qwen2.5:32b"
  echo "  bash scripts/add-model.sh llama3.3:70b-instruct-q4_K_M"
  echo "  bash scripts/add-model.sh deepseek-r1:14b"
  echo "  bash scripts/add-model.sh mistral:7b"
  echo "  bash scripts/add-model.sh qwen2.5-coder:14b"
  echo ""
  echo "Browse all: https://ollama.com/library"
  exit 1
fi

MODEL="$1"
echo "Pulling: $MODEL"
ollama pull "$MODEL"
echo ""
echo "Done. Model available at http://localhost:11434"
echo ""
ollama list
