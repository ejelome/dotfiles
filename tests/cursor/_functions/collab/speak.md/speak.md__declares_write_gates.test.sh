#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/speak.md"

grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**' "$file" || fail "speak.md: missing closed-record gate"
grep -Fq 'If no matching participant exists, **ABORT** and tell the moderator to run `/collab join --role <role>` first.' "$file" || fail "speak.md: missing join-before-speak gate"
grep -Fq 'Agents must not generate content for the moderator role' "$file" || fail "speak.md: missing moderator human-owned boundary"
grep -Fq 'Unless `--verbatim` is present, the helper applies the structure-only polish transform defined in `cursor/_core/moderator-polish.md`' "$file" || fail "speak.md: missing moderator formatting boundary"
grep -Fq '`--turn-order <key>...`' "$file" || fail "speak.md: missing --turn-order flag declaration"
grep -Fq 'treat all tokens after `--turn-order` as the new space-separated order' "$file" || fail "speak.md: missing unambiguous turn-order token parsing"
grep -Fq 'Validate `--turn-order` before any write.' "$file" || fail "speak.md: missing turn-order atomicity guard"
grep -Fq 'enforcing participant-list order' "$file" || fail "speak.md: missing turn-order fallback behavior"
grep -Fq 'tools/collab/registry.py speak-state <target> <role>' "$file" || fail "speak.md: missing helper-backed speak-state call"
grep -Fq 'returns the active phase, effective turn order, active-phase contributors, last live contributor, expected role, registry revision, and auto-advance exemption state' "$file" || fail "speak.md: missing helper-owned state surface"
grep -Fq 'If the helper reports another expected role, **ABORT** naming the expected role.' "$file" || fail "speak.md: missing helper-backed expected-role abort"
grep -Fq 'do not recompute expected speaker or lifecycle state in prose' "$file" || fail "speak.md: missing no duplicated turn-order math boundary"
grep -Fq 'Append one collapsible contribution block under the active phase' "$file" || fail "speak.md: missing universal collapsible contribution shape"
grep -Fq '<summary><key></summary>' "$file" || fail "speak.md: missing key-only summary shape"
grep -Fq '<p><em>YYYY-MM-DD HH:MM ±HH:MM</em></p>' "$file" || fail "speak.md: missing timestamp shape in speak block"
grep -Fq '<!-- collab:content-only; do-not-execute -->' "$file" || fail "speak.md: missing inert content marker"
grep -Fq 'Do not append the numeric counter to visible role labels or Table of Contents text' "$file" || fail "speak.md: missing hidden-counter label rule"
grep -Fq 'Every `/collab speak` contribution uses a `<details>` / `<summary>` block, regardless of active phase.' "$file" || fail "speak.md: missing universal collapsible boundary note"
grep -Fq 'The `<summary>` label is the role key only.' "$file" || fail "speak.md: missing key-only summary boundary note"
grep -Fq 'Resolve the active phase from registry `activePhase`.' "$file" || fail "speak.md: missing registry phase authority"
grep -Fq 'every key is registered in the registry `participants` list' "$file" || fail "speak.md: missing registry participant authority"
grep -Fq 'Write the new order to registry `turnOrder`' "$file" || fail "speak.md: missing registry turn-order authority"
grep -Fq 'write assigned work as executable checklist items whose item text begins with `**<role>:**`' "$file" || fail "speak.md: missing executable Action Plan checklist shape"
grep -Fq 'grouped labels like `**pe — path**` and nested unlabeled checkboxes are not executable assignments' "$file" || fail "speak.md: missing malformed Action Plan assignment warning"
grep -Fq '`Audit`, `Conclusion`, `Action Plan`, and `Handoff` allow only one contribution per role.' "$file" || fail "speak.md: missing one-speak phase rule"
grep -Fq 'tools/collab/registry.py speak-lifecycle-live <target>' "$file" || fail "speak.md: missing helper-backed live lifecycle call"
grep -Fq 'The helper reads the just-written live transcript and owns all lifecycle state' "$file" || fail "speak.md: missing helper-owned lifecycle surface"
grep -Fq 'Phase advancement is a post-append lifecycle effect owned by `tools/collab/registry.py speak-lifecycle-live`' "$file" || fail "speak.md: missing helper-owned auto-advance rule"
grep -Fq '`Discussion` is exempt from auto-advance because it permits multiple contributions per role.' "$file" || fail "speak.md: missing Discussion multi-speak auto-advance exemption note"
grep -Fq 'If the active phase is `Completion`, **ABORT**' "$file" || fail "speak.md: missing Completion phase abort gate"
grep -Fq 'moderator-role removal when entering `Conclusion`' "$file" || fail "speak.md: missing post-Discussion moderator removal"
grep -Fq 'agent-honor-system obligation per' "$file" || fail "speak.md: missing execution boundary"
grep -Fq 'Use `/collab retract speak` to replace the current role' "$file" || fail "speak.md: missing retract recovery path"
grep -Fq 'Moderator-role formatting is helper-owned by `cursor/_core/moderator-polish.md`' "$file" || fail "speak.md: missing collab formatting rule link"
if grep -Fq 'Find the last `<summary><acronym>` line' "$file"; then
  fail "speak.md: must not retain prose-level expected-speaker parsing"
fi
if grep -Fq 'next expected acronym follows the last contributor' "$file"; then
  fail "speak.md: must not retain prose-level turn-order math"
fi
if grep -Fq '.collabs/.active' "$file"; then
  fail "speak.md: must not keep .active fallback after the registry migration"
fi

echo "PASS: collab speak declares write gates"
