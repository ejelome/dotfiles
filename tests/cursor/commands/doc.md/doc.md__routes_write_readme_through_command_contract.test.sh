#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/doc.md"

grep -Fq "**Signature:** \`/doc <assess | compact | compare | write changelog | write manual | write readme>\`" "$file" || fail "doc.md: missing /doc signature"
grep -Fq "\`write readme\` -> [_functions/doc/write-readme](../_functions/doc/write-readme.md)" "$file" || fail "doc.md: missing write readme route"

echo "PASS: doc.md routes /doc write readme through the command contract"
