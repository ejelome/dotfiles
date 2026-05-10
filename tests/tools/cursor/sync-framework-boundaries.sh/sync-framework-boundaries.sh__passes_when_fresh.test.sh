#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$({
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  "$ROOT/tools/cursor/sync-framework-boundaries.sh" --check
} 2>&1)"

assert_contains "$output" "sync-framework-boundaries: OK"
assert_contains "$(sed -n '/BEGIN GENERATED:FRAMEWORK_BOUNDARIES/,/END GENERATED:FRAMEWORK_BOUNDARIES/p' "$ROOT/cursor/_core/framework-boundaries.md")" "| Memory | absent - collab-scoped only |"
if sed -n '/status_memory()/,/^}/p' "$ROOT/tools/cursor/sync-framework-boundaries.sh" | grep -Fq ".collabs/registry.json"; then
  fail "sync-framework-boundaries must not depend on local collab runtime state"
fi

echo "PASS: sync-framework-boundaries check passes when generated table is fresh"
