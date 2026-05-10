#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions" "$tmp/rules" "$tmp/_mdc"

cat >"$tmp/commands/demo.md" <<'EOF'
# /demo

Route demo workflows.

## Trigger

**Slash:** `/demo`
**Signature:** `/demo <run>`
**Phrases:** demo run, run demo

## Steps

1. Resolve the route.

## Notes

- **Parameters:** `<run>` — required route selector.
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject old trigger shape"
assert_contains "$output" "trigger contract expected exactly one '**Prose dispatch:**' line"

echo "PASS: check-cursor-content rejects old trigger shape"
