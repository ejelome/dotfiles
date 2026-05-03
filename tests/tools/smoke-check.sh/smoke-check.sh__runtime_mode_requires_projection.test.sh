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

home="$tmp/home"
mkdir -p "$home"

set +e
output="$({
  HOME="$home" \
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  SMOKE_CHECK_RUNTIME=1 \
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
status=$?
set -e

[[ "$status" -ne 0 ]] || fail "expected smoke-check runtime mode to fail without copied runtime projection"
assert_contains "$output" "smoke-check: runtime projection (SMOKE_CHECK_RUNTIME=1)"
assert_contains "$output" "runtime projection missing destination"

echo "PASS: smoke-check runtime mode requires copied runtime projection"
