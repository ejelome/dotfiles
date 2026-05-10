#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/command-argument.md"

[[ -f "$file" ]] || fail "command-argument.md: missing _core flag contract"

grep -Fq 'Long-form tokens only' "$file" || fail "command-argument.md: missing long-form flag rule"
grep -Fq 'Exact case-sensitive match' "$file" || fail "command-argument.md: missing case-sensitive match rule"
grep -Fq 'Flags appear immediately after the route selector and before positional arguments' "$file" || fail "command-argument.md: missing pre-positional parse rule"
grep -Fq 'Interleaving flags with positional arguments is not supported' "$file" || fail "command-argument.md: missing interleaving rejection"
grep -Fq 'Unsupported flags abort before any route mutation' "$file" || fail "command-argument.md: missing unsupported flag abort"

grep -Fq '`hard-abort`' "$file" || fail "command-argument.md: missing hard-abort guard class"
grep -Fq '`gated-overwrite`' "$file" || fail "command-argument.md: missing gated-overwrite guard class"
for guard in registry-integrity output-mode-policy lifecycle-gate role-gate schema-validation unreadable-context destructive-delete; do
  grep -Fq "\`$guard\`" "$file" || fail "command-argument.md: missing ineligible guard class $guard"
done

grep -Fq 'The diff renderer takes `the candidate patch` as its sole input' "$file" || fail "command-argument.md: missing diff candidate-patch rule"
grep -Fq 'The post-confirmation write applies `the candidate patch` without recomputation or re-read of source' "$file" || fail "command-argument.md: missing write candidate-patch rule"
grep -Fq 'exact-confirmation-token contract' "$file" || fail "command-argument.md: missing gate token cross-reference"

for category in \
  'Flag position' \
  'Confirmation token' \
  'Registry-integrity guards' \
  'Lifecycle and role gates' \
  'Schema and role-JSON validation' \
  'Unreadable context' \
  'Destructive-delete guards' \
  'Patch-reference uniqueness'; do
  grep -Fq "$category" "$file" || fail "command-argument.md: missing negative-test category: $category"
done

echo "PASS: command-argument.md declares force negative contract"
