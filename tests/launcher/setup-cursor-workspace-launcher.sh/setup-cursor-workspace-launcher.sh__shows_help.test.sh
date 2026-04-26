#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$($ROOT/launcher/setup-cursor-workspace-launcher.sh --help 2>&1)"
assert_contains "$output" "Usage: setup-cursor-workspace-launcher.sh"
assert_contains "$output" "Workspace list: copy workspace-launcher.local.sh.example"

echo "PASS: setup-cursor-workspace-launcher shows help"
