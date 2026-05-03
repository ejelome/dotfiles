#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
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
cfg="$tmp/cursor"
mkdir -p "$home/.cursor"
cp -R "$ROOT/cursor" "$cfg"
ln -s "$cfg/commands" "$cfg/commands/commands"
ln -s "$cfg/_core" "$home/.cursor/core"

HOME="$home" \
"$ROOT/tools/manual/manual-link-fallback.sh" \
  --dotfiles-root "$ROOT" \
  --cursor-config-root "$cfg" >/dev/null

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  assert_symlink_points_to "$home/$dest_rel" "$ROOT/$source_rel"
done < <(dotfiles_home_link_specs)

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  assert_copy_matches "$home/$dest_rel" "$cfg/$source_rel"
done < <(cursor_runtime_link_specs)

cursor_user_dir="$(cursor_user_dir_for_home "$home" "$OSTYPE" "${XDG_CONFIG_HOME:-}")"
while IFS='|' read -r source_rel dest_name source_kind required; do
  [[ -n "$source_rel" ]] || continue
  if link_source_exists "$cfg/$source_rel" "$source_kind"; then
    assert_symlink_points_to "$cursor_user_dir/$dest_name" "$cfg/$source_rel"
  fi
done < <(cursor_user_settings_link_specs)

assert_not_exists "$cfg/commands/commands"
assert_not_exists "$home/.cursor/core"

echo "PASS: manual-link-fallback links canonical targets and strips known nested mirrors"
