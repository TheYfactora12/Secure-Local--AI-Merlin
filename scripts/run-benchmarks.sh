#!/usr/bin/env bash
# Offline Merlin memory benchmark runner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

PYTHON_BIN="${MERLIN_PYTHON:-}"
if [[ -z "$PYTHON_BIN" && -x "${STACK_DIR}/.venv/bin/python" ]]; then
  PYTHON_BIN="${STACK_DIR}/.venv/bin/python"
elif [[ -z "$PYTHON_BIN" && -x "${STACK_DIR}/.venv-test/bin/python" ]]; then
  PYTHON_BIN="${STACK_DIR}/.venv-test/bin/python"
elif [[ -z "$PYTHON_BIN" ]]; then
  PYTHON_BIN="python3"
fi

usage() {
  cat <<'EOF'
Usage:
  scripts/run-benchmarks.sh --suite <epbench|memoryarena|amabench|all> [--profile offline]

Options:
  --suite <name>        Benchmark suite to run, default epbench
  --profile offline     Offline deterministic profile. Live profiles are future work.
  --top-k <n>           Retrieval cutoff, default 5
  --jsonl-out <path>    Optional JSONL output path

This runner is offline-safe. It does not require Qdrant, Ollama, LiteLLM, n8n,
Docker, cloud keys, or network access.
EOF
}

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --suite|--profile|--top-k|--jsonl-out|--min-recall-at-5)
      [[ -n "${2:-}" ]] || { echo "ERROR: $1 requires a value" >&2; exit 1; }
      ARGS+=("$1" "$2")
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${#ARGS[@]}" -eq 0 ]]; then
  ARGS=(--suite epbench --profile offline)
fi

cd "$STACK_DIR"
PYTHONPATH="$STACK_DIR" "$PYTHON_BIN" -m tests.benchmarks.run "${ARGS[@]}"
