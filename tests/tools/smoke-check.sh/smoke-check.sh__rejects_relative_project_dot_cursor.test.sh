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

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  PROJECT_DOT_CURSOR="relative/.cursor" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "smoke-check should reject relative PROJECT_DOT_CURSOR"
assert_contains "$output" "PROJECT_DOT_CURSOR must be an absolute path: relative/.cursor"

echo "PASS: smoke-check rejects relative PROJECT_DOT_CURSOR"
