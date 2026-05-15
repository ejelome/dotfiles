#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"

home_specs="$(dotfiles_home_link_specs)"
assert_contains "$home_specs" "zshrc|.zshrc|file|required"
assert_contains "$home_specs" "gitconfig|.gitconfig|file|required"

settings_specs="$(cursor_user_settings_link_specs)"
assert_contains "$settings_specs" "settings.json|settings.json|file|optional"
assert_contains "$settings_specs" "keybindings.json|keybindings.json|file|optional"

darwin_user_dir="$(cursor_user_dir_for_home "/tmp/home" "darwin23" "")"
[[ "$darwin_user_dir" == "/tmp/home/Library/Application Support/Cursor/User" ]] || fail "unexpected macOS cursor user dir: $darwin_user_dir"

linux_xdg_user_dir="$(cursor_user_dir_for_home "/tmp/home" "linux-gnu" "/tmp/xdg")"
[[ "$linux_xdg_user_dir" == "/tmp/xdg/Cursor/User" ]] || fail "unexpected Linux XDG cursor user dir: $linux_xdg_user_dir"

linux_default_user_dir="$(cursor_user_dir_for_home "/tmp/home" "linux-gnu" "")"
[[ "$linux_default_user_dir" == "/tmp/home/.config/Cursor/User" ]] || fail "unexpected Linux default cursor user dir: $linux_default_user_dir"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

touch "$tmp/source-file"
mkdir -p "$tmp/source-dir"

link_source_exists "$tmp/source-file" file || fail "expected file source_kind to pass"
link_source_exists "$tmp/source-dir" dir || fail "expected dir source_kind to pass"

if link_source_exists "$tmp/missing" file; then
  fail "missing file should fail link_source_exists(file)"
fi
if link_source_exists "$tmp/missing" dir; then
  fail "missing dir should fail link_source_exists(dir)"
fi
if link_source_exists "$tmp/source-file" unknown; then
  fail "unknown source_kind should fail link_source_exists"
fi

echo "PASS: link-targets specs and helpers stay consistent"
