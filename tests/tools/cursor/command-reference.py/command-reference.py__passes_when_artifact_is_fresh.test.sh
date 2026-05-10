#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$("$ROOT/tools/cursor/command-reference.py" --check 2>&1)"

assert_contains "$output" "command-reference: OK"

echo "PASS: command-reference check passes when artifact is fresh"
