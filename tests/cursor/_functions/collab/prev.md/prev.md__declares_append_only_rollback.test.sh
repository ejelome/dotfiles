#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/prev.md"

grep -Fq '**Slash:** `/collab prev`' "$file" || fail "prev.md: missing slash declaration"
grep -Fq '**Signature:** `/collab prev`' "$file" || fail "prev.md: missing prev signature"
grep -Fq 'Resolve the previous phase from **Phase sequence** in **Notes**.' "$file" || fail "prev.md: missing previous phase resolution"
grep -Fq 'Update registry `activePhase` to the previous phase.' "$file" || fail "prev.md: missing registry phase rollback"
grep -Fq 'Update the Active phase cell in the transcript state table to the previous phase.' "$file" || fail "prev.md: missing transcript phase mirror"
grep -Fq 'Stop after updating registry and transcript. Never delete or rewrite existing contributions.' "$file" || fail "prev.md: missing append-only rollback guard"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "prev.md: missing registry targeting"

echo "PASS: collab prev declares append-only rollback behavior"
