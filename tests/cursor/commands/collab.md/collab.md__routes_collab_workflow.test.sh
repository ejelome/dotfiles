#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/collab.md"
catalog="$ROOT/cursor/commands/commands.md"

grep -Fq '**Signature:** `/collab <init | join | speak | re-speak | next | prev | set | unset | list | use | open | close | kick | archive | delete | summarize | execute | re-execute | policy>`' "$file" || fail "collab.md: missing routed signature"
for route in init join speak re-speak next prev set unset list use open close kick archive delete summarize execute re-execute policy; do
  grep -Fq "\`${route}\` -> [_functions/collab/${route}](../_functions/collab/${route}.md)" "$file" || fail "collab.md: missing ${route} route"
  grep -Fq "[collab/${route}.md](../_functions/collab/${route}.md)" "$catalog" || fail "commands.md: missing collab/${route}.md catalog entry"
done
grep -Fq 'No machine-readable registry field exists for gate assignment in this version.' "$ROOT/cursor/_functions/collab/policy.md" || fail "policy.md: missing documentation-only boundary"
grep -Fq '/collab use slash-command-ux-and-dx-polish' "$file" || fail "collab.md: missing registry-backed use example"
grep -Fq '/collab set turn-order tw pe' "$file" || fail "collab.md: missing metadata set example"
grep -Fq '/collab unset reviewer' "$file" || fail "collab.md: missing metadata unset example"
grep -Fq 'activeCollabId' "$file" || fail "collab.md: missing registry pointer model"
grep -Fq '/collab execute` and `/collab re-execute` are the exceptions: they implement action-plan items assigned to the executing agent'\''s role' "$file" || fail "collab.md: missing execute implementation boundary"
grep -Fq 'assigned action-plan items for a moderated collaboration record' "$catalog" || fail "commands.md: missing direct execution invocation note"
if grep -Fq 'mark execution authorization' "$file" "$catalog"; then
  fail "collab command docs must not describe execute as authorization-only"
fi
if grep -Fq '.collabs/.active' "$file" "$catalog"; then
  fail "collab command docs must not keep .active as the source of truth"
fi

echo "PASS: collab.md routes the moderated collaboration workflow"
