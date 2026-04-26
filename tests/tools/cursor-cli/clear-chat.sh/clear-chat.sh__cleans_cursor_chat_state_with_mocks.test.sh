#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

home="$tmp/home"
mockbin="$tmp/mockbin"
sqlite_log="$tmp/sqlite.log"
mkdir -p "$home" "$mockbin"

cat > "$mockbin/uname" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "Darwin"
SH

cat > "$mockbin/pgrep" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exit 1
SH

cat > "$mockbin/sqlite3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${MOCK_SQLITE_LOG:?}"
db="${1:-}"
echo "DB:${db}" >> "$MOCK_SQLITE_LOG"
cat >> "$MOCK_SQLITE_LOG"
SH

chmod +x "$mockbin/uname" "$mockbin/pgrep" "$mockbin/sqlite3"

mkdir -p "$home/.cursor/projects/ws/agent-transcripts"
printf 'chat\n' > "$home/.cursor/projects/ws/agent-transcripts/a.json"
mkdir -p "$home/.cursor/chats"
printf 'chat\n' > "$home/.cursor/chats/b.json"

cursor_user="$home/Library/Application Support/Cursor/User"
mkdir -p "$cursor_user/globalStorage"
: > "$cursor_user/globalStorage/state.vscdb"
mkdir -p "$cursor_user/workspaceStorage/ws-1"
: > "$cursor_user/workspaceStorage/ws-1/state.vscdb"

output="$({
  HOME="$home" \
  PATH="$mockbin:$PATH" \
  MOCK_SQLITE_LOG="$sqlite_log" \
  "$ROOT/tools/cursor-cli/clear-chat.sh"
} 2>&1)"

assert_not_exists "$home/.cursor/chats"
assert_not_exists "$home/.cursor/projects/ws/agent-transcripts"

sql_text="$(cat "$sqlite_log")"
assert_contains "$sql_text" "DB:$cursor_user/globalStorage/state.vscdb"
assert_contains "$sql_text" "DB:$cursor_user/workspaceStorage/ws-1/state.vscdb"
assert_contains "$sql_text" "composer.planRegistry"
assert_contains "$sql_text" "aiService.generations"
assert_contains "$output" "clear-chat: done (targets: cursor)."

echo "PASS: clear-chat cleans cursor chat state with mocks"
