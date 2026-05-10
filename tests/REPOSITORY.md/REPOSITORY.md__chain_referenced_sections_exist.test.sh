#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

repo="$ROOT/REPOSITORY.md"

grep -Eq "^# Repository Contract" "$repo"         || fail "REPOSITORY.md: missing title"
grep -Fq "## 4) Mutation Protocol and Ownership" "$repo" || fail "REPOSITORY.md: missing §4"
grep -Fq "## 5) Validation Modes"                "$repo" || fail "REPOSITORY.md: missing §5"
grep -Fq "SMOKE_CHECK_RUNTIME=1"                 "$repo" || fail "REPOSITORY.md: missing SMOKE_CHECK_RUNTIME=1"
grep -Fq "## 3) Output Chain Contract"           "$repo" || fail "REPOSITORY.md: missing output chain contract"
grep -Fq 'Runtime projection under `~`, `~/.cursor/*`, and Cursor User JSON' "$repo" || fail "REPOSITORY.md: missing runtime projection output chain"
grep -Fq 'Command catalog generated block in `cursor/commands/commands.md`' "$repo" || fail "REPOSITORY.md: missing command catalog output chain"
grep -Fq 'Command reference generated block in `cursor/_generated/command-reference.md`' "$repo" || fail "REPOSITORY.md: missing command reference output chain"
grep -Fq 'Framework boundaries generated block in `cursor/_core/framework-boundaries.md`' "$repo" || fail "REPOSITORY.md: missing framework boundaries output chain"
grep -Fq 'Repository README and targeted artifact checks' "$repo" || fail "REPOSITORY.md: missing README output chain"
grep -Fq 'Manual link fallback guide' "$repo" || fail "REPOSITORY.md: missing manual output chain"
grep -Fq 'Agent bootstrap adapters' "$repo" || fail "REPOSITORY.md: missing agent adapter output chain"

echo "PASS: REPOSITORY.md chain-referenced sections exist"
