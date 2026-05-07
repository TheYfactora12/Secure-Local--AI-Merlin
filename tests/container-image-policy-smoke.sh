#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY="${ROOT_DIR}/docs/engineering/CONTAINER_IMAGE_POLICY.md"
COMPOSE_FILES=(
  "${ROOT_DIR}/docker-compose.yml"
  "${ROOT_DIR}/docker-compose.base.yml"
  "${ROOT_DIR}/docker-compose.openhands.yml"
)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$POLICY" ]] || fail "missing container image policy doc"

floating_images="$(
  {
    awk '/^[[:space:]]*image:[[:space:]]*/ {
      sub(/^[[:space:]]*image:[[:space:]]*/, "")
      gsub(/["'\'' ]/, "")
      print
    }' "${COMPOSE_FILES[@]}"

    grep -hE 'SANDBOX_RUNTIME_CONTAINER_IMAGE[:=]' "${COMPOSE_FILES[@]}" \
      | sed -E 's/.*SANDBOX_RUNTIME_CONTAINER_IMAGE[:=][[:space:]]*//; s/^["'\'' ]+//; s/["'\'' ]+$//'
  } | grep -E ':(latest|main|main-latest|alpine)$' | sort -u
)"

[[ -n "$floating_images" ]] || fail "expected at least one floating image to be documented"

while IFS= read -r image; do
  [[ -n "$image" ]] || continue
  grep -Fq "\`${image}\`" "$POLICY" \
    || fail "floating image is not documented in docs/engineering/CONTAINER_IMAGE_POLICY.md: ${image}"
done <<< "$floating_images"

grep -Fq "Pinning Priority" "$POLICY" \
  || fail "container image policy must include pinning priority"

echo "PASS: floating container image tags are documented"
