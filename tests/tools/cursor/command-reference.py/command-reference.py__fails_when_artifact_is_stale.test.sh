#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -R "$ROOT"/. "$tmp/repo"
cd "$tmp/repo"

perl -0pi -e 's/<!-- BEGIN GENERATED:COMMAND_REFERENCE -->\n/<!-- BEGIN GENERATED:COMMAND_REFERENCE -->\nSTALE\n/' cursor/_generated/command-reference.md

set +e
output="$(CURSOR_CONFIG_ROOT="$PWD/cursor" tools/cursor/command-reference.py --check 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "command-reference --check should fail when generated artifact is stale"
assert_contains "$output" 'run `tools/cursor/command-reference.py --render` to update'

echo "PASS: command-reference check fails when generated artifact is stale"
