#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/git/commit.md"

grep -Fq 'Inspect `git status --porcelain`, unstaged diff, and staged diff before grouping.' "$file" || fail "commit.md: missing atomic diff preflight"
grep -Fq 'Build an outcome-based grouping plan before any staging' "$file" || fail "commit.md: missing outcome-based pre-staging grouping plan"
grep -Fq 'list each proposed commit in buildable order, the paths or hunks included, and the diff evidence' "$file" || fail "commit.md: missing grouping plan evidence contract"
grep -Fq 'Show that grouping plan to the user before the first `git add`.' "$file" || fail "commit.md: missing pre-git-add display gate"
grep -Fq 'Do not run `git add .`, `git add -A`, or broad path staging in this route.' "$file" || fail "commit.md: missing broad staging prohibition"
grep -Fq 'Stage only the paths or hunks named in the displayed grouping plan' "$file" || fail "commit.md: missing plan-bounded staging guard"
grep -Fq 'use `git add -p` when one file contains hunks for multiple outcomes' "$file" || fail "commit.md: missing mixed-hunk handling"
grep -Fq 'Collect the new atomic subjects verbatim, in chronological order, before the soft reset.' "$file" || fail "commit.md: missing squash subject preservation before reset"
grep -Fq 'body `- ` lines from the collected atomic subjects exactly as collected' "$file" || fail "commit.md: missing exact squash bullet preservation"

echo "PASS: commit.md declares atomic grouping and squash preservation contract"
