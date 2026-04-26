#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_mdc/auto/auto-collab-message-format.mdc"

grep -Fq 'description: "[auto] auto-collab-message-format.mdc:' "$file" || fail "auto-collab-message-format.mdc: missing canonical description"
grep -Fq 'alwaysApply: true' "$file" || fail "auto-collab-message-format.mdc: missing alwaysApply: true"
grep -Fq '**Triggers:** `auto-collab-message-format`' "$file" || fail "auto-collab-message-format.mdc: missing canonical trigger"
grep -Fq 'Apply after `/collab speak` captures moderator (or other human-supplied) text.' "$file" || fail "auto-collab-message-format.mdc: missing moderator capture scope"
grep -Fq 'A formatting pass is **not** permission to rephrase' "$file" || fail "auto-collab-message-format.mdc: missing no-rephrase boundary"
grep -Fq 'Limit structure-only edits to bullets, labels' "$file" || fail "auto-collab-message-format.mdc: missing edit limit"
grep -Fq 'Never add facts, decisions, scope, answers, summaries, lead-ins, or new framing.' "$file" || fail "auto-collab-message-format.mdc: missing no-new-content boundary"
grep -Fq 'Skip the formatting pass when the user says `verbatim only`, `exactly as written`, or `do not rephrase`.' "$file" || fail "auto-collab-message-format.mdc: missing verbatim override"

echo "PASS: auto-collab-message-format.mdc declares structure-only formatting behavior"
