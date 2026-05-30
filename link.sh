#!/usr/bin/env bash
# Project this checkout's configuration files into the current user's home.
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"

dotfiles_home_link_specs() {
  cat <<'EOF'
zshrc|.zshrc|file|required
gitconfig|.gitconfig|file|required
EOF
}

link_source_exists() {
  local path="$1"
  local source_kind="$2"

  case "$source_kind" in
    file) [[ -f "$path" ]] ;;
    dir) [[ -d "$path" ]] ;;
    *) return 1 ;;
  esac
}

link() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "Backing up $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  echo "Linked $dest -> $src"
}

while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  src="$DOTFILES_ROOT/$source_rel"
  dest="$HOME/$dest_rel"
  if ! link_source_exists "$src" "$source_kind"; then
    if [[ "$required" == "required" ]]; then
      echo "link.sh: missing required source: $src" >&2
      exit 1
    fi
    continue
  fi
  link "$src" "$dest"
done < <(dotfiles_home_link_specs)

if [[ -d "$DOTFILES_ROOT/config" ]]; then
  for f in "$DOTFILES_ROOT/config"/*; do
    [[ -e "$f" ]] || continue
    link "$f" "$HOME/.config/$(basename "$f")"
  done
fi

echo "Done. Restart your shell or run: source ~/.zshrc"
