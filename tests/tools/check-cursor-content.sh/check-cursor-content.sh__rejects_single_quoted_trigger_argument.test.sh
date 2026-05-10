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
**Signature:** `/demo write 'hello world'`
**Prose dispatch:** `(demo write 'hello world')` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo write

## Steps

1. Resolve the route.

## Notes

- **Parameters:** text — required text.
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject single-quoted trigger arguments"
assert_contains "$output" "invalid quote: single quotes are not a valid wrapper; use double quotes"

echo "PASS: check-cursor-content rejects single-quoted trigger argument"
