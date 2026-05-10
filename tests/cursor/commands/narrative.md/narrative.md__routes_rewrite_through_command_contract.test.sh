#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/narrative.md"

grep -Fq "**Signature:** \`/narrative <rewrite content>\`" "$file" || fail "narrative.md: missing /narrative signature"
grep -Fq "\`rewrite content\` -> [_functions/narrative/rewrite-content](../_functions/narrative/rewrite-content.md)" "$file" || fail "narrative.md: missing rewrite content route"
[[ ! -e "$ROOT/cursor/commands/content.md" ]] || fail "content.md: old /content router must not exist"

echo "PASS: narrative.md routes /narrative rewrite content through the command contract"
