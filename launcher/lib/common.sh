# Shared logging, errors, and environment checks.

function log_info() {
  echo "[info] $*"
}

function log_warn() {
  echo "[warn] $*" >&2
}

function die() {
  echo "[error] $*" >&2
  exit 1
}

function has_tool() {
  command -v "$1" >/dev/null 2>&1
}

function require_tools() {
  local tool=""
  for tool in "${REQUIRED_TOOLS[@]}"; do
    has_tool "${tool}" || die "Missing required tool: ${tool}"
  done
}

function require_macos() {
  [[ "${OSTYPE}" == darwin* ]] || die "This script is macOS-only."
}

function require_templates() {
  [[ -f "${PICKER_TEMPLATE_PATH}" ]] || die "Missing picker template: ${PICKER_TEMPLATE_PATH}"
  [[ -f "${LAUNCHER_TEMPLATE_PATH}" ]] || die "Missing launcher template: ${LAUNCHER_TEMPLATE_PATH}"
}

function require_user_config() {
  [[ -f "${LAUNCHER_USER_CONFIG}" ]] || die "Missing ${LAUNCHER_USER_CONFIG}. Copy workspace-launcher.local.sh.example to workspace-launcher.local.sh and set WORKSPACE_ENTRIES."
}
