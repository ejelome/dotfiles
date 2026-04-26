#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

note() {
  echo "  $*"
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "expected path to exist: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
}

assert_symlink() {
  local path="$1"
  [[ -L "$path" ]] || fail "expected symlink: $path"
}

canonical_path() {
  local path="$1"
  python3 - "$path" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
}

assert_symlink_points_to() {
  local link_path="$1"
  local expected_path="$2"
  local actual expected
  assert_symlink "$link_path"
  actual="$(canonical_path "$link_path")"
  expected="$(canonical_path "$expected_path")"
  [[ "$actual" == "$expected" ]] || fail "symlink target mismatch: $link_path -> $actual (expected $expected)"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected text to contain: $needle"
}
