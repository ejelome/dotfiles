#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/commands.md"

grep -Fq "Contract: [cursor/_core/command-standard.md](../_core/command-standard.md)" "$file" || fail "commands.md: missing command contract"
grep -Fq "**\`/doc write readme\`**" "$file" || fail "commands.md: missing /doc write readme invocation note"
grep -Fq "| \`/doc write readme\` | [doc/write-readme.md](../_functions/doc/write-readme.md) |" "$file" || fail "commands.md: missing /doc write readme roster entry"

echo "PASS: commands.md catalogs the /doc write readme route"
