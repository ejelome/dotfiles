#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/rewrite-summary.md"

grep -Fq '**Slash:** `/collab rewrite summary`' "$file" || fail "rewrite-summary.md: missing slash declaration"
grep -Fq '**Signature:** `/collab rewrite summary`' "$file" || fail "rewrite-summary.md: missing signature declaration"

# Gate: nothing yet summarized
grep -Fq '**ABORT**: nothing yet summarized' "$file" || fail "rewrite-summary.md: missing nothing-yet-summarized abort gate"

# Rewrite semantics: in-place, no new section created
grep -Fq 'rewrites the most recent summary in-place rather than appending a new one' "$file" || fail "rewrite-summary.md: missing in-place rewrite semantics note"

# Closed-record allowance
grep -Fq 'allowed on both open and closed records' "$file" || fail "rewrite-summary.md: missing open-and-closed-records allowance"

# Fact boundary
grep -Fq 'Do not mark unaccepted proposals as accepted decisions.' "$file" || fail "rewrite-summary.md: missing fact boundary"

# Preserves contributions outside summary subsection
grep -Fq 'Preserve all previous participant contributions' "$file" || fail "rewrite-summary.md: missing preservation of prior contributions"

# Registry targeting
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "rewrite-summary.md: missing registry targeting source"

echo "PASS: rewrite-summary.md declares rewrite contract"
