#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/join.md"

grep -Fq 'Read `../../_roles/<role>.json`.' "$file" || fail "join.md: missing role JSON read"
grep -Fq 'cursor/_core/role.md' "$file" || fail "join.md: missing role schema"
grep -Fq '`key` (must match `<role>`), `displayName`, `concerns`' "$file" || fail "join.md: missing role schema"
grep -Fq 'tools/collab/registry.py join-participants' "$file" || fail "join.md: missing join-participants helper call"
grep -Fq '| <#> | <key> | <displayName> | <agentId> | <concern>; <concern> |' "$file" || fail "join.md: missing agentId participant row format"
grep -Fq 'Role JSON files live under `cursor/_roles/` as shared command-owned data, not route playbooks.' "$file" || fail "join.md: missing role data boundary"

echo "PASS: collab join declares the role JSON contract"
