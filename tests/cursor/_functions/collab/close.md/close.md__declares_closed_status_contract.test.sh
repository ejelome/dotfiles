#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/close.md"

grep -Fq 'Update the registry status to `closed`.' "$file" || fail "close.md: missing registry status update"
grep -Fq 'Update the Status cell in the transcript state table from `open` to `closed`.' "$file" || fail "close.md: missing transcript status mirror"
grep -Fq 'If the closing collab id matches `activeCollabId`, clear `activeCollabId`.' "$file" || fail "close.md: missing active pointer cleanup"
grep -Fq 'Subsequent routes must refuse target inference until the moderator runs `/collab use <record>`' "$file" || fail "close.md: missing registry cleanup fallback note"
grep -Fq 'Unless `--no-summary` is passed, generate a summary under `## Completion`' "$file" || fail "close.md: missing summary default step"
grep -Fq '`/collab close` generates a summary by default.' "$file" || fail "close.md: missing summary default note"
grep -Fq '`/collab summarize` remains available on closed records' "$file" || fail "close.md: missing summarize-after-close rule"
if grep -Fq '.collabs/.active' "$file"; then
  fail "close.md: must not keep .active cleanup after the registry migration"
fi

echo "PASS: collab close declares closed status behavior"
