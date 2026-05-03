#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

routes=(join speak re-speak next prev set open close kick archive delete summarize execute re-execute)
for route in "${routes[@]}"; do
  file="$ROOT/cursor/_functions/collab/${route}.md"
  grep -Fq 'when absent, resolved per **Registry targeting** in **Notes**' "$file" || fail "${route}.md: missing registry target parameter"
  grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "${route}.md: missing registry targeting source"
  grep -Fq 'treat it as a collab slug' "$file" || fail "${route}.md: missing slug targeting"
  grep -Fq 'Otherwise use `activeCollabId`.' "$file" || fail "${route}.md: missing active pointer targeting"
done

grep -Fq '**Signature:** `/collab join --role <role>`' "$ROOT/cursor/_functions/collab/join.md" || fail "join.md: missing join signature"
grep -Fq '**Signature:** `/collab speak [<message>] [--turn-order <key>...]`' "$ROOT/cursor/_functions/collab/speak.md" || fail "speak.md: missing speak signature"
grep -Fq '**Signature:** `/collab next`' "$ROOT/cursor/_functions/collab/next.md" || fail "next.md: missing next signature"
grep -Fq '**Signature:** `/collab prev`' "$ROOT/cursor/_functions/collab/prev.md" || fail "prev.md: missing prev signature"
grep -Fq '**Signature:** `/collab set <field> <value>`' "$ROOT/cursor/_functions/collab/set.md" || fail "set.md: missing set signature"
grep -Fq '**Signature:** `/collab open`' "$ROOT/cursor/_functions/collab/open.md" || fail "open.md: missing open signature"
grep -Fq '**Signature:** `/collab kick <role>`' "$ROOT/cursor/_functions/collab/kick.md" || fail "kick.md: missing kick signature"
grep -Fq '**Signature:** `/collab archive [<target>]`' "$ROOT/cursor/_functions/collab/archive.md" || fail "archive.md: missing archive signature"
grep -Fq '**Signature:** `/collab delete [<target>]`' "$ROOT/cursor/_functions/collab/delete.md" || fail "delete.md: missing delete signature"
grep -Fq '**Signature:** `/collab summarize`' "$ROOT/cursor/_functions/collab/summarize.md" || fail "summarize.md: missing summarize signature"
grep -Fq '**Signature:** `/collab close [--no-summary]`' "$ROOT/cursor/_functions/collab/close.md" || fail "close.md: missing close signature"
grep -Fq '**Signature:** `/collab execute`' "$ROOT/cursor/_functions/collab/execute.md" || fail "execute.md: missing execute signature"
grep -Fq '**Signature:** `/collab re-speak`' "$ROOT/cursor/_functions/collab/re-speak.md" || fail "re-speak.md: missing re-speak signature"
grep -Fq '**Signature:** `/collab re-execute`' "$ROOT/cursor/_functions/collab/re-execute.md" || fail "re-execute.md: missing re-execute signature"

echo "PASS: collab routes declare explicit record targeting"
