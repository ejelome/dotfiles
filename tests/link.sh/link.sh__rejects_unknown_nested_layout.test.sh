#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

home="$tmp/home"
cfg="$tmp/cursor"
mkdir -p "$home"
cp -R "$ROOT/cursor" "$cfg"

# Unknown nested layout: real directory instead of self-symlink.
mkdir -p "$cfg/commands/commands"

set +e
output="$(
  HOME="$home" \
  CURSOR_CONFIG_ROOT="$cfg" \
  SKIP_CURSOR_INSTALL=1 \
  SKIP_CURSOR_LAUNCHER=1 \
  INSTALL_ZSH_PLUGINS=0 \
  "$ROOT/link.sh" 2>&1
)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "link.sh should fail for unknown nested mirror layout"
assert_contains "$output" "nested mirror or unknown layout"

echo "PASS: link rejects unknown nested mirror layout"
