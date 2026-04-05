#!/bin/zsh
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/Applications/Cursor.app/Contents/Resources/app/bin:${HOME}/Applications/Cursor.app/Contents/Resources/app/bin:${HOME}/.local/bin:${HOME}/.cursor/bin:$PATH"
LOG_PATH="${HOME}/Library/Logs/CursorWorkspaceLauncher.log"
SCRIPT_DIR="${0:A:h}"
mkdir -p "${LOG_PATH:h}"

function log_debug() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${LOG_PATH}"
}

function normalize_target_path() {
  local raw_path="$1"
  local normalized="${raw_path}"
  normalized="${normalized//$'\r'/}"
  normalized="${normalized#"${normalized%%[![:space:]]*}"}"
  normalized="${normalized%"${normalized##*[![:space:]]}"}"
  printf '%s' "${normalized}"
}

RAW_TARGET_PATH=""
log_debug "launcher started; PATH=${PATH}"
function run_picker_once() {
  local picker_output_file picker_rc
  picker_output_file="$(mktemp -t cursor_workspace_picker_output)"
  picker_rc=0

  "${SCRIPT_DIR}/picker" "${picker_output_file}" 2>>"${LOG_PATH}" || picker_rc=$?
  if (( picker_rc != 0 )); then
    log_debug "picker execution failed (rc=${picker_rc})"
    rm -f "${picker_output_file}"
    return "${picker_rc}"
  fi

  RAW_TARGET_PATH="$(<"${picker_output_file}")"
  rm -f "${picker_output_file}"
  return 0
}

if ! run_picker_once; then
  osascript -e 'display alert "Workspace picker failed to run."'
  exit 1
fi
log_debug "picker raw output: ${RAW_TARGET_PATH}"
RAW_CHOICE="$(normalize_target_path "${RAW_TARGET_PATH}")"
log_debug "picker normalized choice: ${RAW_CHOICE}"

if [[ -z "${RAW_CHOICE}" ]]; then
  log_debug "empty path received from picker; treating as cancel"
  exit 0
fi

typeset -a TARGET_PATHS
TARGET_PATHS=()
OPEN_ACTION="open"

# New picker: line 1 = action, line 2 = paths joined by ASCII unit separator (U+001F).
# Legacy: single line "action<TAB>path" or plain path (open).
if [[ "${RAW_CHOICE}" == *$'\n'* ]]; then
  OPEN_ACTION="${RAW_CHOICE%%$'\n'*}"
  OPEN_ACTION="${OPEN_ACTION#"${OPEN_ACTION%%[![:space:]]*}"}"
  OPEN_ACTION="${OPEN_ACTION%"${OPEN_ACTION##*[![:space:]]}"}"
  pathline="${RAW_CHOICE#*$'\n'}"
  pathline="${pathline//$'\r'/}"
  pathline="${pathline#"${pathline%%[![:space:]]*}"}"
  pathline="${pathline%"${pathline##*[![:space:]]}"}"
  sep=$'\x1f'
  TARGET_PATHS=("${(@ps/$sep/)pathline}")
elif [[ "${RAW_CHOICE}" == *$'\t'* ]]; then
  OPEN_ACTION="${RAW_CHOICE%%$'\t'*}"
  OPEN_ACTION="${OPEN_ACTION#"${OPEN_ACTION%%[![:space:]]*}"}"
  OPEN_ACTION="${OPEN_ACTION%"${OPEN_ACTION##*[![:space:]]}"}"
  TARGET_PATHS=("${RAW_CHOICE#*$'\t'}")
else
  TARGET_PATHS=("${RAW_CHOICE}")
fi

if [[ "${OPEN_ACTION}" != "append" ]]; then
  OPEN_ACTION="open"
fi

# Drop empty segments from split
typeset -a cleaned
cleaned=()
for p in "${TARGET_PATHS[@]}"; do
  [[ -n "${p}" ]] || continue
  cleaned+=("${p}")
done
TARGET_PATHS=("${cleaned[@]}")

if (( ${#TARGET_PATHS[@]} == 0 )); then
  log_debug "empty path list after parse"
  exit 0
fi

log_debug "parsed action=${OPEN_ACTION}, path count=${#TARGET_PATHS[@]}"

for p in "${TARGET_PATHS[@]}"; do
  if [[ ! -e "${p}" ]]; then
    log_debug "workspace path missing: ${p}"
    osascript -e "display alert \"Workspace not found: ${p}\""
    exit 1
  fi
done

function open_workspace_with_cursor() {
  # Do not name this `path`: in zsh, `path` is tied to PATH and would clobber it.
  local workspace_path="$1"
  local open_action="$2"
  local cursor_cmd=""
  local output=""
  local rc=0
  local -a args=()

  cursor_cmd="$(command -v cursor || true)"
  log_debug "resolved cursor command: ${cursor_cmd}"

  if ! command -v cursor >/dev/null 2>&1; then
    log_debug "cursor CLI not found in PATH: ${PATH}"
    osascript -e 'display alert "cursor command not found in PATH. Install Cursor CLI and retry."'
    return 1
  fi

  if [[ "${open_action}" == "append" ]]; then
    args=(-a "${workspace_path}")
  else
    args=("${workspace_path}")
  fi

  log_debug "running: ${cursor_cmd} ${args[*]}"
  output="$("${cursor_cmd}" "${args[@]}" 2>&1)" || rc=$?
  if (( rc == 0 )); then
    log_debug "workspace opened via cursor CLI: ${workspace_path}"
    return 0
  fi

  log_debug "cursor command failed (code ${rc}): ${output}"
  osascript -e "display alert \"cursor failed (${rc}): ${output}\""
  return 1
}

idx=0
path_count="${#TARGET_PATHS[@]}"

if [[ "${OPEN_ACTION}" == "open" ]]; then
  for p in "${TARGET_PATHS[@]}"; do
    idx=$((idx + 1))
    if (( idx == 1 )); then
      if ! open_workspace_with_cursor "${p}" "open"; then
        exit 1
      fi
    else
      if ! open_workspace_with_cursor "${p}" "append"; then
        exit 1
      fi
    fi
  done
else
  for p in "${TARGET_PATHS[@]}"; do
    if ! open_workspace_with_cursor "${p}" "append"; then
      exit 1
    fi
  done
fi

log_debug "workspace(s) opened successfully (${path_count} path(s))"
exit 0
