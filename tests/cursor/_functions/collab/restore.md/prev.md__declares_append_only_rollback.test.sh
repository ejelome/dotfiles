#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/restore.md"

grep -Fq '**Slash:** `/collab restore`' "$file" || fail "prev.md: missing slash declaration"
grep -Fq '**Signature:** `/collab restore`' "$file" || fail "prev.md: missing prev signature"
grep -Fq 'Resolve the previous phase from **Phase sequence** in **Notes**.' "$file" || fail "prev.md: missing previous phase resolution"
grep -Fq 'Update registry `activePhase` to the previous phase by calling `tools/collab/registry.py advance <target> prev`' "$file" || fail "prev.md: missing registry phase rollback"
grep -Fq 'Confirm the helper-updated Active phase cell in the transcript state table names the previous phase.' "$file" || fail "prev.md: missing transcript phase mirror"
grep -Fq 'Stop after the helper updates registry and transcript. Never delete or rewrite existing contributions.' "$file" || fail "prev.md: missing append-only rollback guard"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "prev.md: missing registry targeting"

# turnOrder normalization on rollback
grep -Fq 'Confirm the helper recomputed `turnOrder` for the restored phase from participants and phase context.' "$file" || fail "prev.md: missing turnOrder normalization step"
grep -Fq 'Moderator-included phases' "$file" || fail "prev.md: missing moderator-included phases note in turnOrder normalization"
grep -Fq 'moderator-excluded phases' "$file" || fail "prev.md: missing moderator-excluded phases note in turnOrder normalization"
grep -Fq 'Recovery path' "$file" || fail "prev.md: missing restore recovery path"

echo "PASS: collab prev declares append-only rollback behavior"
