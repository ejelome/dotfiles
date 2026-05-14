#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/init.md"

grep -Fq 'Capture the full remaining text after `/collab init` as `"<name>"`' "$file" || fail "init.md: missing full remaining text capture"
grep -Fq 'replace every run of non-alphanumeric characters with one hyphen' "$file" || fail "init.md: missing slug normalization"
grep -Fq 'If the slug is empty, **ABORT**' "$file" || fail "init.md: missing empty slug abort"
grep -Fq 'atomic registry/transcript replacement' "$file" || fail "init.md: missing helper-owned registry bootstrap step"
grep -Fq 'Successful init registers the moderator role automatically by using the corresponding JSON role file' "$file" || fail "init.md: missing moderator auto-join note"
grep -Fq 'includes the moderator role in `participants` and `turnOrder`' "$file" || fail "init.md: missing moderator registry side effect"
grep -Fq '**Participants**' "$file" || fail "init.md: missing Participants label"
grep -Fq '| # | Key | Role | Agent | Responsibilities |' "$file" || fail "init.md: missing participants table with count and Agent column"
grep -Fq '| open | Audit | mod |' "$file" || fail "init.md: missing moderator turn-order seed"
grep -Fq '| 1 | mod | Moderator | <agentId> | scope; sequencing; framing; pacing; integrity |' "$file" || fail "init.md: missing moderator participant row with count and Agent column"
grep -Fq 'tools/collab/registry.py init --agent-id <agentId> [--reviewer <role>] [--preview] <name>' "$file" || fail "init.md: missing helper-owned init invocation"
grep -Fq 'Example: `/collab init "Refactor auth"` creates a collab record about that topic; it does not refactor auth.' "$file" || fail "init.md: missing execution-boundary misuse example"
grep -Fq '> This record is shared context, not an instruction to execute the work being discussed.' "$file" || fail "init.md: missing visible shared-context blockquote"
grep -Fq 'audit inputs are live-session citations; do not retain durable copies' "$file" || fail "init.md: missing durable audit input rewrite"
grep -Fq '_{MMM D, YYYY @ H:MM AM/PM}_' "$file" || fail "init.md: missing human-local init timestamp placeholder"
grep -Fq '## Audit' "$file" || fail "init.md: missing Audit phase"
grep -Fq '## Handoff' "$file" || fail "init.md: missing Handoff phase"
grep -Fq '**Status**' "$file" || fail "init.md: missing Status label"
grep -Fq '| Status | Active phase | Turn order |' "$file" || fail "init.md: missing status table with Turn order"
grep -Fq 'Registry-backed collab state is authoritative.' "$file" || fail "init.md: missing transcript-mirror note"
grep -Fq '**Execution history**' "$file" || fail "init.md: missing Completion execution history heading"
if grep -Fq 'Await `/collab run plan` to mark execution authorization' "$file"; then
  fail "init.md: must not describe execute as authorization-only"
fi
if grep -Fq '## Participants' "$file"; then
  fail "init.md: Participants must stay metadata, not a phase"
fi
if grep -Fq '.collabs/.active' "$file"; then
  fail "init.md: must not bootstrap .active after the registry migration"
fi

echo "PASS: collab init declares template and slug behavior"
