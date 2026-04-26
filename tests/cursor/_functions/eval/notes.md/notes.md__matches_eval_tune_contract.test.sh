#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

notes="$ROOT/cursor/_functions/eval/notes.md"
tune="$ROOT/cursor/_functions/eval/tune.md"
shared="$ROOT/cursor/_mdc/shared/shared-cmd-eval.mdc"
repo="$ROOT/REPOSITORY.md"

[[ -f "$notes" ]] || fail "notes.md: missing eval notes file"
grep -Fq "# /eval notes" "$notes" || fail "notes.md: missing title"
grep -Fq "Serve as the append-only log for QA learning notes approved during \`/eval tune\` runs." "$notes" || fail "notes.md: missing purpose"
grep -Fq "## Trigger" "$notes" || fail "notes.md: missing Trigger section"
grep -Fq "## Steps" "$notes" || fail "notes.md: missing Steps section"
grep -Fq "## Notes" "$notes" || fail "notes.md: missing Notes section"
grep -Fq "**Append behavior:**" "$notes" || fail "notes.md: missing append behavior note"
grep -Fq "**Status:** No retained QA audit entries yet." "$notes" || fail "notes.md: missing status note"
grep -Fq "Never replace or rewrite prior audit sections." "$notes" || fail "notes.md: missing append-only rule"
grep -Fq "Load this route only through \`/eval tune\`; do not invoke \`/eval notes\` directly." "$notes" || fail "notes.md: missing route-only step"

grep -Fq "[notes.md](notes.md)" "$tune" || fail "eval tune: missing notes link"
grep -Fq "If the file is missing when notes are approved, **ABORT**" "$tune" || fail "eval tune: missing missing-file guard"
grep -Fq "\`cursor/_functions/eval/notes.md\` is the durable append-only log" "$shared" || fail "shared-cmd-eval: missing notes durable log rule"
grep -Fq "QA notes append log" "$repo" || fail "REPOSITORY.md: missing QA notes output chain"

echo "PASS: notes.md matches /eval tune output contract"
