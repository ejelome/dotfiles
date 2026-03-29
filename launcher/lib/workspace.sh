# Workspace list validation and Swift literal generation for the picker template.

function validate_workspace_config() {
  (( ${#WORKSPACE_ENTRIES[@]} > 0 )) || die "No workspace entries configured."

  local entry label path
  for entry in "${WORKSPACE_ENTRIES[@]}"; do
    label="${entry%%|*}"
    path="${entry#*|}"
    [[ -n "${label}" ]] || die "Workspace label is empty in entry: ${entry}"
    [[ "${path}" != "${entry}" ]] || die "Workspace entry missing separator '|': ${entry}"
    [[ -n "${path}" ]] || die "Workspace path is empty for label: ${label}"
  done
}

function escape_swift() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  echo "${s}"
}

function swift_array() {
  local -a values=("$@")
  local -a escaped=()
  local value=""

  for value in "${values[@]}"; do
    escaped+=("\"$(escape_swift "${value}")\"")
  done

  local IFS=", "
  echo "${escaped[*]}"
}

function picker_items_swift_literal() {
  local entry="" label=""
  local -a labels=()

  for entry in "${WORKSPACE_ENTRIES[@]}"; do
    label="${entry%%|*}"
    labels+=("${label}")
  done

  swift_array "${labels[@]}"
}

function workspace_paths_swift_literal() {
  local entry="" path=""
  local -a paths=()

  for entry in "${WORKSPACE_ENTRIES[@]}"; do
    path="${entry#*|}"
    paths+=("${path}")
  done

  swift_array "${paths[@]}"
}

function default_selection_index() {
  if [[ -z "${DEFAULT_WORKSPACE_LABEL}" ]]; then
    echo 0
    return 0
  fi

  local entry="" label="" index=0
  for entry in "${WORKSPACE_ENTRIES[@]}"; do
    label="${entry%%|*}"
    if [[ "${label}" == "${DEFAULT_WORKSPACE_LABEL}" ]]; then
      echo "${index}"
      return 0
    fi
    # Not ((index++)): with set -e, post-increment from 0 exits the script (status 1).
    index=$((index + 1))
  done

  die "Default workspace label not found in WORKSPACE_ENTRIES: ${DEFAULT_WORKSPACE_LABEL}"
}
