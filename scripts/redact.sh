#!/usr/bin/env bash
# Source this file — do not run directly.
[[ "${BASH_SOURCE[0]}" != "${0}" ]] || \
  { echo "Source this file, do not run it directly"; exit 1; }

redact_string() {
  sed -E \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED-AWS-KEY]/g' \
    -e 's/eyJ[A-Za-z0-9_\/+=-]{20,}/[REDACTED-JWT]/g' \
    -e 's/(password|secret|token|api_key|apikey|credential|private)([[:space:]]*=[[:space:]]*)[^[:space:]]*/\1\2[REDACTED]/Ig' \
    -e 's|/Users/[^[:space:]]*|[REDACTED-PATH]|g' \
    -e 's|/home/[^[:space:]]*|[REDACTED-PATH]|g' \
    -e 's/sk-[A-Za-z0-9]{20,}/[REDACTED-API-KEY]/g' \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/[REDACTED-API-KEY]/g'
}
