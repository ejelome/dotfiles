#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

home="$tmp/home"
mkdir -p "$home"

run_link() {
  HOME="$home" \
  SKIP_CURSOR_INSTALL=1 \
  SKIP_CURSOR_LAUNCHER=1 \
  INSTALL_ZSH_PLUGINS=0 \
  "$ROOT/link.sh" >/dev/null
}

note "first run"
run_link

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  assert_symlink_points_to "$home/$dest_rel" "$ROOT/$source_rel"
done < <(dotfiles_home_link_specs)

cursor_user_dir="$(cursor_user_dir_for_home "$home" "$OSTYPE" "${XDG_CONFIG_HOME:-}")"
while IFS='|' read -r source_rel dest_name source_kind required; do
  [[ -n "$source_rel" ]] || continue
  if link_source_exists "$ROOT/cursor/$source_rel" "$source_kind"; then
    assert_symlink_points_to "$cursor_user_dir/$dest_name" "$ROOT/cursor/$source_rel"
  fi
done < <(cursor_user_settings_link_specs)

note "second run (idempotency)"
run_link

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  assert_symlink_points_to "$home/$dest_rel" "$ROOT/$source_rel"
done < <(dotfiles_home_link_specs)

assert_not_exists "$home/.zshrc.bak"
assert_not_exists "$home/.gitconfig.bak"

echo "PASS: link home symlinks, Cursor User settings, and idempotency"
