#!/usr/bin/env bash
# Clear Cursor chat and composer history on macOS. Preserves User settings (settings.json,
# keybindings, snippets). Deletes agent transcripts under ~/.cursor/projects and ~/.cursor/chats
# when present, and prunes matching keys from global and workspace state.vscdb files.
#
# Quit Cursor completely (Cmd+Q) before running. Requires sqlite3 (macOS includes it).
#
# Usage: ./tools/cursor-cli/clear-chat.sh
set -euo pipefail

die() {
  echo "clear-chat: $*" >&2
  exit 1
}

cursor_is_running() {
  pgrep -xq Cursor 2>/dev/null \
    || pgrep -f "/Applications/Cursor.app/Contents/MacOS/Cursor" >/dev/null 2>&1
}

sql_composer_chat_pane_keys() {
  printf '%s\n' "DELETE FROM ItemTable WHERE key LIKE 'workbench.panel.composerChatViewPane.%';"
}

clean_global_db() {
  local db=$1
  {
    sql_composer_chat_pane_keys
    cat <<'SQL'
DELETE FROM ItemTable WHERE key IN (
  'backgroundComposer.windowBcMapping',
  'composer.composerHeaders',
  'composer.planRedirects',
  'composer.planRegistry',
  'conversationClassificationScoredConversations',
  'workbench.backgroundComposer.persistentData'
);
SQL
  } | sqlite3 "$db"
}

clean_workspace_db() {
  local db=$1
  {
    sql_composer_chat_pane_keys
    cat <<'SQL'
DELETE FROM ItemTable WHERE key IN (
  'aiService.generations',
  'aiService.prompts',
  'composer.composerData',
  'workbench.backgroundComposer.workspacePersistentData'
);
SQL
  } | sqlite3 "$db"
}

if [[ "$(uname -s)" != Darwin ]]; then
  die "this script targets macOS (Cursor support paths differ elsewhere)."
fi

if cursor_is_running; then
  die "Cursor is still running. Quit Cursor (Cmd+Q), then run this script again."
fi

command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 not found (required to clean state.vscdb)."

CURSOR_USER="${HOME}/Library/Application Support/Cursor/User"
GLOBAL_DB="${CURSOR_USER}/globalStorage/state.vscdb"
PROJECTS="${HOME}/.cursor/projects"

echo "Removing agent transcript files under ${PROJECTS} ..."
find "$PROJECTS" -path '*/agent-transcripts/*' -type f -delete 2>/dev/null || true
find "$PROJECTS" -type d -name agent-transcripts -empty -delete 2>/dev/null || true

if [[ -d "${HOME}/.cursor/chats" ]]; then
  rm -rf "${HOME}/.cursor/chats"
  echo "Removed ~/.cursor/chats"
fi

if [[ -f "$GLOBAL_DB" ]]; then
  echo "Cleaning global chat keys in state.vscdb ..."
  clean_global_db "$GLOBAL_DB"
fi

while IFS= read -r -d '' db; do
  echo "Cleaning workspace DB: $db"
  clean_workspace_db "$db"
done < <(find "${CURSOR_USER}/workspaceStorage" -name state.vscdb -print0 2>/dev/null || true)

echo "Done. Open Cursor again; chat history should be empty. Settings were not modified."
