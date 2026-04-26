#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

cfg="$tmp/cursor"
cp -R "$ROOT/cursor" "$cfg"
ln -s "$cfg/commands" "$cfg/commands/commands"

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  CURSOR_CONFIG_ROOT="$cfg" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
rc=$?
set -e

[[ $rc -ne 0 ]] || fail "smoke-check should fail when nested mirrors exist and fix mode is off"
assert_contains "$output" "remove $cfg/commands/commands"
assert_exists "$cfg/commands/commands"

echo "PASS: smoke-check fails on nested mirrors without fix flag"
