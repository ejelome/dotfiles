#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/re-execute.md"

grep -Fq '**Slash:** `/collab re-execute`' "$file" || fail "re-execute.md: missing slash declaration"
grep -Fq '**Signature:** `/collab re-execute`' "$file" || fail "re-execute.md: missing signature declaration"

# Gates: closed/archived and Completion-only
grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be re-executed.' "$file" || fail "re-execute.md: missing closed-record gate"
grep -Fq 'If the active phase is not `Completion`, **ABORT**: `/collab re-execute` is valid only when registry `activePhase` is `Completion`.' "$file" || fail "re-execute.md: missing Completion-only guard"
grep -Fq '/collab re-execute` must refuse all phases other than `Completion`' "$file" || fail "re-execute.md: missing Completion-only boundary note"

# Gate: idempotency — already succeeded
grep -Fq 'If the last entry is already marked `completed`, **ABORT**: last execution already succeeded; nothing to retry.' "$file" || fail "re-execute.md: missing already-succeeded idempotency gate"

# Gate: no prior entry — redirect to execute
grep -Fq '**ABORT**: no prior execution record to rewrite; use `/collab execute` to begin execution.' "$file" || fail "re-execute.md: missing no-prior-entry abort gate"

# Progress marker written before implementation starts
grep -Fq 'in progress YYYY-MM-DD HH:MM — re-execution started.' "$file" || fail "re-execute.md: missing in-progress trace before implementation"

# Validation sequence
grep -Fq 'Run the validation sequence: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.' "$file" || fail "re-execute.md: missing validation sequence"

# Success path: replaces both prior in-progress and failed lines; nothing stale visible
grep -Fq 'the `in progress` line and its subsequent `failed` line' "$file" || fail "re-execute.md: missing both-lines cleanup on success"
grep -Fq 'Do not leave any failure or stale in-progress line visible.' "$file" || fail "re-execute.md: missing stale-line visibility guard"

# Failure path: appends new failure line; leaves prior entries unchanged
grep -Fq 'leave all prior entries unchanged' "$file" || fail "re-execute.md: missing prior-entries-unchanged contract on failure"

# Revision history shape: covers full prior attempt (both lines)
grep -Fq 'Revision history shape' "$file" || fail "re-execute.md: missing Revision history shape note"
grep -Fq 'its `in progress` line and `failed` line, in original order' "$file" || fail "re-execute.md: missing full-attempt revision history shape"
grep -Fq 'prepend the new attempt block inside the existing wrapper rather than nesting a second wrapper' "$file" || fail "re-execute.md: missing multiple-retry accumulation contract"

# Action plan checkbox sync
grep -Fq 'Check every completed role-scoped checklist item in `## Action Plan` as `[x]`.' "$file" || fail "re-execute.md: missing action-plan checkbox sync"

# Registry execution mirror and auto-close
grep -Fq 'Mirror execution state in the registry `execution` object' "$file" || fail "re-execute.md: missing registry execution mirror"
grep -Fq 'If every non-moderator assigned role has a completed execution entry' "$file" || fail "re-execute.md: missing auto-close condition"

# Execution boundary
grep -Fq 'This route implements only action-plan items assigned to the current role.' "$file" || fail "re-execute.md: missing execution boundary"

# Registry targeting
grep -Fq 'when absent, resolved per **Registry targeting** in **Notes**' "$file" || fail "re-execute.md: missing registry target parameter"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "re-execute.md: missing registry targeting source"

echo "PASS: re-execute.md declares rewrite and retry contract"
