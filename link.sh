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

if [[ "$OSTYPE" == darwin* ]]; then
  LAUNCHER_SETUP_SCRIPT="$DOTFILES_ROOT/launcher/setup-cursor-workspace-launcher.sh"

  if [[ -x "$LAUNCHER_SETUP_SCRIPT" ]]; then
    if "$LAUNCHER_SETUP_SCRIPT"; then
      echo "Built Cursor launcher app via setup script."
    else
      echo "Warning: failed to build Cursor launcher app."
    fi
  elif [[ -f "$LAUNCHER_SETUP_SCRIPT" ]]; then
    if zsh "$LAUNCHER_SETUP_SCRIPT"; then
      echo "Built Cursor launcher app via setup script."
    else
      echo "Warning: failed to build Cursor launcher app."
    fi
  else
    echo "Skipping launcher setup: $LAUNCHER_SETUP_SCRIPT not found."
  fi
fi

echo "Done. Restart your shell or run: source ~/.zshrc"
