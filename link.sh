#!/usr/bin/env bash
# Install dotfiles from this repo into $HOME. Backs up existing home links.
set -e
DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=tools/lib/cursor-layout.sh
source "$DOTFILES_ROOT/tools/lib/cursor-layout.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$DOTFILES_ROOT/tools/lib/link-targets.sh"

print_usage() {
  cat <<'USAGE'
Usage: ./link.sh [options]

Options:
  --cursor-config-root <path>       Use an alternate Cursor config root.
  --cursor-config-root=<path>
  (Also symlinks $CURSOR_CONFIG_ROOT/_settings/{settings,keybindings}.json into Cursor's User/ folder when present.)
  --skip-cursor-install             Skip auto-installing Cursor on macOS.
  --skip-cursor-install=<bool>
  --skip-cursor-launcher            Skip workspace launcher build on macOS.
  --skip-cursor-launcher=<bool>
  --force-cursor-launcher           Rebuild launcher even when app exists.
  --force-cursor-launcher=<bool>
  --install-zsh-plugins             Install/update zsh plugins after linking.
  --install-zsh-plugins=<bool>
  -h, --help                        Show this help text.

Boolean values: 1/0, true/false, yes/no, on/off.
Environment variable equivalents are also supported:
  CURSOR_CONFIG_ROOT, SKIP_CURSOR_INSTALL, SKIP_CURSOR_LAUNCHER,
  FORCE_CURSOR_LAUNCHER, INSTALL_ZSH_PLUGINS
USAGE
}

normalize_bool() {
  local raw="${1:-}" normalized
  normalized="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$normalized" in
    1|true|yes|on) printf '%s\n' "1" ;;
    0|false|no|off) printf '%s\n' "0" ;;
    *) return 1 ;;
  esac
}

init_bool_from_env() {
  local var_name="$1" default_value="$2" raw normalized
  raw="${!var_name:-}"
  if [[ -z "$raw" ]]; then
    printf -v "$var_name" '%s' "$default_value"
    return 0
  fi
  if ! normalized="$(normalize_bool "$raw")"; then
    echo "link.sh: invalid boolean for ${var_name}: ${raw}" >&2
    echo "link.sh: use 1/0, true/false, yes/no, or on/off." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$normalized"
}

set_bool_option() {
  local var_name="$1" option_name="$2" raw="$3" normalized
  if ! normalized="$(normalize_bool "$raw")"; then
    echo "link.sh: invalid boolean for ${option_name}: ${raw}" >&2
    echo "link.sh: use 1/0, true/false, yes/no, or on/off." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$normalized"
}

# Cursor config source: directory containing _CURSOR.md, rules/, commands/, _functions/, _mdc/, _core/, _roles/, _tests/, _templates/, and _settings/.
# Canonical install path is always ~/.cursor/... . Override to point at any checkout (not necessarily this repo).
# Each ~/.cursor target is linked only when the corresponding source path exists under CURSOR_CONFIG_ROOT.
# skills-cursor/ is managed by Cursor itself and is not tracked in this repo.
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
init_bool_from_env "SKIP_CURSOR_INSTALL" "0"
init_bool_from_env "SKIP_CURSOR_LAUNCHER" "0"
init_bool_from_env "FORCE_CURSOR_LAUNCHER" "0"
init_bool_from_env "INSTALL_ZSH_PLUGINS" "0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cursor-config-root)
      shift
      [[ $# -gt 0 ]] || { echo "link.sh: --cursor-config-root requires a value." >&2; exit 1; }
      CURSOR_CONFIG_ROOT="$1"
      ;;
    --cursor-config-root=*)
      CURSOR_CONFIG_ROOT="${1#*=}"
      ;;
    --skip-cursor-install)
      SKIP_CURSOR_INSTALL="1"
      ;;
    --skip-cursor-install=*)
      set_bool_option "SKIP_CURSOR_INSTALL" "--skip-cursor-install" "${1#*=}"
      ;;
    --skip-cursor-launcher)
      SKIP_CURSOR_LAUNCHER="1"
      ;;
    --skip-cursor-launcher=*)
      set_bool_option "SKIP_CURSOR_LAUNCHER" "--skip-cursor-launcher" "${1#*=}"
      ;;
    --force-cursor-launcher)
      FORCE_CURSOR_LAUNCHER="1"
      ;;
    --force-cursor-launcher=*)
      set_bool_option "FORCE_CURSOR_LAUNCHER" "--force-cursor-launcher" "${1#*=}"
      ;;
    --install-zsh-plugins)
      INSTALL_ZSH_PLUGINS="1"
      ;;
    --install-zsh-plugins=*)
      set_bool_option "INSTALL_ZSH_PLUGINS" "--install-zsh-plugins" "${1#*=}"
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "link.sh: unknown option: $1" >&2
      print_usage
      exit 1
      ;;
  esac
  shift
done

# Ensure the Cursor CLI is discoverable for this shell session.
ensure_cursor_cli_on_path() {
  if command -v cursor >/dev/null 2>&1; then
    return 0
  fi

  local candidate
  for candidate in \
    "/Applications/Cursor.app/Contents/Resources/app/bin" \
    "$HOME/Applications/Cursor.app/Contents/Resources/app/bin"; do
    if [[ -x "$candidate/cursor" ]]; then
      export PATH="$candidate:$PATH"
      return 0
    fi
  done

  return 1
}

# Auto-install Cursor on macOS when missing.
# Set SKIP_CURSOR_INSTALL=1 or pass --skip-cursor-install to skip this step.
maybe_install_cursor() {
  if [[ "${SKIP_CURSOR_INSTALL}" == 1 ]]; then
    return 0
  fi

  if ensure_cursor_cli_on_path; then
    return 0
  fi

  if [[ "$OSTYPE" != darwin* ]]; then
    echo "link.sh: cursor CLI not found; skipping Cursor auto-install on non-macOS."
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo "link.sh: cursor CLI not found and Homebrew is unavailable; skipping Cursor auto-install." >&2
    return 0
  fi

  if brew list --cask cursor >/dev/null 2>&1; then
    echo "link.sh: Cursor cask already installed; checking CLI path."
  else
    echo "link.sh: installing Cursor via Homebrew cask (SKIP_CURSOR_INSTALL=1 to skip)."
    if ! brew install --cask cursor; then
      echo "link.sh: warning: failed to install Cursor via Homebrew cask." >&2
      return 0
    fi
  fi

  if ensure_cursor_cli_on_path; then
    echo "link.sh: cursor CLI is available for this run."
  else
    echo "link.sh: Cursor installed, but 'cursor' is still not on PATH. In Cursor, run: Shell Command: Install 'cursor' command in PATH." >&2
  fi
}

maybe_build_cursor_launcher() {
  if [[ "$OSTYPE" != darwin* ]]; then
    return 0
  fi

  if [[ "${SKIP_CURSOR_LAUNCHER}" == 1 ]]; then
    echo "link.sh: skipping launcher build (SKIP_CURSOR_LAUNCHER=1)."
    return 0
  fi

  local launcher_setup_script="$DOTFILES_ROOT/launcher/setup-cursor-workspace-launcher.sh"
  local launcher_user_config="$DOTFILES_ROOT/launcher/workspace-launcher.local.sh"
  local launcher_app_path="$HOME/Applications/CursorWorkspaceLauncher.app"

  if [[ ! -f "$launcher_setup_script" ]]; then
    echo "Skipping launcher setup: $launcher_setup_script not found."
    return 0
  fi

  if [[ ! -f "$launcher_user_config" ]]; then
    echo "link.sh: skipping launcher build (missing $launcher_user_config). Copy launcher/workspace-launcher.local.sh.example to enable."
    return 0
  fi

  if [[ -d "$launcher_app_path" && "${FORCE_CURSOR_LAUNCHER}" != 1 ]]; then
    echo "link.sh: launcher already exists; skipping rebuild (set FORCE_CURSOR_LAUNCHER=1 to rebuild)."
    return 0
  fi

  if [[ -x "$launcher_setup_script" ]]; then
    if "$launcher_setup_script"; then
      echo "Built Cursor launcher app via setup script."
    else
      echo "Warning: failed to build Cursor launcher app."
    fi
  else
    if zsh "$launcher_setup_script"; then
      echo "Built Cursor launcher app via setup script."
    else
      echo "Warning: failed to build Cursor launcher app."
    fi
  fi
}

maybe_install_zsh_plugins() {
  if [[ "${INSTALL_ZSH_PLUGINS}" != 1 ]]; then
    return 0
  fi

  local install_plugins_script="$DOTFILES_ROOT/tools/zsh/install-plugins.sh"
  if [[ ! -f "$install_plugins_script" ]]; then
    echo "link.sh: warning: missing zsh plugin helper ($install_plugins_script)." >&2
    return 0
  fi

  echo "link.sh: installing/updating zsh plugins (--install-zsh-plugins)."
  if ! bash "$install_plugins_script"; then
    echo "link.sh: warning: zsh plugin install failed; re-run from repo: ./tools/zsh/install-plugins.sh" >&2
  fi
}

cursor_strip_nested_mirrors "$CURSOR_CONFIG_ROOT"
cursor_assert_no_nested_mirrors "$CURSOR_CONFIG_ROOT" "link.sh" || exit 1

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

if [[ -L "$HOME/.cursor/core" ]]; then
  rm -f "$HOME/.cursor/core"
  echo "Removed legacy symlink $HOME/.cursor/core"
fi

if [[ -d "$DOTFILES_ROOT/config" ]]; then
  for f in "$DOTFILES_ROOT/config"/*; do
    [[ -e "$f" ]] || continue
    link "$f" "$HOME/.config/$(basename "$f")"
  done
fi

copy_cursor_runtime() {
  local src="$1" dest="$2" source_kind="$3"
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
      echo "link.sh: unknown Cursor runtime source kind: $source_kind" >&2
      exit 1
      ;;
  esac
  echo "Copied $dest <- $src"
}

# Runtime Cursor mirrors and Cursor User settings are both derived from
# tools/lib/link-targets.sh to avoid per-file path drift. Runtime ~/.cursor
# targets are copied so ~/.cursor is not a symlinked view of this checkout.
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

maybe_install_cursor

maybe_build_cursor_launcher

maybe_install_zsh_plugins

cursor_strip_nested_mirrors "$CURSOR_CONFIG_ROOT"
cursor_assert_no_nested_mirrors "$CURSOR_CONFIG_ROOT" "link.sh" || exit 1

echo "Done. Restart your shell or run: source ~/.zshrc"
