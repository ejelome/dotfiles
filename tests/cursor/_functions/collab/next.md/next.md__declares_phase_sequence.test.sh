#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/next.md"

grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**' "$file" || fail "next.md: missing closed-record gate"
grep -Fq 'Phase sequence:** `Audit` -> `Discussion` -> `Conclusion` -> `Action Plan` -> `Handoff` -> `Completion`' "$file" || fail "next.md: missing canonical phase sequence"
grep -Fq 'The moderator decides when this route runs.' "$file" || fail "next.md: missing moderator gate"

echo "PASS: collab next declares phase sequence"
