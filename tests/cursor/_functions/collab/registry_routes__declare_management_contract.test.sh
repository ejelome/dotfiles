#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

list_file="$ROOT/cursor/_functions/collab/list.md"
use_file="$ROOT/cursor/_functions/collab/use.md"
open_file="$ROOT/cursor/_functions/collab/open.md"
kick_file="$ROOT/cursor/_functions/collab/kick.md"
delete_file="$ROOT/cursor/_functions/collab/delete.md"

grep -Fq '**Signature:** `/collab list`' "$list_file" || fail "list.md: missing list signature"
grep -Fq 'Return one line per collab with active marker, slug, status, active phase, and participant count.' "$list_file" || fail "list.md: missing list output shape"
grep -Fq '**Signature:** `/collab use <record>`' "$use_file" || fail "use.md: missing use signature"
grep -Fq 'Write the matched collab id to `active_collab_id`.' "$use_file" || fail "use.md: missing active pointer write"
grep -Fq '**Signature:** `/collab open`' "$open_file" || fail "open.md: missing open signature"
grep -Fq 'Update the registry status to `open`.' "$open_file" || fail "open.md: missing reopen status contract"
grep -Fq '**Signature:** `/collab kick <role>`' "$kick_file" || fail "kick.md: missing kick signature"
grep -Fq 'Remove `<role>` from registry `participants` and registry `turn_order`.' "$kick_file" || fail "kick.md: missing participant removal contract"
grep -Fq 'moderator cannot be removed by `/collab kick`' "$kick_file" || fail "kick.md: missing moderator protection"
grep -Fq '**Signature:** `/collab delete`' "$delete_file" || fail "delete.md: missing delete signature"
grep -Fq 'Default delete is archival only.' "$delete_file" || fail "delete.md: missing soft-delete default"
grep -Fq 'Require the explicit `--hard` flag before removing any transcript file.' "$delete_file" || fail "delete.md: missing hard-delete guard"

echo "PASS: collab registry routes declare management behavior"
