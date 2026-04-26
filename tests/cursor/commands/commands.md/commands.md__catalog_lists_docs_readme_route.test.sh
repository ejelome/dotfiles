#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/commands.md"

grep -Fq "Contract: [cursor/_core/command.md](../_core/command.md)" "$file" || fail "commands.md: missing command contract"
grep -Fq "**\`/docs readme\`**" "$file" || fail "commands.md: missing /docs readme invocation note"
grep -Fq "| \`/docs readme\` | [docs/readme.md](../_functions/docs/readme.md) |" "$file" || fail "commands.md: missing /docs readme roster entry"

echo "PASS: commands.md catalogs the /docs readme route"
