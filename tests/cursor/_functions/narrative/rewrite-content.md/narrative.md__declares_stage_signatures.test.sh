#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/narrative/rewrite-content.md"

grep -Fq "**Signature:** \`/narrative rewrite content <audit | align | gate> --role <key>\`" "$file" || fail "narrative.md: missing stage selector signature"
grep -Fq "**Stage signatures:** \`/narrative rewrite content audit --role <key>\` — \`--role\` required. \`/narrative rewrite content align --role <key>\` — reads state file; \`--role\` required. \`/narrative rewrite content gate --role <key>\` — reads \`validationCommands\` from state; \`--role\` required." "$file" || fail "narrative.md: missing stage signatures"
grep -Fq "For \`align\`, resolve the state file through \`tools/narrative/state.py align --role <key>\`" "$file" || fail "narrative.md: missing align state file validation"
grep -Fq "tools/narrative/state.py align" "$file" || fail "narrative.md: missing align state helper"
grep -Fq "runtime guard rejects symlinked \`~/.cursor\` projections" "$file" || fail "narrative.md: missing align runtime guard"
grep -Fq "**Phase 3 — Gate:** Read \`validationCommands\` from state by calling \`tools/narrative/state.py gate --role <key>\`. Report only — do not attempt fixes." "$file" || fail "narrative.md: missing state-backed report-only gate"
grep -Fq "**State file:** \`.revamps/<repo-basename>-<YYYY-MM-DD>.json\`" "$file" || fail "narrative.md: missing state path"
grep -Fq '| `repoRoot` | string | audit | Absolute path of the CWD at invocation time |' "$file" || fail "narrative.md: missing repoRoot state field"
grep -Fq '| `activeStage` | string | each phase | Last completed stage name |' "$file" || fail "narrative.md: missing activeStage state field"
grep -Fq '| `narrativeGlobs` | array | audit | Narrative file globs in scope |' "$file" || fail "narrative.md: missing narrativeGlobs state field"
grep -Fq '| `ruleAlignTargets` | array | align | Project and runtime rule paths compared by align |' "$file" || fail "narrative.md: missing ruleAlignTargets state field"
grep -Fq '| `validationCommands` | array | audit | Repo-specific validation commands discovered at invocation time |' "$file" || fail "narrative.md: missing validationCommands state field"
grep -Fq "Gate reads \`validationCommands\` from state; it does not use hardcoded commands." "$file" || fail "narrative.md: missing repo-aware gate contract"
! grep -Fq 'SKIP_TESTS_RUN=1 ./tools/smoke-check.sh' "$file" || fail "narrative.md: gate must not hardcode dotfiles smoke-check command"
! grep -Fq 'SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh' "$file" || fail "narrative.md: gate must not hardcode dotfiles runtime smoke-check command"
[[ ! -e "$ROOT/cursor/_functions/narrative/content.md" ]] || fail "content.md: old route function must not exist"

echo "PASS: narrative/rewrite-content.md declares per-stage signatures and validation"
