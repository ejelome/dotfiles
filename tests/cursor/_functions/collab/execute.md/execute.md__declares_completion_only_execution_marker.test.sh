#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/execute.md"

grep -Fq '**Slash:** `/collab execute`' "$file" || fail "execute.md: missing slash declaration"
grep -Fq '**Signature:** `/collab execute`' "$file" || fail "execute.md: missing execute signature"
grep -Fq 'If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be executed.' "$file" || fail "execute.md: missing closed-record guard"
grep -Fq 'If the active phase is not `Completion`, **ABORT**: `/collab execute` is valid only when registry `activePhase` is `Completion`.' "$file" || fail "execute.md: missing Completion-only guard"
grep -Fq 'Resolve the executing role from the registry participants list.' "$file" || fail "execute.md: missing registry-backed role resolution"
grep -Fq 'Collect all unchecked checklist items whose label begins with `**<role>:**` matching the resolved role.' "$file" || fail "execute.md: missing assigned item collection"
grep -Fq '_requires: #N_' "$file" || fail "execute.md: missing requires dependency check"
grep -Fq '_requires: #N #M_' "$file" || fail "execute.md: missing multi-item requires dependency check"
grep -Fq 'executing role, blocked item number, required item number(s), and required item state' "$file" || fail "execute.md: missing structured abort message format"
grep -Fq 'A handoff `requires` field may list one or more action-plan item numbers separated by spaces' "$file" || fail "execute.md: missing requires list parsing contract"
grep -Fq 'perform or halt' "$file" || fail "execute.md: missing perform-or-halt contract"
grep -Fq 'If an execution-history item matching `**<role>:** completed` already exists, report that the role'\''s execution is already complete and stop.' "$file" || fail "execute.md: missing role completion idempotency guard"
grep -Fq 'Ensure `## Completion` contains `**Execution history**`, then append the next numbered item as `<n>. **<role>:** in progress YYYY-MM-DD HH:MM — execution started.`.' "$file" || fail "execute.md: missing in-progress execution trace"
grep -Fq 'Implement each collected action-plan item in source, in the order listed.' "$file" || fail "execute.md: missing implementation step"
grep -Fq 'Run the validation sequence: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.' "$file" || fail "execute.md: missing validation sequence"
grep -Fq 'Check every completed role-scoped checklist item in `## Action Plan` as `[x]` before reporting success.' "$file" || fail "execute.md: missing action-plan checkbox sync"
grep -Fq 'Mirror execution state in the registry `execution` object' "$file" || fail "execute.md: missing registry execution mirror"
grep -Fq 'If every non-moderator assigned role has a completed execution entry' "$file" || fail "execute.md: missing auto-close condition"
grep -Fq 'failed or missing entries leave the record open' "$file" || fail "execute.md: missing incomplete execution behavior"
grep -Fq 'Append the next numbered item as `<n>. **<role>:** completed YYYY-MM-DD HH:MM — validation passed.` after validation passes.' "$file" || fail "execute.md: missing completion trace"
grep -Fq 'If validation fails, append `<n>. **<role>:** failed YYYY-MM-DD HH:MM — validation failed: <failed command>.` before reporting.' "$file" || fail "execute.md: missing failure trace"
grep -Fq 'target collab slug, id, or numeric `#N` as the first token after `execute`; when absent, resolved per **Registry targeting** in **Notes**.' "$file" || fail "execute.md: missing registry target parameter"
grep -Fq 'Resolve the target collab from `.collabs/registry.json`' "$file" || fail "execute.md: missing registry targeting"
grep -Fq 'Items labeled for other roles are skipped without modification.' "$file" || fail "execute.md: missing other-role skip contract"
grep -Fq 'Treat unchecked checklist items without a `**<role>:**` label as out of scope' "$file" || fail "execute.md: missing malformed item handling"
grep -Fq 'This route implements only action-plan items assigned to the current role.' "$file" || fail "execute.md: missing execution boundary"
grep -Fq 'must refuse `Audit`, `Discussion`, `Conclusion`, `Action Plan`, and `Handoff`.' "$file" || fail "execute.md: missing invalid phase list"

if grep -Fq '**Execution:** started' "$file"; then
  fail "execute.md: must not use legacy started marker"
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
