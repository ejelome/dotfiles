#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/join.md"

grep -Fq 'Read `roles/<role>.json` beside this playbook.' "$file" || fail "join.md: missing role JSON read"
grep -Fq 'JSON object with `acronym` matching `<role>`' "$file" || fail "join.md: missing role schema"
grep -Fq 'Replace `**Participants:** none`' "$file" || fail "join.md: missing participant metadata update"
grep -Fq 'Role JSON files are command-owned data, not route playbooks.' "$file" || fail "join.md: missing role data boundary"

echo "PASS: collab join declares the role JSON contract"
