#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/revamp.md"

grep -Fq "**Signature:** \`/revamp <narrative>\`" "$file" || fail "revamp.md: missing /revamp signature"
grep -Fq "\`narrative\` -> [_functions/revamp/narrative](../_functions/revamp/narrative.md)" "$file" || fail "revamp.md: missing narrative route"
[[ ! -e "$ROOT/cursor/commands/content.md" ]] || fail "content.md: old /content router must not exist"

echo "PASS: revamp.md routes /revamp narrative through the command contract"
