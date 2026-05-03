#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/revamp/narrative.md"

grep -Fq 'Resolve `--role <key>` from the remaining input. If missing, **ABORT**: `--role <key>` is required.' "$file" || fail "narrative.md: missing required --role resolution step"
grep -Fq 'Read `cursor/_roles/<key>.json`. If unreadable, **ABORT**: role file unreadable; name the expected path.' "$file" || fail "narrative.md: missing role JSON read guard"
grep -Fq 'Validate the role JSON against [cursor/_core/role.md](../../_core/role.md): `key` must match `<key>`, and `displayName` and non-empty `concerns` must be present.' "$file" || fail "narrative.md: missing role schema validation"
grep -Fq 'If invalid, **ABORT**: invalid role JSON; name the failed field.' "$file" || fail "narrative.md: missing invalid role abort"
grep -Fq 'write the resolved key to `roleBindings[phase]`' "$file" || fail "narrative.md: missing roleBindings write contract"
grep -Fq "the resolved role's \`concerns\` array to \`concernRequirements[phase]\`" "$file" || fail "narrative.md: missing concernRequirements role-derived write"
grep -Fq '| `concernRequirements` | object | each phase | Map of phase name to the executing role'\''s `concerns` array, written after `roleBindings` is resolved; enforced as a hard gate at phase completion. |' "$file" || fail "narrative.md: concernRequirements schema row must be phase-owned and hard-gated"

echo "PASS: revamp/narrative.md declares role resolution contract"
