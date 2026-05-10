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
**Signature:** `/demo <speak>`
**Prose dispatch:** `(demo speak)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo route

## Steps

1. Resolve the route.

## Notes

- Example: `(collab speak This is the message body)` writes `This is the message body` into the transcript.
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject collab speak argument leakage"
assert_contains "$output" "collab speak prose dispatch must not treat argument text as contribution content"

echo "PASS: check-cursor-content rejects collab speak argument leakage"
