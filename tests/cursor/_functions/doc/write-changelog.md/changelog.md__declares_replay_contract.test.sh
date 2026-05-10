#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/doc/write-changelog.md"

grep -Fq 'If the target file does not exist, default to full repository history' "$file" || fail "changelog.md: missing full-history create behavior"
grep -Fq 'If the first relevant commit cannot be determined, ask once before writing.' "$file" || fail "changelog.md: missing root-anchor ambiguity gate"
grep -Fq 'Partial ranges must use **Coverage preamble**.' "$file" || fail "changelog.md: missing durable partial coverage requirement"
grep -Fq '> **Coverage:** Commits from YYYY-MM-DD to YYYY-MM-DD. History before YYYY-MM-DD is not included.' "$file" || fail "changelog.md: missing exact coverage preamble template"
grep -Fq 'Sort `atomic` by committer date oldest to newest within each `###`.' "$file" || fail "changelog.md: missing chronological atomic ordering"
grep -Fq 'Dedupe by normalized category plus bullet text plus source OID.' "$file" || fail "changelog.md: missing deterministic dedupe key"
grep -Fq 'Report range, mode, ordering, destination sections, and squash OID when applicable with **Post-run report**.' "$file" || fail "changelog.md: missing response metadata contract"
grep -Fq 'Never prefix bullet text with the category name or its verb form' "$file" || fail "changelog.md: missing category-verb-prefix prevention"
grep -Fq 'run `git show --name-status <oid>` for the selected commit' "$file" || fail "changelog.md: missing squash diff grounding command"
grep -Fq 'flag or reject candidates whose type/scope does not match touched paths' "$file" || fail "changelog.md: missing squash drift rejection"

echo "PASS: changelog.md declares replay contract"
