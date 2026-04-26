#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

routes=(join speak next prev set open close kick delete summarize execute)
for route in "${routes[@]}"; do
  file="$ROOT/cursor/_functions/collab/${route}.md"
  grep -Fq 'when absent, resolved per **Registry targeting** in **Notes**' "$file" || fail "${route}.md: missing registry target parameter"
  grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "${route}.md: missing registry targeting source"
  grep -Fq 'treat it as a collab slug or id' "$file" || fail "${route}.md: missing slug-or-id targeting"
  grep -Fq 'match it against `transcript_path` as a legacy explicit target' "$file" || fail "${route}.md: missing transcript_path fallback"
  grep -Fq 'Otherwise use `active_collab_id`.' "$file" || fail "${route}.md: missing active pointer targeting"
done

grep -Fq '**Signature:** `/collab join --role <role>`' "$ROOT/cursor/_functions/collab/join.md" || fail "join.md: missing join signature"
grep -Fq '**Signature:** `/collab speak [<message>] [--turn-order <acronym>...]`' "$ROOT/cursor/_functions/collab/speak.md" || fail "speak.md: missing speak signature"
grep -Fq '**Signature:** `/collab next`' "$ROOT/cursor/_functions/collab/next.md" || fail "next.md: missing next signature"
grep -Fq '**Signature:** `/collab prev`' "$ROOT/cursor/_functions/collab/prev.md" || fail "prev.md: missing prev signature"
grep -Fq '**Signature:** `/collab set <field> <value>`' "$ROOT/cursor/_functions/collab/set.md" || fail "set.md: missing set signature"
grep -Fq '**Signature:** `/collab open`' "$ROOT/cursor/_functions/collab/open.md" || fail "open.md: missing open signature"
grep -Fq '**Signature:** `/collab kick <role>`' "$ROOT/cursor/_functions/collab/kick.md" || fail "kick.md: missing kick signature"
grep -Fq '**Signature:** `/collab delete`' "$ROOT/cursor/_functions/collab/delete.md" || fail "delete.md: missing delete signature"
grep -Fq '**Signature:** `/collab summarize`' "$ROOT/cursor/_functions/collab/summarize.md" || fail "summarize.md: missing summarize signature"
grep -Fq '**Signature:** `/collab close [--no-summary]`' "$ROOT/cursor/_functions/collab/close.md" || fail "close.md: missing close signature"
grep -Fq '**Signature:** `/collab execute`' "$ROOT/cursor/_functions/collab/execute.md" || fail "execute.md: missing execute signature"

echo "PASS: collab routes declare explicit record targeting"
