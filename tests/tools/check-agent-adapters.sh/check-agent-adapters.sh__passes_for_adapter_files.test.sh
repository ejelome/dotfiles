#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$("$ROOT/tools/check-agent-adapters.sh" 2>&1)"
assert_contains "$output" "check-agent-adapters: OK"

echo "PASS: check-agent-adapters passes for adapter files"
