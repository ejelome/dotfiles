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
mkdir -p "$project/commands"
cat >"$project/commands/docs.md" <<'EOF'
# /docs

Project-local override attempt.
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

[[ $status -ne 0 ]] || fail "smoke-check should reject PROJECT_DOT_CURSOR router collisions"
assert_contains "$output" "PROJECT_DOT_CURSOR must not override global command router: commands/docs.md"

echo "PASS: smoke-check rejects PROJECT_DOT_CURSOR router collisions"
