#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/speak.md"

grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**' "$file" || fail "speak.md: missing closed-record gate"
grep -Fq 'If no matching participant exists, **ABORT** and tell the moderator to run `/collab join --role <role>` first.' "$file" || fail "speak.md: missing join-before-speak gate"
grep -Fq 'Agents must not generate content for `mod`' "$file" || fail "speak.md: missing moderator human-owned boundary"
grep -Fq 'write only the supplied `<message>` text verbatim and apply any rule-mandated structure-only formatting pass' "$file" || fail "speak.md: missing moderator formatting boundary"
grep -Fq '`--turn-order <acronym>...`' "$file" || fail "speak.md: missing --turn-order flag declaration"
grep -Fq 'treat all tokens after `--turn-order` as the new space-separated order' "$file" || fail "speak.md: missing unambiguous turn-order token parsing"
grep -Fq 'Validate `--turn-order` before any write.' "$file" || fail "speak.md: missing turn-order atomicity guard"
grep -Fq 'enforcing participant-list order' "$file" || fail "speak.md: missing turn-order fallback behavior"
grep -Fq 'If the speaking participant does not match the expected acronym, **ABORT** naming the expected role.' "$file" || fail "speak.md: missing turn-order enforcement abort"
grep -Fq 'Resolve the active phase from registry `active_phase`.' "$file" || fail "speak.md: missing registry phase authority"
grep -Fq 'every acronym is registered in the registry `participants` list' "$file" || fail "speak.md: missing registry participant authority"
grep -Fq 'Write the new order to registry `turn_order`' "$file" || fail "speak.md: missing registry turn-order authority"
grep -Fq 'Never perform work listed in `## Action Plan`' "$file" || fail "speak.md: missing execution boundary"
grep -Fq '[auto-collab-message-format](../../_mdc/auto/auto-collab-message-format.mdc)' "$file" || fail "speak.md: missing collab formatting rule link"
if grep -Fq '.collabs/.active' "$file"; then
  fail "speak.md: must not keep .active fallback after the registry migration"
fi

echo "PASS: collab speak declares write gates"
