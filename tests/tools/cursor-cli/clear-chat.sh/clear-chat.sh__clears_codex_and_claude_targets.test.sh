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
mkdir -p "$home/.codex" "$home/.claude"

mkdir -p "$home/.codex/sessions/2026/04"
mkdir -p "$home/.codex/archived_sessions"
printf 'history\n' > "$home/.codex/history.jsonl"
printf 'index\n' > "$home/.codex/session_index.jsonl"
printf 'sqlite\n' > "$home/.codex/state_5.sqlite"
printf 'sqlite\n' > "$home/.codex/state_5.sqlite-shm"
printf 'sqlite\n' > "$home/.codex/state_5.sqlite-wal"
printf 'sqlite\n' > "$home/.codex/logs_2.sqlite"
printf 'sqlite\n' > "$home/.codex/logs_2.sqlite-shm"
printf 'sqlite\n' > "$home/.codex/logs_2.sqlite-wal"
printf 'keep\n' > "$home/.codex/config.toml"

mkdir -p "$home/.claude/sessions"
mkdir -p "$home/.claude/projects/proj"
mkdir -p "$home/.claude/session-env"
mkdir -p "$home/.claude/paste-cache"
printf 'history\n' > "$home/.claude/history.jsonl"
printf 'keep\n' > "$home/.claude/settings.json"

output="$({
  HOME="$home" \
  "$ROOT/tools/cursor-cli/clear-chat.sh" --codex --claude
} 2>&1)"

assert_not_exists "$home/.codex/sessions"
assert_not_exists "$home/.codex/archived_sessions"
assert_not_exists "$home/.codex/history.jsonl"
assert_not_exists "$home/.codex/session_index.jsonl"
assert_not_exists "$home/.codex/state_5.sqlite"
assert_not_exists "$home/.codex/state_5.sqlite-shm"
assert_not_exists "$home/.codex/state_5.sqlite-wal"
assert_not_exists "$home/.codex/logs_2.sqlite"
assert_not_exists "$home/.codex/logs_2.sqlite-shm"
assert_not_exists "$home/.codex/logs_2.sqlite-wal"
assert_exists "$home/.codex/config.toml"

assert_not_exists "$home/.claude/sessions"
assert_not_exists "$home/.claude/projects"
assert_not_exists "$home/.claude/session-env"
assert_not_exists "$home/.claude/paste-cache"
assert_not_exists "$home/.claude/history.jsonl"
assert_exists "$home/.claude/settings.json"

assert_contains "$output" "clear-chat: done (targets: codex claude)."

echo "PASS: clear-chat clears codex and claude targets"
