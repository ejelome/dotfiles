#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
  rm -f "$ROOT/cursor/_core/reintroduced.md"
  rmdir "$ROOT/cursor/_core" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$ROOT/cursor/_core"
printf 'runtime belongs in dotcursor\n' >"$ROOT/cursor/_core/reintroduced.md"

GIT_INDEX_FILE="$tmp/index"
export GIT_INDEX_FILE
git -C "$ROOT" read-tree HEAD
git -C "$ROOT" add cursor/_core/reintroduced.md

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
rc=$?
set -e

[[ $rc -ne 0 ]] || fail "smoke-check should reject tracked Cursor runtime source"
assert_contains "$output" "cursor/ may contain only settings.json and keybindings.json"

echo "PASS: smoke-check rejects Cursor runtime source"
