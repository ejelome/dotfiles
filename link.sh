#!/usr/bin/env bash
# Symlink dotfiles from this repo into $HOME. Backs up existing files.
set -e
DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"
HOME="${HOME:-$HOME}"

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

link "$DOTFILES_ROOT/zshrc" "$HOME/.zshrc"
link "$DOTFILES_ROOT/gitconfig" "$HOME/.gitconfig"

if [[ -d "$DOTFILES_ROOT/config" ]]; then
  for f in "$DOTFILES_ROOT/config"/*; do
    [[ -e "$f" ]] || continue
    link "$f" "$HOME/.config/$(basename "$f")"
  done
fi

if [[ -d "$DOTFILES_ROOT/cursor/rules" ]]; then
  link "$DOTFILES_ROOT/cursor/rules" "$HOME/.cursor/rules"
fi

echo "Done. Restart your shell or run: source ~/.zshrc"
