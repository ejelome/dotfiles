#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/run-plan.md"

grep -Fq '**Slash:** `/collab run plan`' "$file" || fail "execute.md: missing slash declaration"
grep -Fq '**Signature:** `/collab run plan`' "$file" || fail "execute.md: missing execute signature"
grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be executed.' "$file" || fail "execute.md: missing closed-record guard"
grep -Fq 'If the active phase is not `Completion`, **ABORT**: `/collab run plan` is valid only when registry `activePhase` is `Completion`.' "$file" || fail "execute.md: missing Completion-only guard"
grep -Fq 'Resolve the executing role from the registry participants list.' "$file" || fail "execute.md: missing registry-backed role resolution"
grep -Fq 'Collect all unchecked checklist items whose label begins with `**<role>:**` matching the resolved role.' "$file" || fail "execute.md: missing assigned item collection"
grep -Fq '_requires: #N_' "$file" || fail "execute.md: missing requires dependency check"
grep -Fq '_requires: #N #M_' "$file" || fail "execute.md: missing multi-item requires dependency check"
grep -Fq 'executing role, blocked item number, required item number(s), and required item state' "$file" || fail "execute.md: missing structured abort message format"
grep -Fq 'A handoff `requires` field may list one or more action-plan item numbers separated by spaces' "$file" || fail "execute.md: missing requires list parsing contract"
grep -Fq 'perform or halt' "$file" || fail "execute.md: missing perform-or-halt contract"
grep -Fq 'If an execution-history item matching `**<role>:** completed` already exists, report that the role'\''s execution is already complete and stop.' "$file" || fail "execute.md: missing role completion idempotency guard"
grep -Fq 'Ensure `## Completion` contains `**Execution history**`.' "$file" || fail "execute.md: missing execution-history section guard"
grep -Fq 'If using subagents for implementation work, declare one assigned write scope per subagent before spawning.' "$file" || fail "execute.md: missing per-subagent write-scope declaration"
grep -Fq 'For each subagent, call `tools/collab/registry.py execute-spawn <target> <role> --scope <path> --sibling-scope <path>...` to validate that worker'\''s assigned scope against the other declared scopes.' "$file" || fail "execute.md: missing per-subagent write-scope validation step"
grep -Fq 'After that subagent returns, call the same helper with `--returned-path <path>` for every returned path and reject any patch outside that worker'\''s assigned scope.' "$file" || fail "execute.md: missing returned-path assigned-scope gate"
grep -Fq 'Implement each collected action-plan item in source, in the order listed.' "$file" || fail "execute.md: missing implementation step"
grep -Fq 'Run scoped validation for the executing role.' "$file" || fail "execute.md: missing scoped role validation step"
grep -Fq 'Minimum scoped validation is `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`; add targeted tests for touched behavior when available.' "$file" || fail "execute.md: missing scoped validation minimum"
grep -Fq 'Do not run `./tests/run.sh` for ordinary role-scoped completion.' "$file" || fail "execute.md: missing ordinary role full-suite prohibition"
grep -Fq 'If the collected item is the terminal full-suite Action Plan item, run the full sequence instead: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.' "$file" || fail "execute.md: missing terminal full-suite validation sequence"
grep -Fq 'Check every completed role-scoped checklist item in `## Action Plan` as `[x]` before reporting success.' "$file" || fail "execute.md: missing action-plan checkbox sync"
grep -Fq 'Mirror execution state in the registry `execution` object' "$file" || fail "execute.md: missing registry execution mirror"
grep -Fq -- '--validation-scope scoped' "$file" || fail "execute.md: missing scoped validation metadata"
grep -Fq 'Use `--validation-scope full` only for the terminal full-suite item' "$file" || fail "execute.md: missing full validation metadata"
grep -Fq 'If every non-moderator assigned role, including the terminal full-suite owner, has a completed execution entry' "$file" || fail "execute.md: missing auto-close condition"
grep -Fq 'failed or missing entries leave the record open' "$file" || fail "execute.md: missing incomplete execution behavior"
grep -Fq 'Append the next numbered item as `<n>. **<role>:** completed YYYY-MM-DD HH:MM — validation passed; <scope>; <N> paths.`' "$file" || fail "execute.md: missing completion trace with scope and path count"
grep -Fq 'where `<scope>` is `scoped`, `full`, or `deferred` and `<N>` is the count of touched paths' "$file" || fail "execute.md: missing scope and path count description"
grep -Fq 'failed YYYY-MM-DD HH:MM — validation failed: <failed command>; <scope>; <N> paths' "$file" || fail "execute.md: missing failure trace with scope and path count"
grep -Fq 'Final-suite obligation' "$file" || fail "execute.md: missing final-suite obligation note"
grep -Fq 'Current behavior source' "$file" || fail "execute.md: missing current behavior source note"
grep -Fq 'The previous per-agent full-suite expectation came from this route'\''s explicit validation sequence, not from `tools/collab/registry.py`' "$file" || fail "execute.md: missing per-agent full-suite source finding"
grep -Fq 'Per-role `/collab run plan` execution must not invoke `./tests/run.sh` as a per-agent completion check' "$file" || fail "execute.md: missing per-agent full-suite prohibition"
grep -Fq 'When no reviewer exists, the fallback owner is the final non-moderator assigned role in `turnOrder`' "$file" || fail "execute.md: missing no-reviewer terminal owner fallback"
grep -Fq 'Action-plan items must not assign running the full test suite (`./tests/run.sh`) as a per-agent completion step' "$file" || fail "execute.md: missing checklist shape full-suite guard"
grep -Fq 'Late-failure recovery' "$file" || fail "execute.md: missing late-failure recovery note"
grep -Fq 'rewrite or add the failing role'\''s Action Plan item' "$file" || fail "execute.md: missing failing-role rewrite recovery"
grep -Fq 'target collab slug, id, or numeric `#N` as the first token after `run plan`; when absent, resolved per **Registry targeting** in **Notes**.' "$file" || fail "execute.md: missing registry target parameter"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "execute.md: missing registry targeting"
grep -Fq 'Items labeled for other roles are skipped without modification.' "$file" || fail "execute.md: missing other-role skip contract"
grep -Fq 'Executable items are flat checklist lines beginning with `**<role>:**`.' "$file" || fail "execute.md: missing flat executable checklist shape"
grep -Fq 'Nested checklist items, role-group headings, or unlabeled child tasks are not executable assignments.' "$file" || fail "execute.md: missing nested item exclusion"
grep -Fq 'Treat unchecked checklist items without a `**<role>:**` label as out of scope' "$file" || fail "execute.md: missing malformed item handling"
grep -Fq 'The parent declares one assigned write scope per subagent, uses `tools/collab/registry.py execute-spawn <target> <role> --scope <path> --sibling-scope <path>... [--returned-path <path>...]` as the per-subagent write-scope gate, rejects returned paths outside that subagent'\''s assigned scope, computes touched paths from the accepted parent patch after integrating returned work, runs repository validation itself, and records execution status from the parent role only.' "$file" || fail "execute.md: missing parent-owned subagent integration boundary"
grep -Fq 'A subagent never authors a collab turn and never mutates registry or transcript state independently.' "$file" || fail "execute.md: missing subagent registry/transcript boundary"
grep -Fq 'This route implements only action-plan items assigned to the current role.' "$file" || fail "execute.md: missing execution boundary"
grep -Fq 'must refuse `Audit`, `Discussion`, `Conclusion`, `Action Plan`, and `Handoff`.' "$file" || fail "execute.md: missing invalid phase list"

if grep -Fq '**Execution:** started' "$file"; then
  fail "execute.md: must not use old started marker"
fi
if grep -Fq 'in progress YYYY-MM-DD HH:MM — execution started' "$file"; then
  fail "execute.md: must not use two-event in-progress execution history format"
fi
if grep -Fq 'marks execution authorization' "$file"; then
  fail "execute.md: must not describe execute as authorization-only"
fi
if grep -Fq 'It never performs tasks listed in `## Action Plan`' "$file"; then
  fail "execute.md: must not preserve marker-only execution boundary"
fi
if grep -Fq '.collabs/.active' "$file"; then
  fail "execute.md: must not keep .active targeting after the registry migration"
fi

echo "PASS: collab execute declares role-scoped implementation behavior"
