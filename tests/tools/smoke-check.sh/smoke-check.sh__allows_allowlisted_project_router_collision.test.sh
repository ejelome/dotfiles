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
cat >"$project/commands/commands.md" <<'EOF'
# /commands

Project-local command index.
EOF

output="$({
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  PROJECT_DOT_CURSOR="$project" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"

assert_contains "$output" "smoke-check: project .cursor guard ($project)"
assert_contains "$output" "smoke-check: OK"

echo "PASS: smoke-check allows allowlisted PROJECT_DOT_CURSOR router collisions"
