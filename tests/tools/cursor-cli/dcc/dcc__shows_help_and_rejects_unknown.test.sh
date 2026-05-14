#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

help_output="$("$ROOT/tools/cursor-cli/dcc" --help)"
assert_contains "$help_output" "Usage: dcc <shortcut> [args...]"
assert_contains "$help_output" '  mod  Open Codex as "Moderator" with model gpt-5.3-codex-spark, service tier fast, and effort low'
assert_contains "$help_output" '  tw   Open Claude as "Technical Writer" with model claude-sonnet-4-6 and effort medium'
assert_contains "$help_output" '  pa   Open Claude as "Principal Architect" with model claude-opus-4-7 and effort xhigh'
assert_contains "$help_output" '  pe   Open Codex as "Platform Engineer" with model gpt-5.5, service tier fast, and effort medium'
assert_contains "$help_output" "      --yes-all"
assert_contains "$help_output" "prompt skipping is the default"
assert_contains "$help_output" "      --skip-all-prompts"

set +e
output="$("$ROOT/tools/cursor-cli/dcc" nope 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "dcc should fail on unknown shortcuts"
assert_contains "$output" "unknown shortcut: nope"
assert_contains "$output" "use --help"

set +e
output="$("$ROOT/tools/cursor-cli/dcc" '*' 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "dcc should fail on glob-like unknown shortcuts"
assert_contains "$output" "unknown shortcut: *"

echo "PASS: dcc shows help and rejects unknown shortcut"
