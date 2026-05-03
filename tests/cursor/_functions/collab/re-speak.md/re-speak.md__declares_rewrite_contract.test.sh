#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/re-speak.md"

grep -Fq '**Slash:** `/collab re-speak`' "$file" || fail "re-speak.md: missing slash declaration"
grep -Fq '**Signature:** `/collab re-speak`' "$file" || fail "re-speak.md: missing signature declaration"

# Gate: closed/archived record
grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**' "$file" || fail "re-speak.md: missing closed-record gate"

# Gate: Completion phase is off-limits; redirect to re-execute
grep -Fq 'If the active phase is `Completion`, **ABORT**: `/collab re-speak` is not permitted in the `Completion` phase' "$file" || fail "re-speak.md: missing Completion phase abort gate"
grep -Fq 'use `/collab re-execute` to rewrite execution records' "$file" || fail "re-speak.md: missing re-execute redirect in Completion gate"

# Gate: no prior contribution
grep -Fq '**ABORT**: no prior contribution to rewrite; use `/collab speak` to create the first contribution.' "$file" || fail "re-speak.md: missing no-prior-contribution abort gate"

# Helper-backed location of last contribution
grep -Fq 'tools/collab/registry.py speak-state <target> <role>' "$file" || fail "re-speak.md: missing speak-state helper call for anchor resolution"

# Active content region extraction — must exclude existing revision history block
grep -Fq 'up to (but not including) any existing `<details><summary>Revision history</summary>` block' "$file" || fail "re-speak.md: missing revision-history exclusion in active-region extraction"

# Revision history shape: wrap prior content, prepend inside existing wrapper
grep -Fq 'Revision history shape' "$file" || fail "re-speak.md: missing Revision history shape note"
grep -Fq 'Previous revision, <original-timestamp>' "$file" || fail "re-speak.md: missing original-timestamp in revision history shape"
grep -Fq 'prepend the new prior-revision entry inside it rather than nesting a second wrapper' "$file" || fail "re-speak.md: missing multiple-rewrite accumulation contract"

# Rewrite semantics — in-place, no count change, one-speak limits not re-checked
grep -Fq 'The contribution count for the role in the phase does not change.' "$file" || fail "re-speak.md: missing contribution-count invariant"
grep -Fq 'One-speak phase limits are not re-checked' "$file" || fail "re-speak.md: missing one-speak-limit bypass note"

# No new block, no new TOC entry
grep -Fq 'Do not create a new `<details>` block.' "$file" || fail "re-speak.md: missing no-new-details-block guard"
grep -Fq 'Do not add a new Table of Contents entry.' "$file" || fail "re-speak.md: missing no-new-toc-entry guard"

# Moderator boundary
grep -Fq 'Agents must not generate content for the moderator role.' "$file" || fail "re-speak.md: missing moderator-role boundary"

# Execution boundary
grep -Fq 'Never perform any file edit, shell command, or codebase change as a side effect of this command.' "$file" || fail "re-speak.md: missing execution boundary"

# Registry targeting
grep -Fq 'when absent, resolved per **Registry targeting** in **Notes**' "$file" || fail "re-speak.md: missing registry target parameter"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "re-speak.md: missing registry targeting source"

echo "PASS: re-speak.md declares rewrite contract"
