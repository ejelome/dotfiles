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

output="$({
  HOME="$home" \
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  SKIP_CURSOR_INSTALL=1 \
  SKIP_CURSOR_LAUNCHER=1 \
  "$ROOT/link.sh" >/dev/null

  HOME="$home" \
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  SMOKE_CHECK_RUNTIME=1 \
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"

assert_contains "$output" "smoke-check: runtime projection (SMOKE_CHECK_RUNTIME=1)"
assert_contains "$output" "smoke-check: OK"

echo "PASS: smoke-check runtime mode passes with linked runtime projection"
