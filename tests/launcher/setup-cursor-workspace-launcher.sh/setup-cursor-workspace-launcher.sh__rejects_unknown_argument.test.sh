#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

set +e
output="$($ROOT/launcher/setup-cursor-workspace-launcher.sh --bad-arg 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "setup-cursor-workspace-launcher should fail on unknown args"
assert_contains "$output" "Unknown argument: --bad-arg"

echo "PASS: setup-cursor-workspace-launcher rejects unknown arguments"
