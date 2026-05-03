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
mkdir -p "$home/.cursor/rules"

printf 'local zshrc\n' >"$home/.zshrc"
printf 'local gitconfig\n' >"$home/.gitconfig"
printf 'legacy rules dir\n' >"$home/.cursor/rules/local.txt"

HOME="$home" \
CURSOR_CONFIG_ROOT="$ROOT/cursor" \
SKIP_CURSOR_INSTALL=1 \
SKIP_CURSOR_LAUNCHER=1 \
INSTALL_ZSH_PLUGINS=0 \
"$ROOT/link.sh" >/dev/null

assert_exists "$home/.zshrc.bak"
assert_exists "$home/.gitconfig.bak"
assert_not_exists "$home/.cursor/rules.bak"

assert_symlink_points_to "$home/.zshrc" "$ROOT/zshrc"
assert_symlink_points_to "$home/.gitconfig" "$ROOT/gitconfig"
assert_copy_matches "$home/.cursor/rules" "$ROOT/cursor/rules"
assert_not_exists "$home/.cursor/rules/local.txt"

zshrc_bak="$(cat "$home/.zshrc.bak")"
gitconfig_bak="$(cat "$home/.gitconfig.bak")"
assert_contains "$zshrc_bak" "local zshrc"
assert_contains "$gitconfig_bak" "local gitconfig"

echo "PASS: link backups existing non-symlink targets"
