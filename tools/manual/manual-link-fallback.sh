#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"

usage() {
  cat <<'USAGE'
Usage: ./tools/manual/manual-link-fallback.sh [options]

Options:
  --dotfiles-root <path>       Override dotfiles root (default: script-detected repo root).
  --cursor-config-root <path>  Override CURSOR_CONFIG_ROOT (default: <dotfiles-root>/cursor).
  -h, --help                   Show this help text.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dotfiles-root)
      shift
      [[ $# -gt 0 ]] || { echo "manual-link-fallback: --dotfiles-root requires a value." >&2; exit 1; }
      DOTFILES_ROOT="$1"
      ;;
    --cursor-config-root)
      shift
      [[ $# -gt 0 ]] || { echo "manual-link-fallback: --cursor-config-root requires a value." >&2; exit 1; }
      CURSOR_CONFIG_ROOT="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "manual-link-fallback: unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

# shellcheck source=tools/lib/cursor-layout.sh
source "$DOTFILES_ROOT/tools/lib/cursor-layout.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$DOTFILES_ROOT/tools/lib/link-targets.sh"

link() {
  local src="$1"
  local dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "Backing up $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  echo "Linked $dest -> $src"
}

copy_cursor_runtime() {
  local src="$1"
  local dest="$2"
  local source_kind="$3"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  case "$source_kind" in
    dir)
      cp -R "$src" "$dest"
      ;;
    file)
      cp -p "$src" "$dest"
      ;;
    *)
      echo "manual-link-fallback: unknown Cursor runtime source kind: $source_kind" >&2
      exit 1
      ;;
  esac
}

cursor_strip_nested_mirrors "$CURSOR_CONFIG_ROOT"
cursor_assert_no_nested_mirrors "$CURSOR_CONFIG_ROOT" "manual-fallback" || exit 1

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  src="$DOTFILES_ROOT/$source_rel"
  dest="$HOME/$dest_rel"
  if ! link_source_exists "$src" "$source_kind"; then
    if [[ "$required" == "required" ]]; then
      echo "manual-link-fallback: missing required source: $src" >&2
      exit 1
    fi
    continue
  fi
  link "$src" "$dest"
done < <(dotfiles_home_link_specs)

if [[ -L "$HOME/.cursor/core" ]]; then
  rm -f "$HOME/.cursor/core"
fi

if [[ -d "$DOTFILES_ROOT/config" ]]; then
  for f in "$DOTFILES_ROOT/config"/*; do
    [[ -e "$f" ]] || continue
    link "$f" "$HOME/.config/$(basename "$f")"
  done
fi

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  src="$CURSOR_CONFIG_ROOT/$source_rel"
  dest="$HOME/$dest_rel"
  if ! link_source_exists "$src" "$source_kind"; then
    continue
  fi
  copy_cursor_runtime "$src" "$dest" "$source_kind"
done < <(cursor_runtime_link_specs)

CURSOR_USER_DIR="$(cursor_user_dir_for_home "$HOME" "$OSTYPE" "${XDG_CONFIG_HOME:-}")"
while IFS='|' read -r source_rel dest_name source_kind required; do
  [[ -n "$source_rel" ]] || continue
  src="$CURSOR_CONFIG_ROOT/$source_rel"
  dest="$CURSOR_USER_DIR/$dest_name"
  if ! link_source_exists "$src" "$source_kind"; then
    continue
  fi
  link "$src" "$dest"
done < <(cursor_user_settings_link_specs)

cursor_strip_nested_mirrors "$CURSOR_CONFIG_ROOT"
cursor_assert_no_nested_mirrors "$CURSOR_CONFIG_ROOT" "manual-fallback" || exit 1

echo "manual-link-fallback: done. Reload your shell with: source ~/.zshrc"
