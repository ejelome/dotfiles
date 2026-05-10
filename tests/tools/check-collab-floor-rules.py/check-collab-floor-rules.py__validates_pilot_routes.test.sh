#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

write_route() {
  local root="$1" rel="$2" body="$3"
  local path="$root/$rel"
  mkdir -p "$(dirname "$path")" "$root/cursor/_core"
  printf '# Invariants\n' >"$root/cursor/_core/route-invariant.md"
  cat >"$root/cursor/_core/route-sufficiency.md" <<'MD'
# Route sufficiency

This file is the first checked against its own mechanical rubric.

## Mechanical sufficiency

1. **Target resolution.** Test item.
2. **Helper-owned writes.** Test item.
3. **Role and phase preconditions.** Test item.
4. **Stop conditions.** Test item.
5. **Write scope.** Test item.
6. **Resume signals.** Test item.
7. **Recovery paths.** Test item.

## Execution sufficiency

Fixture obligations are not lintable. A fresh agent with no prior conversation context must execute from explicit references.
MD
  printf '%s\n' "$body" >"$path"
}

valid_route='# /collab init

## Trigger

**Slash:** `/collab init`

## Steps

1. Resolve the target collab id and transcript path. If resolution fails, **ABORT**: target unavailable.
2. Write the transcript and registry from the route template.
3. Call `tools/collab/registry.py join-participants <target> --agent-id <agentId>`.
4. Stop after updating registry and transcript.

## Notes

- **Phase precondition:** Runs before any contribution phase exists.
- **Post-state resume signal:** Run `tools/collab/registry.py speak-state --resume <target> <role>` before writing.
- **Execution boundary:** Only write under `.collabs/`.
- **Recovery path:** Retry after restoring the missing helper-owned projection.
- **Floor rule 3 compliance:** Step 2 is a prose-rendered write and is a temporary exemption per [`_core/route-invariant.md`](../../_core/route-invariant.md).
'

missing_helper_route='# /collab init

## Trigger

**Slash:** `/collab init`

## Steps

1. Resolve the target.
2. Write the transcript and registry from the route template.
3. Call `tools/collab/registry.py join-participants <target> --agent-id <agentId>`.
4. Stop after updating registry and transcript.

## Notes

- **Post-state resume signal:** Run `tools/collab/registry.py speak-state --resume <target> <role>` before writing.
'

valid_root="$tmp/valid"
write_route "$valid_root" "cursor/_functions/collab/init.md" "$valid_route"
output="$("$ROOT/tools/check-collab-floor-rules.py" --root "$valid_root" --route cursor/_functions/collab/init.md 2>&1)"
assert_contains "$output" "check-collab-floor-rules: OK"

missing_helper_root="$tmp/missing-helper"
write_route "$missing_helper_root" "cursor/_functions/collab/init.md" "$missing_helper_route"
set +e
output="$("$ROOT/tools/check-collab-floor-rules.py" --root "$missing_helper_root" --route cursor/_functions/collab/init.md 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-collab-floor-rules should fail without helper ownership or exemption"
assert_contains "$output" "mutating step(s) lack helper ownership or floor-rule exemption"

missing_stop_root="$tmp/missing-stop"
write_route "$missing_stop_root" "cursor/_functions/collab/init.md" "${valid_route/4. Stop after updating registry and transcript./4. Report the update.}"
set +e
output="$("$ROOT/tools/check-collab-floor-rules.py" --root "$missing_stop_root" --route cursor/_functions/collab/init.md 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-collab-floor-rules should fail without a stop condition"
assert_contains "$output" "missing explicit stop condition"

missing_resume_root="$tmp/missing-resume"
write_route "$missing_resume_root" "cursor/_functions/collab/init.md" "${valid_route/speak-state --resume <target> <role>/speak-state <target> <role>/}"
set +e
output="$("$ROOT/tools/check-collab-floor-rules.py" --root "$missing_resume_root" --route cursor/_functions/collab/init.md 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-collab-floor-rules should fail without a resume signal"
assert_contains "$output" "missing post-state resume signal"

broken_link_root="$tmp/broken-link"
broken_route="${valid_route/..\/..\/_core\/route-invariant.md/..\/..\/_core\/missing.md}"
write_route "$broken_link_root" "cursor/_functions/collab/init.md" "$broken_route"
set +e
output="$("$ROOT/tools/check-collab-floor-rules.py" --root "$broken_link_root" --route cursor/_functions/collab/init.md 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-collab-floor-rules should fail on broken declared links"
assert_contains "$output" "broken link target"

echo "PASS: check-collab-floor-rules.py validates pilot routes"
