#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

set +e
output="$($ROOT/tools/cursor-cli/clear-chat.sh --nope 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "clear-chat.sh should fail on unknown options"
assert_contains "$output" "unknown option: --nope"
assert_contains "$output" "use --help"

echo "PASS: clear-chat rejects unknown option"
