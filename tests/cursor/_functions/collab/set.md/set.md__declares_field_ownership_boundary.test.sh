#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/set.md"

grep -Fq '**Slash:** `/collab set`' "$file" || fail "set.md: missing slash declaration"
grep -Fq '**Signature:** `/collab set <field> <value>`' "$file" || fail "set.md: missing set signature"
grep -Fq '`title` updates the registry title and transcript H1.' "$file" || fail "set.md: missing title mutation contract"
grep -Fq '`description` updates the registry description' "$file" || fail "set.md: missing description mutation contract"
grep -Fq '`turn-order` parses space-separated role keys' "$file" || fail "set.md: missing turn-order mutation contract"
grep -Fq '`reviewer-optional-phases <phase>...` validates every phase name' "$file" || fail "set.md: missing reviewer optional phases mutation contract"
grep -Fq '`active-phase` is recovery-only: require `--force`' "$file" || fail "set.md: missing force-only active-phase repair"
grep -Fq '`status` -> `open` / `close`' "$file" || fail "set.md: missing status ownership boundary"
grep -Fq '`participants` -> `join` / `kick`' "$file" || fail "set.md: missing participant ownership boundary"
grep -Fq '`reviewer`, `reviewerOptionalPhases` -> `set`' "$file" || fail "set.md: missing reviewer optional phases ownership boundary"
grep -Fq 'Every mutable field has exactly one normal mutation path.' "$file" || fail "set.md: missing one-owner-per-field contract"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "set.md: missing registry targeting"

echo "PASS: collab set declares metadata ownership boundaries"
