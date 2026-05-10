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

project="$tmp/project/.cursor"
mkdir -p "$project/rules"
cat >"$project/rules/local.mdc" <<'EOF'
# Project rule

Do not depend on [_core](../_core/style-guide.md) from an app-local rule.
EOF

set +e
output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  PROJECT_DOT_CURSOR="$project" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "smoke-check should reject PROJECT_DOT_CURSOR core references"
assert_contains "$output" "PROJECT_DOT_CURSOR must not reference authoring core: rules/local.mdc"

echo "PASS: smoke-check rejects PROJECT_DOT_CURSOR core references"
