#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/revamp/narrative.md"

grep -Fq 'Reruns overwrite `roleBindings[phase]`, `concernRequirements[phase]`, and `phaseOutputs[phase]` together; do not append history.' "$file" || fail "narrative.md: missing rerun overwrite semantics"
grep -Fq 'After a phase emits its structured artifact, write that artifact to `phaseOutputs[phase]` in the state file.' "$file" || fail "narrative.md: missing phaseOutputs write contract"
grep -Fq '`align` must read `phaseOutputs.audit` before producing output.' "$file" || fail "narrative.md: missing align prior-output read"
grep -Fq '`gate` must read both `phaseOutputs.audit` and `phaseOutputs.align` before producing output.' "$file" || fail "narrative.md: missing gate prior-output reads"
grep -Fq 'Never rely on chat history or prose outside the state file for prior-phase handoff.' "$file" || fail "narrative.md: missing state-only handoff boundary"
grep -Fq 'Verify that `coveredConcerns` is a superset of `concernRequirements[phase]` and that the artifact has non-empty content for every claimed concern.' "$file" || fail "narrative.md: missing concern coverage verification"
grep -Fq 'For `audit` and `align`, **ABORT** after emitting the artifact; for `gate`, report `Result: fail`.' "$file" || fail "narrative.md: missing coverage failure behavior"
grep -Fq 'If prior `phaseOutputs` entries are missing or malformed, report `Result: blocked`.' "$file" || fail "narrative.md: missing malformed handoff blocking behavior"
grep -Fq 'Also read `phaseOutputs.audit` and `phaseOutputs.align` from state.' "$file" || fail "narrative.md: missing gate handoff state reads"

echo "PASS: revamp/narrative.md declares handoff state contract"
