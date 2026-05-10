#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

die() {
  echo "check-agent-adapters: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1" text="$2"
  grep -Fq "$text" "$file" || die "${file#"$ROOT"/}: missing required text: $text"
}

assert_matches() {
  local file="$1" pattern="$2"
  grep -Eq "$pattern" "$file" || die "${file#"$ROOT"/}: missing required pattern: $pattern"
}

assert_not_contains() {
  local file="$1" text="$2"
  if grep -Fq "$text" "$file"; then
    die "${file#"$ROOT"/}: unexpected text: $text"
  fi
}

agents="$ROOT/AGENTS.md"
claude="$ROOT/CLAUDE.md"
cursor_source="$ROOT/cursor/_CURSOR.md"

assert_contains "$agents" "\`~/.cursor/_CURSOR.md\`"
assert_contains "$agents" "[REPOSITORY.md](REPOSITORY.md)"
assert_matches "$agents" "## Bootstrap chain"
assert_matches "$agents" "Codex:.*AGENTS\\.md.*~/.cursor/_CURSOR\\.md"
assert_matches "$agents" "GPT:.*AGENTS\\.md.*~/.cursor/_CURSOR\\.md"
assert_matches "$agents" "Claude:.*CLAUDE\\.md.*AGENTS\\.md.*~/.cursor/_CURSOR\\.md"

assert_contains "$claude" "[AGENTS.md](AGENTS.md)"
assert_matches "$claude" "routing-only"
assert_not_contains "$claude" "## Behavior"

assert_contains "$cursor_source" "[AGENTS.md](../AGENTS.md)"
assert_matches "$cursor_source" "REPOSITORY\.md.*#4-mutation-protocol-and-ownership"
assert_matches "$cursor_source" "Bootstrap chain.*AGENTS\\.md"
assert_matches "$cursor_source" "routing-only adapter"
assert_not_contains "$cursor_source" "## Behavior"

echo "check-agent-adapters: OK"
