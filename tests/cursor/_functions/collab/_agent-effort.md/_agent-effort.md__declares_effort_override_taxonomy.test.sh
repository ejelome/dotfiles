#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/_agent-effort.md"

grep -Fq 'Declared effort is an audit marker, not a runtime-enforced floor.' "$file" || fail "agent-effort.md: missing declaration trust model"
grep -Fq 'The protocol detects opt-in escalation only.' "$file" || fail "agent-effort.md: missing selection-bias limitation"
grep -Fq 'This matrix is illustrative.' "$file" || fail "agent-effort.md: missing illustrative matrix label"
grep -Fq 'runtime-authoritative recommendation' "$file" || fail "agent-effort.md: missing helper authority statement"
grep -Fq 'EFFORT OVERRIDE: matrix' "$file" || fail "agent-effort.md: missing explicit matrix override form"

for category in \
  'coherence-risk' \
  'implementation-density' \
  'deadlock-or-disagreement' \
  'delivery-or-migration-risk' \
  'reviewer-concern-raised'
do
  grep -Fq "\`$category\`" "$file" || fail "agent-effort.md: missing taxonomy category: $category"
done

grep -Fq 'Every change to `_agent-effort.json` or to the escalation signal taxonomy in this file must cite' "$file" || fail "agent-effort.md: missing taxonomy change-motivation rule"

echo "PASS: agent-effort.md declares effort override taxonomy"
