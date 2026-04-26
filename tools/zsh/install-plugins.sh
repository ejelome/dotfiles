#!/usr/bin/env bash
# Install or update required zsh plugins used by zshrc.
set -euo pipefail

PLUGINS_DIR="${ZSH_PLUGINS_DIR:-$HOME/.zsh/plugins}"

if ! command -v git >/dev/null 2>&1; then
  echo "install-zsh-plugins: git is required" >&2
  exit 1
fi

mkdir -p "$PLUGINS_DIR"

install_or_update_repo() {
  local name="$1" url="$2"
  local dir="$PLUGINS_DIR/$name"

  if [[ -d "$dir/.git" ]]; then
    echo "install-zsh-plugins: update $name"
    git -C "$dir" pull --ff-only
    return 0
  fi

  if [[ -e "$dir" ]]; then
    echo "install-zsh-plugins: skip $name (exists but is not a git repo: $dir)" >&2
    return 0
  fi

  echo "install-zsh-plugins: clone $name"
  git clone --depth 1 "$url" "$dir"
}

install_or_update_repo "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_or_update_repo "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

echo "install-zsh-plugins: done"
