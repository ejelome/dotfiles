# App bundle layout, Swift picker compile, launcher script, Info.plist, optional icon.

function clean_existing_app_bundle() {
  if [[ -d "${APP_PATH}" ]]; then
    rm -rf "${APP_PATH}"
    log_info "Removed existing app bundle at ${APP_PATH}"
  fi
  if [[ -f "${DEBUG_LOG_PATH}" ]]; then
    rm -f "${DEBUG_LOG_PATH}"
    log_info "Cleared old debug log at ${DEBUG_LOG_PATH}"
  fi
}

function ensure_bundle_structure() {
  mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/Resources"
}

function build_picker_binary() {
  local swift_tmp_base swift_src picker_tmp
  local picker_items workspace_paths default_index

  picker_items="$(picker_items_swift_literal)"
  workspace_paths="$(workspace_paths_swift_literal)"
  default_index="$(default_selection_index)"

  swift_tmp_base="$(mktemp -t cursor_launcher_picker)"
  swift_src="${swift_tmp_base}.swift"
  picker_tmp="${swift_tmp_base}.picker"
  mv "${swift_tmp_base}" "${swift_src}"

  {
    python3 - "${PICKER_TEMPLATE_PATH}" "${swift_src}" "${picker_items}" "${workspace_paths}" "${default_index}" <<'PY'
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1]).expanduser()
output_path = pathlib.Path(sys.argv[2])
picker_items = sys.argv[3]
workspace_paths = sys.argv[4]
default_index = sys.argv[5]

template = template_path.read_text(encoding="utf-8")
rendered = (
    template
    .replace("__PICKER_ITEMS__", picker_items)
    .replace("__WORKSPACE_PATHS__", workspace_paths)
    .replace("__DEFAULT_SELECTION_INDEX__", default_index)
)
output_path.write_text(rendered, encoding="utf-8")
PY

    log_info "Compiling Swift picker..."
    swiftc "${swift_src}" -o "${picker_tmp}"
    chmod +x "${picker_tmp}"
    mv "${picker_tmp}" "${PICKER_BIN_PATH}"
    log_info "Swift picker compiled"
  } always {
    [[ -n "${swift_src:-}" && -f "${swift_src}" ]] && rm -f "${swift_src}"
    [[ -n "${picker_tmp:-}" && -f "${picker_tmp}" ]] && rm -f "${picker_tmp}"
  }
}

function write_launcher() {
  local launcher_tmp
  launcher_tmp="$(mktemp -t cursor_launcher_exec)"
  cp "${LAUNCHER_TEMPLATE_PATH}" "${launcher_tmp}"

  chmod +x "${launcher_tmp}"
  mv "${launcher_tmp}" "${LAUNCHER_PATH}"
}

function write_info_plist() {
  local plist_tmp
  plist_tmp="$(mktemp -t cursor_launcher_info_plist)"
  cat > "${plist_tmp}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.local.${APP_NAME}</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST
  mv "${plist_tmp}" "${APP_PATH}/Contents/Info.plist"
}

function detect_icon_path() {
  local candidate=""
  for candidate in "${ICON_CANDIDATE_PATHS[@]}"; do
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

function maybe_create_app_icon() {
  local tool=""
  for tool in "${OPTIONAL_ICON_TOOLS[@]}"; do
    if ! has_tool "${tool}"; then
      log_warn "Optional icon tool missing (${tool}); skipping icon generation"
      return 0
    fi
  done

  local icon_path=""
  if ! icon_path="$(detect_icon_path)"; then
    log_warn "Icon not found; tried: ${ICON_CANDIDATE_PATHS[*]}"
    return 0
  fi

  local iconset_root iconset_dir
  iconset_root="$(mktemp -d /tmp/cursor_launcher_iconset_XXXXXX)"
  iconset_dir="${iconset_root}/AppIcon.iconset"

  {
    mkdir -p "${iconset_dir}"

    local size=0
    for size in 16 32 64 128 256 512; do
      sips -z "${size}" "${size}" "${icon_path}" --out "${iconset_dir}/icon_${size}x${size}.png" >/dev/null 2>&1
      sips -z "$((size * 2))" "$((size * 2))" "${icon_path}" --out "${iconset_dir}/icon_${size}x${size}@2x.png" >/dev/null 2>&1
    done

    iconutil -c icns "${iconset_dir}" -o "${APP_PATH}/Contents/Resources/AppIcon.icns"
    log_info "Icon generated"
  } always {
    [[ -n "${iconset_root:-}" && -d "${iconset_root}" ]] && rm -rf "${iconset_root}"
  }
}
