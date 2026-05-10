#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/route-sufficiency.md"

[[ -f "$file" ]] || fail "route-sufficiency.md: missing _core sufficiency contract"
grep -Fq '## Mechanical sufficiency' "$file" || fail "route-sufficiency.md: missing mechanical section"
grep -Fq '## Execution sufficiency' "$file" || fail "route-sufficiency.md: missing execution section"
grep -Fq 'This file is the first checked against its own mechanical rubric.' "$file" || fail "route-sufficiency.md: missing self-application statement"
grep -Fq 'This section is not lintable.' "$file" || fail "route-sufficiency.md: missing non-lintable execution boundary"
grep -Fq 'fresh agent' "$file" || fail "route-sufficiency.md: missing constrained fresh-agent fixture"
grep -Fq 'no prior conversation context' "$file" || fail "route-sufficiency.md: missing context-loss fixture"

for item in \
  '1. **Target resolution.**' \
  '2. **Helper-owned writes.**' \
  '3. **Role and phase preconditions.**' \
  '4. **Stop conditions.**' \
  '5. **Write scope.**' \
  '6. **Resume signals.**' \
  '7. **Recovery paths.**'
do
  grep -Fq "$item" "$file" || fail "route-sufficiency.md: missing mechanical item: $item"
done

echo "PASS: sufficiency declares route sufficiency contract"
