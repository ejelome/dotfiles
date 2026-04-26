#!/usr/bin/env bash
# Full Cursor "factory reset" on macOS: backup, then remove local user data.
# Quit Cursor completely (Cmd+Q) before running.
#
# Usage:
#   ./tools/cursor-cli/factory-reset.sh         # show what would happen
#   ./tools/cursor-cli/factory-reset.sh --yes   # backup + delete (DESTRUCTIVE)

set -euo pipefail

CURSOR_APP="/Applications/Cursor.app/Contents/MacOS/Cursor"
APP_SUPPORT="${HOME}/Library/Application Support/Cursor"
DOT_CURSOR="${HOME}/.cursor"
BUNDLE_ID="com.todesktop.230313mzl4w4u92"
PREF_PLIST="${HOME}/Library/Preferences/${BUNDLE_ID}.plist"
CACHES=(
  "${HOME}/Library/Caches/${BUNDLE_ID}"
  "${HOME}/Library/Caches/${BUNDLE_ID}.ShipIt"
)

if pgrep -fq "$CURSOR_APP" 2>/dev/null; then
  echo "Cursor is still running. Quit it (Cmd+Q), then run this script again." >&2
  exit 1
fi

if [[ "${1:-}" != "--yes" ]]; then
  echo "Cursor factory reset (macOS)"
  echo
  echo "This will BACK UP then REMOVE:"
  echo "  - ${APP_SUPPORT}"
  echo "  - ${DOT_CURSOR}"
  echo "  - ${PREF_PLIST} (if present)"
  for c in "${CACHES[@]}"; do echo "  - ${c} (if present)"; done
  echo
  echo "You will lose: settings, extensions, UI state, chat/workspace cache, and local Cursor data."
  echo "If you use ~/.cursor symlinks (e.g. to dotfiles), those links are removed; your repo files are not deleted."
  echo
  echo "To proceed:  $0 --yes"
  exit 0
fi

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${HOME}/Desktop/cursor-factory-reset-backup-${TS}"
mkdir -p "$BACKUP_DIR"

echo "Creating backup at: $BACKUP_DIR"

if [[ -d "$APP_SUPPORT" ]]; then
  ditto "$APP_SUPPORT" "${BACKUP_DIR}/Application Support/Cursor"
fi
if [[ -d "$DOT_CURSOR" ]] || [[ -L "$DOT_CURSOR" ]]; then
  ditto "$DOT_CURSOR" "${BACKUP_DIR}/dot-cursor"
fi
if [[ -f "$PREF_PLIST" ]]; then
  ditto "$PREF_PLIST" "${BACKUP_DIR}/"
fi
for c in "${CACHES[@]}"; do
  if [[ -d "$c" ]]; then
    ditto "$c" "${BACKUP_DIR}/Caches/$(basename "$c")"
  fi
done

echo "Backup finished. Removing Cursor data..."

rm -rf "$APP_SUPPORT"
rm -rf "$DOT_CURSOR"
rm -f "$PREF_PLIST"
for c in "${CACHES[@]}"; do
  rm -rf "$c"
done

# Optional: window restore state (if present)
SAVED_STATE="${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState"
if [[ -d "$SAVED_STATE" ]]; then
  rm -rf "$SAVED_STATE"
fi

echo "Done. Cursor has been reset. Open Cursor to go through first-run setup again."
echo "Backup copy: $BACKUP_DIR"
