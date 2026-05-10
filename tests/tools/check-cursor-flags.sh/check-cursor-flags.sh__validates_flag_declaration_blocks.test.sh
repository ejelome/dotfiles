#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

write_route() {
  local root="$1" rel="$2" block="$3" body="${4:-}"
  local path="$root/_functions/$rel"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<MD
# Test Route

Flag contract: cursor/_core/command-argument.md.

$block

$body
MD
}

eligible_block='```cursor-flag
flag: force
eligibility: eligible
guard-class: gated-overwrite
```'

hard_abort_block='```cursor-flag
flag: force
eligibility: eligible
guard-class: hard-abort
```'

registry_block='```cursor-flag
flag: force
eligibility: ineligible
guard-class: registry-integrity
ineligibility-reason: Registry collisions protect shared state.
```'

output_mode_block='```cursor-flag
flag: force
eligibility: ineligible
guard-class: output-mode-policy
ineligibility-reason: Output mode is not an artifact conflict.
```'

candidate_body='Diff step renders `the candidate patch`. Write step applies `the candidate patch`.'

write_required_routes() {
  local root="$1"
  write_route "$root" "agent/install.md" "$hard_abort_block" "$candidate_body"
  write_route "$root" "agent/patch.md" "$eligible_block" "$candidate_body"
  write_route "$root" "agent/upgrade.md" "$eligible_block" "$candidate_body"
  write_route "$root" "doc/compact.md" "$output_mode_block"
  write_route "$root" "collab/init.md" "$registry_block"
}

missing_field_root="$tmp/missing-field/cursor"
write_required_routes "$missing_field_root"
write_route "$missing_field_root" "agent/patch.md" '```cursor-flag
flag: force
eligibility: eligible
```' "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$missing_field_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail when a required field is missing"
assert_contains "$output" "guard-class: missing required field"

malformed_root="$tmp/malformed/cursor"
write_required_routes "$malformed_root"
write_route "$malformed_root" "agent/install.md" '```cursor-flag
flag force
eligibility: eligible
guard-class: hard-abort
```' "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$malformed_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on malformed block lines"
assert_contains "$output" "block: malformed line: flag force"

duplicate_root="$tmp/duplicate/cursor"
write_required_routes "$duplicate_root"
write_route "$duplicate_root" "agent/install.md" "$hard_abort_block

$hard_abort_block" "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$duplicate_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on duplicate route flag blocks"
assert_contains "$output" "duplicate cursor-flag block for force"

unknown_guard_root="$tmp/unknown-guard/cursor"
write_required_routes "$unknown_guard_root"
write_route "$unknown_guard_root" "agent/install.md" '```cursor-flag
flag: force
eligibility: eligible
guard-class: maybe-overwrite
```' "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$unknown_guard_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on unknown guard classes"
assert_contains "$output" "guard-class: unknown guard class"

unknown_flag_root="$tmp/unknown-flag/cursor"
write_required_routes "$unknown_flag_root"
write_route "$unknown_flag_root" "agent/install.md" '```cursor-flag
flag: dry-run
eligibility: eligible
guard-class: hard-abort
```' "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$unknown_flag_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on unknown flags"
assert_contains "$output" "flag: unknown flag"

composition_root="$tmp/composition/cursor"
write_required_routes "$composition_root"
write_route "$composition_root" "agent/install.md" '```cursor-flag
flag: force
eligibility: eligible
guard-class: registry-integrity
```' "$candidate_body"
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$composition_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on eligible blocks with ineligible guard classes"
assert_contains "$output" "eligible force blocks cannot use an ineligible guard class"

missing_reason_root="$tmp/missing-reason/cursor"
write_required_routes "$missing_reason_root"
write_route "$missing_reason_root" "collab/init.md" '```cursor-flag
flag: force
eligibility: ineligible
guard-class: registry-integrity
```'
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$missing_reason_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on missing ineligibility reasons"
assert_contains "$output" "ineligibility-reason: missing required field for ineligible flag"

missing_ref_root="$tmp/missing-ref/cursor"
write_required_routes "$missing_ref_root"
path="$missing_ref_root/_functions/doc/compact.md"
python3 - "$path" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
path.write_text(path.read_text().replace("Flag contract: cursor/_core/command-argument.md.\n\n", ""))
PY
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$missing_ref_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail when flag routes omit the core flag citation"
assert_contains "$output" "flag-contract: missing cursor/_core/command-argument.md citation"

missing_phrase_root="$tmp/missing-phrase/cursor"
write_required_routes "$missing_phrase_root"
write_route "$missing_phrase_root" "agent/patch.md" "$eligible_block" 'Diff step renders a summary. Write step applies it.'
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$missing_phrase_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail when eligible routes omit the candidate patch phrase"
assert_contains "$output" "canonical-phrase: eligible force routes must mention"

alternate_patch_root="$tmp/alternate-patch/cursor"
write_required_routes "$alternate_patch_root"
write_route "$alternate_patch_root" "agent/patch.md" "$eligible_block" 'Diff step renders `the candidate patch`. Write step applies `the candidate patch`. Then discard the proposed patch.'
set +e
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$alternate_patch_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-flags should fail on alternate patch identifiers"
assert_contains "$output" "patch-reference: non-canonical patch reference(s): the proposed patch"

valid_root="$tmp/valid/cursor"
write_required_routes "$valid_root"
output="$("$ROOT/tools/check-cursor-flags.sh" --cursor-config-root "$valid_root" 2>&1)"
assert_contains "$output" "check-cursor-flags: OK"

echo "PASS: check-cursor-flags validates flag declaration blocks"
