#!/usr/bin/env bash
# Clear local chat/session history for Cursor, Codex CLI, and Claude Code CLI.
# Defaults to Cursor-only cleanup when no product is specified.
#
# Usage:
#   ./tools/cursor-cli/clear-chat.sh [--cursor] [--codex] [--claude]
#   ./tools/cursor-cli/clear-chat.sh --all
#
# Targets:
# - --cursor: Cursor chat/composer state (macOS only; requires sqlite3)
# - --codex: Codex CLI session/history artifacts under ~/.codex
# - --claude: Claude Code session/history artifacts under ~/.claude
set -euo pipefail

die() {
  echo "clear-chat: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: ./tools/cursor-cli/clear-chat.sh [--cursor] [--codex] [--claude] [--all]

Options:
  --cursor   Clear Cursor chat/composer state (default when no flag is passed)
  --codex    Clear Codex CLI session/history state
  --claude   Clear Claude Code CLI session/history state
  --all      Clear all supported targets
  -h, --help Show this help text
USAGE
}

cursor_is_running() {
  pgrep -xq Cursor 2>/dev/null \
    || pgrep -f "/Applications/Cursor.app/Contents/MacOS/Cursor" >/dev/null 2>&1
}

sql_composer_chat_pane_keys() {
  printf '%s\n' "DELETE FROM ItemTable WHERE key LIKE 'workbench.panel.composerChatViewPane.%';"
}

clean_global_db() {
  local db="$1"
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
  local db="$1"
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

clean_cursor() {
  if [[ "$(uname -s)" != Darwin ]]; then
    die "--cursor target requires macOS."
  fi
  if cursor_is_running; then
    die "Cursor is still running. Quit Cursor (Cmd+Q), then run this script again."
  fi
  command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 not found (required for --cursor cleanup)."

  local cursor_user global_db projects
  cursor_user="${HOME}/Library/Application Support/Cursor/User"
  global_db="${cursor_user}/globalStorage/state.vscdb"
  projects="${HOME}/.cursor/projects"

  echo "clear-chat: [cursor] removing agent transcript files under ${projects} ..."
  find "$projects" -path '*/agent-transcripts/*' -type f -delete 2>/dev/null || true
  find "$projects" -type d -name agent-transcripts -empty -delete 2>/dev/null || true

  if [[ -d "${HOME}/.cursor/chats" ]]; then
    rm -rf "${HOME}/.cursor/chats"
    echo "clear-chat: [cursor] removed ~/.cursor/chats"
  fi

  if [[ -f "$global_db" ]]; then
    echo "clear-chat: [cursor] cleaning global chat keys in state.vscdb ..."
    clean_global_db "$global_db"
  fi

  while IFS= read -r -d '' db; do
    echo "clear-chat: [cursor] cleaning workspace DB: $db"
    clean_workspace_db "$db"
  done < <(find "${cursor_user}/workspaceStorage" -name state.vscdb -print0 2>/dev/null || true)
}

clean_codex() {
  local codex_home
  codex_home="${CODEX_HOME:-$HOME/.codex}"

  echo "clear-chat: [codex] clearing session/history artifacts under ${codex_home} ..."
  rm -rf "${codex_home}/sessions" "${codex_home}/archived_sessions"
  rm -f "${codex_home}/history.jsonl" "${codex_home}/session_index.jsonl"
  find "$codex_home" -maxdepth 1 -type f \
    \( -name 'state_*.sqlite' -o -name 'state_*.sqlite-shm' -o -name 'state_*.sqlite-wal' \
       -o -name 'logs_*.sqlite' -o -name 'logs_*.sqlite-shm' -o -name 'logs_*.sqlite-wal' \) \
    -delete 2>/dev/null || true
}

clean_claude() {
  local claude_home
  claude_home="${CLAUDE_HOME:-$HOME/.claude}"

  echo "clear-chat: [claude] clearing session/history artifacts under ${claude_home} ..."
  rm -rf "${claude_home}/sessions" "${claude_home}/projects" "${claude_home}/session-env" "${claude_home}/paste-cache"
  rm -f "${claude_home}/history.jsonl"
}

do_cursor=0
do_codex=0
do_claude=0
args_provided=0

while [[ $# -gt 0 ]]; do
  args_provided=1
  case "$1" in
    --cursor)
      do_cursor=1
      ;;
    --codex)
      do_codex=1
      ;;
    --claude)
      do_claude=1
      ;;
    --all)
      do_cursor=1
      do_codex=1
      do_claude=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1 (use --help)"
      ;;
  esac
  shift
done

# Default product selection.
if [[ $args_provided -eq 0 ]]; then
  do_cursor=1
fi

(( do_cursor || do_codex || do_claude )) || die "no targets selected (use --help)"

targets=()
if [[ $do_cursor -eq 1 ]]; then
  clean_cursor
  targets+=("cursor")
fi
if [[ $do_codex -eq 1 ]]; then
  clean_codex
  targets+=("codex")
fi
if [[ $do_claude -eq 1 ]]; then
  clean_claude
  targets+=("claude")
fi

echo "clear-chat: done (targets: ${targets[*]})."
