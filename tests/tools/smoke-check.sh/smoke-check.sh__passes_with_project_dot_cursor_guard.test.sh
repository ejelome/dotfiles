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
mkdir -p "$project/rules" "$project/commands"
cat >"$project/rules/local.mdc" <<'EOF'
---
description: "Project rule"
alwaysApply: true
---
# Project rule

Use installed commands from `~/.cursor/commands`.
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

echo "PASS: smoke-check accepts safe PROJECT_DOT_CURSOR"
