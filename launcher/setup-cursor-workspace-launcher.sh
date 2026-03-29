#!/bin/zsh

set -euo pipefail

readonly SCRIPT_DIR="${0:A:h}"

source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/workspace.sh"
source "${SCRIPT_DIR}/lib/build_app.sh"
source "${SCRIPT_DIR}/lib/dock.sh"

function parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      -h|--help)
        cat <<'USAGE'
Usage: setup-cursor-workspace-launcher.sh

The Dock tile for the launcher is refreshed on every run (stale entries are
removed first, then the current app path is appended).

Workspace list: copy workspace-launcher.local.sh.example to
workspace-launcher.local.sh and set WORKSPACE_ENTRIES.
USAGE
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

function main() {
  parse_args "$@"
  require_macos
  require_tools
  require_templates
  require_user_config
  validate_workspace_config
  clean_existing_app_bundle
  ensure_bundle_structure
  build_picker_binary
  write_launcher
  write_info_plist
  maybe_create_app_icon
  add_to_dock
  log_info "${APP_NAME}.app built successfully"
}

main "$@"
