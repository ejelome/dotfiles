#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions/collab" "$tmp/_generated" "$tmp/rules" "$tmp/_mdc" "$tmp/_core"

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

cat >"$tmp/_functions/collab/_agent-effort.md" <<'EOF'
# Effort defaults

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab effort defaults

## Steps

1. Read this document.

## Notes

See [`_agent-effort.json`](_agent-effort.json).
EOF

cat >"$tmp/_functions/collab/_agent-effort.json" <<'EOF'
{}
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject missing agent guidance docs"
assert_contains "$output" "cursor/_functions/collab/_agent-model.md: missing collab shared dependency"

echo "PASS: check-cursor-content rejects missing agent guidance docs"
