#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions" "$tmp/rules" "$tmp/_mdc"

bad_word='compati''bility'
cat >"$tmp/commands/demo.md" <<EOF
# /demo

Route demo workflows.

## Trigger

**Slash:** \`/demo\`
**Signature:** \`/demo <run>\`
**Prose dispatch:** \`(demo run)\` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo run, run demo

## Steps

1. Remove unexplained ${bad_word} wording.

## Notes

- **Parameters:** \`<run>\` — required route selector.
EOF

set +e
output="$({
  CHECK_CURSOR_CONTENT_NO_RG=1 \
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content fallback should reject transition wording without rg"
assert_contains "$output" "remove or justify flagged transition wording"

echo "PASS: check-cursor-content rejects transition wording without rg"
