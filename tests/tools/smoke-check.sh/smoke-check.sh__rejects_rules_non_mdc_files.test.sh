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
printf 'unexpected\n' >"$cfg/rules/README.txt"

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  CURSOR_CONFIG_ROOT="$cfg" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
rc=$?
set -e

[[ $rc -ne 0 ]] || fail "smoke-check should reject non-.mdc files in rules/"
assert_contains "$output" "rules/ contains unexpected file; keep only .mdc routers"
assert_contains "$output" "README.txt"

echo "PASS: smoke-check rejects non-.mdc files in rules"
