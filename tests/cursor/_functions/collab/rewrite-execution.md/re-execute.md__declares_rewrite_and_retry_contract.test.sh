#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/rewrite-execution.md"

grep -Fq '**Slash:** `/collab rewrite execution`' "$file" || fail "rewrite execution.md: missing slash declaration"
grep -Fq '**Signature:** `/collab rewrite execution`' "$file" || fail "rewrite execution.md: missing signature declaration"

# Gates: closed/archived and Completion-only
grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be re-executed.' "$file" || fail "rewrite execution.md: missing closed-record gate"
grep -Fq 'If the active phase is not `Completion`, **ABORT**: `/collab rewrite execution` is valid only when registry `activePhase` is `Completion`.' "$file" || fail "rewrite execution.md: missing Completion-only guard"
grep -Fq '/collab rewrite execution` must refuse all phases other than `Completion`' "$file" || fail "rewrite execution.md: missing Completion-only boundary note"

# Gate: idempotency — already succeeded
grep -Fq 'If the last entry is already marked `completed`, **ABORT**: last execution already succeeded; nothing to retry.' "$file" || fail "rewrite execution.md: missing already-succeeded idempotency gate"

# Gate: no prior entry — redirect to execute
grep -Fq '**ABORT**: no prior execution record to rewrite; use `/collab run plan` to begin execution.' "$file" || fail "rewrite execution.md: missing no-prior-entry abort gate"

# Progress marker written before implementation starts
grep -Fq 'in progress YYYY-MM-DD HH:MM — re-execution started.' "$file" || fail "rewrite execution.md: missing retry in-progress trace"
grep -Fq 'only when retry work begins before validation can complete in the same visible record' "$file" || fail "rewrite execution.md: missing limited retry progress contract"

# Validation sequence
grep -Fq 'Run scoped validation for the executing role.' "$file" || fail "rewrite execution.md: missing scoped validation sequence"
grep -Fq 'Do not run `./tests/run.sh` for ordinary role-scoped re-execution.' "$file" || fail "rewrite execution.md: missing ordinary retry full-suite prohibition"
grep -Fq 'If the retried item is the terminal full-suite Action Plan item, run the full sequence instead: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.' "$file" || fail "rewrite execution.md: missing terminal retry validation sequence"

# Success path: replaces both prior in-progress and failed lines; nothing stale visible
grep -Fq 'the `in progress` line, if present, and its subsequent `failed` line' "$file" || fail "rewrite execution.md: missing retry-line cleanup on success"
grep -Fq 'completed YYYY-MM-DD HH:MM — validation passed; <scope>; <N> paths.' "$file" || fail "rewrite execution.md: missing scoped success record"
grep -Fq 'Do not leave any failure or stale in-progress line visible.' "$file" || fail "rewrite execution.md: missing stale-line visibility guard"

# Failure path: appends new failure line; leaves prior entries unchanged
grep -Fq 'failed YYYY-MM-DD HH:MM — validation failed: <failed command>; <scope>; <N> paths.' "$file" || fail "rewrite execution.md: missing scoped failure record"
grep -Fq 'leave all prior entries unchanged' "$file" || fail "rewrite execution.md: missing prior-entries-unchanged contract on failure"

# Revision history shape: covers full prior attempt (both lines)
grep -Fq 'Revision history shape' "$file" || fail "rewrite execution.md: missing Revision history shape note"
grep -Fq 'its `in progress` line when present and `failed` line, in original order' "$file" || fail "rewrite execution.md: missing retry attempt revision history shape"
grep -Fq 'prepend the new attempt block inside the existing wrapper rather than nesting a second wrapper' "$file" || fail "rewrite execution.md: missing multiple-retry accumulation contract"

# Action plan checkbox sync
grep -Fq 'Check every completed role-scoped checklist item in `## Action Plan` as `[x]`.' "$file" || fail "rewrite execution.md: missing action-plan checkbox sync"

# Registry execution mirror and auto-close
grep -Fq 'Mirror execution state in the registry `execution` object' "$file" || fail "rewrite execution.md: missing registry execution mirror"
grep -Fq 'including validation result, validation scope, and touched paths' "$file" || fail "rewrite execution.md: missing validation scope registry mirror"
grep -Fq 'If every non-moderator assigned role has a completed execution entry' "$file" || fail "rewrite execution.md: missing auto-close condition"

# Execution boundary
grep -Fq 'This route implements only action-plan items assigned to the current role.' "$file" || fail "rewrite execution.md: missing execution boundary"

# Registry targeting
grep -Fq 'when absent, resolved per **Registry targeting** in **Notes**' "$file" || fail "rewrite execution.md: missing registry target parameter"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "rewrite execution.md: missing registry targeting source"

echo "PASS: rewrite execution.md declares rewrite and retry contract"
