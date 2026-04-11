#!/usr/bin/env bash
# Symlink dotfiles from this repo into $HOME. Backs up existing files.
set -e
DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Cursor user config source: directory containing rules/, commands/, optional core/, extensions.txt.
# Canonical install path is always ~/.cursor/... . Override to point at any checkout (not necessarily this repo).
# Each ~/.cursor target is linked only when the corresponding source path exists under CURSOR_CONFIG_ROOT.
# skills-cursor/ is managed by Cursor itself and is not tracked in this repo.
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"

# Drop self-referential mirrors under CURSOR_CONFIG_ROOT (recursive symlink hazard). Cursor
# sometimes recreates these when the open workspace is this repo and ~/.cursor points here.
strip_cursor_nested_mirrors() {
  local r="$CURSOR_CONFIG_ROOT"
  rm_self_symlink() {
    local nest="$1" want="$2"
    [[ -L "$nest" ]] || return 0
    [[ "$(readlink "$nest")" == "$want" ]] || return 0
    rm -f "$nest"
  }
  rm_self_symlink "$r/commands/commands" "$r/commands"
  rm_self_symlink "$r/rules/rules" "$r/rules"
  rm_self_symlink "$r/core/core" "$r/core"
}

assert_cursor_no_nested_mirrors() {
  local r="$CURSOR_CONFIG_ROOT" bad
  for bad in "$r/commands/commands" "$r/rules/rules" "$r/core/core"; do
    if [[ -e "$bad" ]]; then
      echo "link.sh: remove $bad (nested mirror or unknown layout under CURSOR_CONFIG_ROOT)." >&2
      exit 1
    fi
  done
}

strip_cursor_nested_mirrors
assert_cursor_no_nested_mirrors

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

if [[ -d "$CURSOR_CONFIG_ROOT/rules" ]]; then
  link "$CURSOR_CONFIG_ROOT/rules" "$HOME/.cursor/rules"
fi

if [[ -d "$CURSOR_CONFIG_ROOT/commands" ]]; then
  link "$CURSOR_CONFIG_ROOT/commands" "$HOME/.cursor/commands"
fi

if [[ -d "$CURSOR_CONFIG_ROOT/core" ]]; then
  link "$CURSOR_CONFIG_ROOT/core" "$HOME/.cursor/core"
fi

if [[ -f "$CURSOR_CONFIG_ROOT/extensions.txt" ]]; then
  link "$CURSOR_CONFIG_ROOT/extensions.txt" "$HOME/.cursor/extensions.txt"
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

# Sync Cursor extensions from ~/.cursor/extensions.txt (after link) when the CLI exists.
# Destructive helpers (e.g. clear-chat) stay manual — never run them here.
INSTALL_EXT_SCRIPT="$DOTFILES_ROOT/tools/cursor-cli/install-extensions.sh"
if [[ "${SKIP_CURSOR_EXTENSIONS:-}" != 1 ]] && [[ -f "$HOME/.cursor/extensions.txt" ]] && [[ -f "$INSTALL_EXT_SCRIPT" ]]; then
  if command -v cursor >/dev/null 2>&1; then
    echo "link.sh: syncing Cursor extensions from manifest (SKIP_CURSOR_EXTENSIONS=1 to skip)."
    if ! bash "$INSTALL_EXT_SCRIPT"; then
      echo "link.sh: warning: install-extensions.sh failed; re-run from repo: ./tools/cursor-cli/install-extensions.sh (or use PATH after zshrc: install-extensions.sh)" >&2
    fi
  fi
fi

strip_cursor_nested_mirrors
assert_cursor_no_nested_mirrors

echo "Done. Restart your shell or run: source ~/.zshrc"
