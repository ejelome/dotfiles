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
**Prose dispatch:** `(demo run)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo route

## Steps

1. Resolve the route.

## Notes

- The prose dispatch form is executable and can be invoked directly.
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject direct-execution prose dispatch framing"
assert_contains "$output" "prose dispatch direct-execution wording needs a routing-only/reference-only qualifier"

echo "PASS: check-cursor-content rejects direct-execution prose dispatch framing"
