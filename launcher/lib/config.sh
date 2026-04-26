# Sourced by setup-cursor-workspace-launcher.sh after SCRIPT_DIR is set.

readonly APP_NAME="CursorWorkspaceLauncher"
readonly APP_PATH="$HOME/Applications/${APP_NAME}.app"
readonly LAUNCHER_PATH="${APP_PATH}/Contents/MacOS/${APP_NAME}"
readonly PICKER_BIN_PATH="${APP_PATH}/Contents/MacOS/picker"
readonly DEBUG_LOG_PATH="$HOME/Library/Logs/${APP_NAME}.log"
readonly PICKER_TEMPLATE_PATH="${SCRIPT_DIR}/templates/cursor-workspace-picker.swift.tpl"
readonly LAUNCHER_TEMPLATE_PATH="${SCRIPT_DIR}/templates/cursor-workspace-launcher.zsh.tpl"
readonly LAUNCHER_USER_CONFIG="${SCRIPT_DIR}/workspace-launcher.local.sh"

# Override in workspace-launcher.local.sh (see workspace-launcher.local.sh.example).
typeset -ga WORKSPACE_ENTRIES=()
DEFAULT_WORKSPACE_LABEL=""

# PNG sources for optional icon generation; checked in order. Extend in local config via +=.
typeset -ga ICON_CANDIDATE_PATHS=(
  "${SCRIPT_DIR}/icons/icon-2d.png"
  "${SCRIPT_DIR}/icon-2d.png"
)

typeset -ra REQUIRED_TOOLS=(
  swiftc
  osascript
  defaults
  killall
  mktemp
  python3
)

typeset -ra OPTIONAL_ICON_TOOLS=(
  sips
  iconutil
)

if [[ -f "${LAUNCHER_USER_CONFIG}" ]]; then
  source "${LAUNCHER_USER_CONFIG}"
fi
