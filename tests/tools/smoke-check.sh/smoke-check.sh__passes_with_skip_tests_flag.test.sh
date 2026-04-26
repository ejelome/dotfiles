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

output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"

assert_contains "$output" "smoke-check: tests skipped (SKIP_TESTS_RUN=1)"
assert_contains "$output" "smoke-check: OK"

echo "PASS: smoke-check passes with SKIP_TESTS_RUN=1"
