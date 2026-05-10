#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/agent/upgrade.md"

[[ -f "$file" ]] || fail "upgrade.md: missing /agent upgrade route"

grep -Fq 'Verify `AGENTS.md`, `CLAUDE.md`, and `REPOSITORY.md` exist' "$file" || fail "upgrade.md: missing incomplete-scaffold abort"
grep -Fq 'scaffold-version marker not found in `AGENTS.md`' "$file" || fail "upgrade.md: missing marker-missing abort"
grep -Fq 'Compare the two marker strings using lexicographic equality' "$file" || fail "upgrade.md: missing literal marker comparison"
grep -Fq 'scaffold is up to date' "$file" || fail "upgrade.md: missing current-scaffold idempotency exit"

grep -Fq 'collect the file and compute a per-file changed-block summary' "$file" || fail "upgrade.md: missing changed-block summary before confirmation"
grep -Fq 'Gate the overwrite per' "$file" || fail "upgrade.md: missing single confirmation gate"
grep -Fq 'If the user does not type the exact proceed token, leave all files and the marker untouched' "$file" || fail "upgrade.md: missing no-confirmation unchanged-files guarantee"
grep -Fq 'If confirmed: write every accepted file in full from the corresponding template' "$file" || fail "upgrade.md: missing confirmed-upgrade write behavior"

grep -Fq 'All writes are all-or-nothing' "$file" || fail "upgrade.md: missing all-or-nothing write rule"
grep -Fq 'do not leave a partial upgrade' "$file" || fail "upgrade.md: missing partial-write guard"
grep -Fq 'The marker in the newly written `AGENTS.md` is the current template marker value' "$file" || fail "upgrade.md: missing marker-bump coupling to confirmed write"

grep -Fq 'If the proposed change overlaps any section that has been patched' "$file" || fail "upgrade.md: missing REPOSITORY.md overlap detection"
grep -Fq 'record a targeted skip message for `REPOSITORY.md` and exclude it from the confirmation step' "$file" || fail "upgrade.md: missing REPOSITORY.md refuse-on-overlap behavior"
grep -Fq 'the other files continue' "$file" || fail "upgrade.md: missing REPOSITORY.md non-partial continuation wording"

grep -Fq 'Upgrade rewrite rule for `cursor/_CURSOR.md` link' "$file" || fail "upgrade.md: missing cursor/_CURSOR.md rewrite rule"
grep -Fq 'contains a link to `cursor/_CURSOR.md`' "$file" || fail "upgrade.md: missing exact cursor/_CURSOR.md trigger"
grep -Fq 'remove the `cursor/_CURSOR.md` entry from the Entry points list' "$file" || fail "upgrade.md: missing exact cursor/_CURSOR.md removal behavior"
grep -Fq 'the target repo'\''s `AGENTS.md` file satisfies both (a) the `<!-- scaffold-version: ... -->` marker is present and (b) the target repo does not contain `_templates/AGENTS.md` at any tracked path' "$file" || fail "upgrade.md: missing exact two-condition rewrite predicate"
grep -Fq 'Do not apply this rewrite unless both conditions are met' "$file" || fail "upgrade.md: missing negative guard for partial predicate matches"

echo "PASS: upgrade.md declares scaffold upgrade safety contract"
