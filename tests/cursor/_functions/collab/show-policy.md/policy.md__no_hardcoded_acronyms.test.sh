#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/show-policy.md"

# Load bearing positions: any line that is not an example comment must not
# contain a bare role acronym (2-3 lowercase letters used as a word token).
# Example comments are tagged <!-- example --> and are exempt.
bad_lines="$(grep -vF '<!-- example -->' "$file" | grep -E '\b(pa|pe|tw|mod)\b' || true)"
if [[ -n "$bad_lines" ]]; then
  fail "policy.md: hard-coded role acronyms found outside example comments:
$bad_lines"
fi

grep -Fq 'tools/collab/registry.py roles' "$file" || fail "policy.md: must reference registry.py roles for role discovery"
grep -Fq 'reviewerRole' "$file" || fail "policy.md: must reference reviewerRole registry field"
grep -Fq 'Gate triggers' "$file" || fail "policy.md: must declare gate triggers"
grep -Fq 'Gate-blocked state' "$file" || fail "policy.md: must declare gate-blocked state"

echo "PASS: policy.md declares role-agnostic gate policy with no hard-coded acronyms"
