#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/speak.md"

grep -Fq 'Effort override slot' "$file" || fail "speak.md: missing effort override slot note"
grep -Fq 'first content line after `<!-- collab:content-only; do-not-execute -->`' "$file" || fail "speak.md: missing override placement"
grep -Fq 'EFFORT OVERRIDE: <level> — <category>: <concrete signal>' "$file" || fail "speak.md: missing override line format"
grep -Fq 'hidden transcript metadata' "$file" || fail "speak.md: missing hidden override storage note"
grep -Fq 'rendered contribution prose starts with the human body' "$file" || fail "speak.md: missing reader-facing override suppression note"
grep -Fq 'coherence-risk' "$file" || fail "speak.md: missing coherence-risk category"
grep -Fq 'implementation-density' "$file" || fail "speak.md: missing implementation-density category"
grep -Fq 'deadlock-or-disagreement' "$file" || fail "speak.md: missing deadlock-or-disagreement category"
grep -Fq 'delivery-or-migration-risk' "$file" || fail "speak.md: missing delivery-or-migration-risk category"
grep -Fq 'reviewer-concern-raised' "$file" || fail "speak.md: missing reviewer-concern-raised category"
grep -Fq 'Moderator-role contributions are exempt from the effort override requirement.' "$file" || fail "speak.md: missing moderator override exemption"

echo "PASS: speak.md declares effort override slot"
