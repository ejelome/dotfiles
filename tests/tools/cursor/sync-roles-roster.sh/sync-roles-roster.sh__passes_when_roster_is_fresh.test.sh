#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$({
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  "$ROOT/tools/cursor/sync-roles-roster.sh" --check
} 2>&1)"

assert_contains "$output" "sync-roles-roster: OK"

echo "PASS: sync-roles-roster check passes when generated roster is fresh"
