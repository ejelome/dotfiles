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
  local root="$1" rel="$2" block="$3"
  local path="$root/_functions/$rel"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<MD
# Test Route

Gate contract: cursor/_core/command-argument.md.

$block
MD
}

valid_block='```cursor-gate
gate-class: destructive
proceed: delete <slug>
abort: cancel
operand-format: collab registry id
invalid-input: re-prompt
re-prompt-template: Type "delete <slug>" to delete this collab, or "cancel" to abort.
```'

missing_field_root="$tmp/missing-field/cursor"
write_route "$missing_field_root" "collab/delete.md" '```cursor-gate
gate-class: destructive
proceed: delete <slug>
abort: cancel
operand-format: collab registry id
re-prompt-template: Type "delete <slug>" to delete this collab, or "cancel" to abort.
```'
set +e
output="$("$ROOT/tools/check-cursor-gates.sh" --cursor-config-root "$missing_field_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-gates should fail when a required field is missing"
assert_contains "$output" "invalid-input: missing required field"

bad_verb_root="$tmp/bad-verb/cursor"
write_route "$bad_verb_root" "agent/upgrade.md" '```cursor-gate
gate-class: destructive
proceed: destroy <repo>
abort: cancel
operand-format: repository path
invalid-input: re-prompt
re-prompt-template: Type "destroy <repo>" to proceed, or "cancel" to abort.
```'
set +e
output="$("$ROOT/tools/check-cursor-gates.sh" --cursor-config-root "$bad_verb_root" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-gates should fail when a destructive verb is out of set"
assert_contains "$output" "proceed: destructive proceed verb is not in the closed set"

valid_root="$tmp/valid/cursor"
write_route "$valid_root" "collab/delete.md" "$valid_block"
write_route "$valid_root" "git/commit.md" '```cursor-gate
gate-class: standard
proceed: confirm
abort: cancel
operand-format: none
invalid-input: re-prompt
re-prompt-template: Type "confirm" to proceed, or "cancel" to abort.
```'
output="$("$ROOT/tools/check-cursor-gates.sh" --cursor-config-root "$valid_root" 2>&1)"
assert_contains "$output" "check-cursor-gates: OK"

echo "PASS: check-cursor-gates validates gate declaration blocks"
