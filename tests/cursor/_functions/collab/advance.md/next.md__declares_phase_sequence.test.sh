#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/advance.md"

grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**' "$file" || fail "next.md: missing closed-record gate"
grep -Fq 'Phase sequence:** `Audit` -> `Discussion` -> `Conclusion` -> `Action Plan` -> `Handoff` -> `Completion`' "$file" || fail "next.md: missing canonical phase sequence"
grep -Fq 'If the next phase is `Conclusion`, the helper removes the moderator role from registry `turnOrder`' "$file" || fail "next.md: missing moderator removal before Conclusion"
grep -Fq 'Recovery path' "$file" || fail "next.md: missing helper mirror recovery path"
grep -Fq 'The moderator decides when this route runs.' "$file" || fail "next.md: missing moderator gate"

# Transition notices: compact at Discussion->Conclusion, subagent at Handoff->Completion
grep -Fq '"notice": "compact"' "$file" || fail "next.md: missing compact notice shape"
grep -Fq '"notice": "subagent"' "$file" || fail "next.md: missing subagent notice shape"
grep -Fq 'same notices are emitted when `speak-lifecycle-live` auto-advances' "$file" || fail "next.md: missing speak-lifecycle-live dual-path note"

echo "PASS: collab next declares phase sequence"
