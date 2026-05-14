#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

repo="$ROOT/REPOSITORY.md"

grep -Eq "^# Repository Contract" "$repo"         || fail "REPOSITORY.md: missing title"
grep -Fq "## 4) Mutation Protocol and Ownership" "$repo" || fail "REPOSITORY.md: missing §4"
grep -Fq "## 5) Validation Modes"                "$repo" || fail "REPOSITORY.md: missing §5"
grep -Fq "## 3) Output Chain Contract"           "$repo" || fail "REPOSITORY.md: missing output chain contract"
grep -Fq 'Shell, Git, and config symlinks under `~`' "$repo" || fail "REPOSITORY.md: missing dotfiles symlink output chain"
! grep -Fq "SMOKE_CHECK_RUNTIME=1" "$repo" || fail "REPOSITORY.md: must not retain runtime projection validation"
! grep -Fq 'Cursor User JSON' "$repo" || fail "REPOSITORY.md: must not retain Cursor runtime output chain"

echo "PASS: REPOSITORY.md chain-referenced sections exist"
