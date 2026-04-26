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

ln -s "$cfg/commands" "$cfg/commands/commands"
ln -s "$cfg/rules" "$cfg/rules/rules"
ln -s "$cfg/_functions" "$cfg/_functions/_functions"
ln -s "$cfg/_core" "$cfg/_core/_core"
ln -s "$cfg/_mdc" "$cfg/_mdc/_mdc"
ln -s "$cfg/_tests" "$cfg/_tests/_tests"

HOME="$home" \
CURSOR_CONFIG_ROOT="$cfg" \
SKIP_CURSOR_INSTALL=1 \
SKIP_CURSOR_LAUNCHER=1 \
INSTALL_ZSH_PLUGINS=0 \
"$ROOT/link.sh" >/dev/null

assert_not_exists "$cfg/commands/commands"
assert_not_exists "$cfg/rules/rules"
assert_not_exists "$cfg/_functions/_functions"
assert_not_exists "$cfg/_core/_core"
assert_not_exists "$cfg/_mdc/_mdc"
assert_not_exists "$cfg/_tests/_tests"

assert_symlink_points_to "$home/.cursor/commands" "$cfg/commands"
assert_symlink_points_to "$home/.cursor/rules" "$cfg/rules"
assert_symlink_points_to "$home/.cursor/_functions" "$cfg/_functions"
assert_symlink_points_to "$home/.cursor/_core" "$cfg/_core"
assert_symlink_points_to "$home/.cursor/_mdc" "$cfg/_mdc"
assert_symlink_points_to "$home/.cursor/_tests" "$cfg/_tests"
assert_symlink_points_to "$home/.cursor/_CURSOR.md" "$cfg/_CURSOR.md"

echo "PASS: link cleans known nested mirror symlinks"
