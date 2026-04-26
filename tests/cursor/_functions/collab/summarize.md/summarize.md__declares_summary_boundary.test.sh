#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/summarize.md"

grep -Fq 'Write the summary under `## Completion`.' "$file" || fail "summarize.md: missing Completion target"
grep -Fq 'Summaries are allowed on closed records.' "$file" || fail "summarize.md: missing closed-record allowance"
grep -Fq 'Do not mark unaccepted proposals as accepted decisions.' "$file" || fail "summarize.md: missing fact boundary"

echo "PASS: collab summarize declares summary boundary"
