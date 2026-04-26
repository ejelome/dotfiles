#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/docs.md"

grep -Fq "**Signature:** \`/docs <assess | changelog | compact | compare | manual | readme>\`" "$file" || fail "docs.md: missing /docs signature"
grep -Fq "\`readme\` -> [_functions/docs/readme](../_functions/docs/readme.md)" "$file" || fail "docs.md: missing readme route"

echo "PASS: docs.md routes /docs readme through the command contract"
