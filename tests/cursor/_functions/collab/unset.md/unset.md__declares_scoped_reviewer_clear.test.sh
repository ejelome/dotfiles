#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/unset.md"

grep -Fq '**Signature:** `/collab unset reviewer`' "$file" || fail "unset.md: missing scoped unset signature"
grep -Fq 'tools/collab/registry.py unset <target> reviewer' "$file" || fail "unset.md: missing helper-backed reviewer unset"
grep -Fq 'removes `reviewerRole`, `reviewerMode`, and `reviewerOptionalPhases`' "$file" || fail "unset.md: missing reviewer field clear contract"
grep -Fq 'already-absent reviewer as a no-op' "$file" || fail "unset.md: missing idempotent reviewer unset contract"
grep -Fq 'The only supported field in this pass is `reviewer`.' "$file" || fail "unset.md: must keep unset scoped to reviewer"

echo "PASS: unset.md declares scoped reviewer clear behavior"
