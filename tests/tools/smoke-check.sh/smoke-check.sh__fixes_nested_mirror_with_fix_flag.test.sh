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

output="$({
  SKIP_TESTS_RUN=1 \
  SMOKE_CHECK_FIX_NESTED_MIRRORS=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  CURSOR_CONFIG_ROOT="$cfg" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"

assert_contains "$output" "fixing nested self-symlink mirrors"
assert_contains "$output" "smoke-check: OK"
assert_not_exists "$cfg/commands/commands"

echo "PASS: smoke-check fixes nested mirrors when fix flag is set"
