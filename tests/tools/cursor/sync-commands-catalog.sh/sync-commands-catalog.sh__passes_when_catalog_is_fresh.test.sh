#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$({
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  "$ROOT/tools/cursor/sync-commands-catalog.sh" --check
} 2>&1)"

assert_contains "$output" "sync-commands-catalog: OK"

echo "PASS: sync-commands-catalog check passes when generated roster is fresh"
