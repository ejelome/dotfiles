# Dock plist cleanup then append launcher tile.

function add_to_dock() {
  python3 "${SCRIPT_DIR}/lib/dock_update.py" "${APP_PATH}"

  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${APP_PATH}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  killall Dock
  log_info "Dock updated (launcher tile synced for ${APP_NAME})"
}
