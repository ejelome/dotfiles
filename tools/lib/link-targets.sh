#!/usr/bin/env bash

# Canonical symlink target maps for link.sh, smoke-check.sh, and tests.

dotfiles_home_link_specs() {
  cat <<'EOF'
zshrc|.zshrc|file|required
gitconfig|.gitconfig|file|required
EOF
}

cursor_user_settings_link_specs() {
  cat <<'EOF'
settings.json|settings.json|file|optional
keybindings.json|keybindings.json|file|optional
EOF
}

cursor_user_dir_for_home() {
  local home="$1"
  local ostype="${2:-$OSTYPE}"
  local xdg_config_home
  if [[ $# -ge 3 ]]; then
    xdg_config_home="$3"
  else
    xdg_config_home="${XDG_CONFIG_HOME:-}"
  fi

  if [[ "$ostype" == darwin* ]]; then
    printf '%s/Library/Application Support/Cursor/User\n' "$home"
    return 0
  fi

  if [[ -n "$xdg_config_home" ]]; then
    printf '%s/Cursor/User\n' "$xdg_config_home"
    return 0
  fi

  printf '%s/.config/Cursor/User\n' "$home"
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
