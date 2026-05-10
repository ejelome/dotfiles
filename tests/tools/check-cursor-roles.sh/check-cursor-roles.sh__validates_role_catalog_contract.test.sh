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

write_role() {
  local dir="$1" file="$2" key="$3"
  mkdir -p "$dir"
  cat >"$dir/$file.json" <<JSON
{
  "key": "$key",
  "displayName": "Test Role",
  "concerns": ["coverage"]
}
JSON
}

valid="$tmp/valid"
write_role "$valid" "pe" "pe"
output="$("$ROOT/tools/check-cursor-roles.sh" --roles-dir "$valid" 2>&1)"
assert_contains "$output" "check-cursor-roles: OK"

missing="$tmp/missing"
mkdir -p "$missing"
cat >"$missing/pe.json" <<'JSON'
{
  "key": "pe",
  "displayName": "Platform Engineer"
}
JSON
set +e
output="$("$ROOT/tools/check-cursor-roles.sh" --roles-dir "$missing" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-roles should fail when a required key is missing"
assert_contains "$output" "missing required key: concerns"

mismatch="$tmp/mismatch"
write_role "$mismatch" "platform" "pe"
set +e
output="$("$ROOT/tools/check-cursor-roles.sh" --roles-dir "$mismatch" 2>&1)"
status=$?
set -e
[[ $status -ne 0 ]] || fail "check-cursor-roles should fail when key mismatches filename"
assert_contains "$output" "key must match filename stem"

echo "PASS: check-cursor-roles validates role catalog contract"
