#!/usr/bin/env bash
set -euo pipefail

DOC="docs/architecture/MERLIN_STAFF_SKILL_EVALUATION.md"

[[ -f "$DOC" ]] || { echo "missing $DOC"; exit 1; }

grep -q "Do not add a seventh staff mode yet" "$DOC"
grep -q "Compliance Officer" "$DOC"
grep -q "Security Reviewer workflow" "$DOC"
grep -q "No new staff mode" "$DOC"
grep -q "8GB behavior" "$DOC"
grep -q "file_read" "$DOC"
grep -q "memory_write" "$DOC"

echo "PASS: Merlin staff skill evaluation is present and v1-safe"
