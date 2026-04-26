#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp_root="$ROOT/.tmp-smoke-check-dsstore-test"
mkdir -p "$tmp_root"
printf 'metadata\n' >"$tmp_root/.DS_Store"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$ROOT/.tmp-smoke-check-dsstore-test-pycache" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
rc=$?
set -e

rm -rf "$ROOT/.tmp-smoke-check-dsstore-test-pycache"

[[ $rc -ne 0 ]] || fail "smoke-check should fail when .DS_Store files exist"
assert_contains "$output" "smoke-check: remove macOS metadata file"
assert_contains "$output" ".tmp-smoke-check-dsstore-test/.DS_Store"

echo "PASS: smoke-check rejects .DS_Store files"
