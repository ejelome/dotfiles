#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions" "$tmp/_generated" "$tmp/rules" "$tmp/_mdc"

cat >"$tmp/commands/demo.md" <<'EOF'
# /demo

Route demo workflows.

## Trigger

**Slash:** `/demo`
**Signature:** `/demo`
**Prose dispatch:** `(demo)` - for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo workflow

## Steps

1. Resolve the route.

## Notes

- **Parameters:** none.
EOF

cat >"$tmp/_generated/content-invariants.tsv" <<'EOF'
cursor/commands/demo.md	demo-required-phrase	required phrase that is absent
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject a missing named content invariant"
assert_contains "$output" "missing content invariant demo-required-phrase"

echo "PASS: check-cursor-content rejects missing named content invariant"
