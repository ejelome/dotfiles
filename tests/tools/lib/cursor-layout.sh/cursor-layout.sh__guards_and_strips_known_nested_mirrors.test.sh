#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
# shellcheck source=tools/lib/cursor-layout.sh
source "$ROOT/tools/lib/cursor-layout.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

cfg="$tmp/cursor"
mkdir -p "$cfg/commands" "$cfg/rules" "$cfg/_functions" "$cfg/_core" "$cfg/_mdc" "$cfg/_tests"
ln -s "$cfg/commands" "$cfg/commands/commands"

set +e
output="$(cursor_assert_no_nested_mirrors "$cfg" "cursor-layout-test" 2>&1)"
rc=$?
set -e

[[ $rc -ne 0 ]] || fail "cursor_assert_no_nested_mirrors should fail on nested self-symlink mirror"
assert_contains "$output" "remove $cfg/commands/commands"

cursor_strip_nested_mirrors "$cfg"
assert_not_exists "$cfg/commands/commands"

mkdir -p "$cfg/commands/commands"
cursor_strip_nested_mirrors "$cfg"
assert_exists "$cfg/commands/commands"

set +e
output="$(cursor_assert_no_nested_mirrors "$cfg" "cursor-layout-test" 2>&1)"
rc=$?
set -e
[[ $rc -ne 0 ]] || fail "cursor_assert_no_nested_mirrors should fail on unknown nested layout"
assert_contains "$output" "remove $cfg/commands/commands"

rm -rf "$cfg/commands/commands"
mkdir -p "$cfg/core"

set +e
output="$(cursor_assert_no_nested_mirrors "$cfg" "cursor-layout-test" 2>&1)"
rc=$?
set -e

[[ $rc -ne 0 ]] || fail "cursor_assert_no_nested_mirrors should fail on legacy core/ path"
assert_contains "$output" "private Cursor folders under CURSOR_CONFIG_ROOT must be underscore-prefixed"

echo "PASS: cursor-layout guards nested mirrors and legacy private folders"
