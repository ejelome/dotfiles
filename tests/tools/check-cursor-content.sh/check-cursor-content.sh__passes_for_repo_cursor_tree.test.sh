#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$({
  CURSOR_CONFIG_ROOT="$ROOT/cursor" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"

assert_contains "$output" "check-cursor-content: OK"

echo "PASS: check-cursor-content passes for repository cursor tree"
