#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions" "$tmp/rules" "$tmp/_mdc"

cat >"$tmp/commands/one.md" <<'EOF'
# /one

Route first demo workflows.

## Trigger

**Slash:** `/duplicate`
**Signature:** `/duplicate`
**Prose dispatch:** `(duplicate)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** first demo

## Steps

1. Resolve the route.

## Notes

- **Parameters:** none.
EOF

cat >"$tmp/commands/two.md" <<'EOF'
# /two

Route second demo workflows.

## Trigger

**Slash:** `/duplicate`
**Signature:** `/duplicate`
**Prose dispatch:** `(duplicate two)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** second demo

## Steps

1. Resolve the route.

## Notes

- **Parameters:** none.
EOF

set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject duplicate invocable trigger entries"
assert_contains "$output" "trigger invocable duplicate"
assert_contains "$output" "'/duplicate' appears in"

rm -rf "$tmp"
tmp="$(mktemp -d)"
mkdir -p "$tmp/commands" "$tmp/_functions/test" "$tmp/rules" "$tmp/_mdc"

cat >"$tmp/commands/test.md" <<'EOF'
# /test

Route test workflows.

## Trigger

**Slash:** `/test`
**Signature:** `/test <commands | rules | _functions | _mdc | _core | _roles | _settings | repo | all>`
**Prose dispatch:** `(test <commands | rules | _functions | _mdc | _core | _roles | _settings | repo | all>)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** run tests

## Steps

1. Resolve the target.

## Notes

- **Parameters:** target selector.
EOF

cat >"$tmp/_functions/test/run.md" <<'EOF'
# /test

Run test workflows.

## Trigger

**Slash:** `/test`
**Signature:** `/test <commands | rules | _functions | _mdc | _core | _roles | _settings | repo | all>`
**Prose dispatch:** `(test <commands | rules | _functions | _mdc | _core | _roles | _settings | repo | all>)` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** run tests

## Steps

1. Resolve the target.

## Notes

- **Parameters:** target selector.
EOF

output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
assert_contains "$output" "check-cursor-content: OK"

echo "PASS: check-cursor-content rejects duplicate trigger invocation"
