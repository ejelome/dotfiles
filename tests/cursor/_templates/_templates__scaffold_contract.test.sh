#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

claude="$ROOT/cursor/_templates/CLAUDE.md"
agents="$ROOT/cursor/_templates/AGENTS.md"
repo="$ROOT/cursor/_templates/REPOSITORY.md"
canonical_prefix='To invoke a global Cursor command, use the prose dispatch form `(<namespace> <command> <arg> ...)` as the invocation hint alongside the executable slash `/<namespace> <command>`.'
canonical_example='For example: `(collab join --role tw)` / `/collab join --role tw`.'

[[ -f "$claude" ]] || fail "missing template: cursor/_templates/CLAUDE.md"
[[ -f "$agents" ]] || fail "missing template: cursor/_templates/AGENTS.md"
[[ -f "$repo" ]] || fail "missing template: cursor/_templates/REPOSITORY.md"

grep -Fq "[AGENTS.md](AGENTS.md)" "$claude" || fail "CLAUDE template: missing AGENTS route"
grep -Eq "routing-only" "$claude" || fail "CLAUDE template: missing routing-only contract"
grep -Fq "[REPOSITORY.md](REPOSITORY.md#4-mutation-protocol-and-ownership)" "$claude" || fail "CLAUDE template: missing REPOSITORY contract link"

grep -Fq '~/.cursor/_CURSOR.md' "$agents" || fail "AGENTS template: missing global Cursor runtime reference"
grep -Fq "[REPOSITORY.md](REPOSITORY.md)" "$agents" || fail "AGENTS template: missing REPOSITORY entry point"
grep -Fq "Codex: \`AGENTS.md\` → \`~/.cursor/_CURSOR.md\`" "$agents" || fail "AGENTS template: missing Codex bootstrap chain"
grep -Fq "Claude: \`CLAUDE.md\` → \`AGENTS.md\` → \`~/.cursor/_CURSOR.md\`" "$agents" || fail "AGENTS template: missing Claude bootstrap chain"
grep -Fq "$canonical_prefix" "$agents" || fail "AGENTS template: missing canonical prefix routing sentence"
grep -Fq "$canonical_example" "$agents" || fail "AGENTS template: missing paired Lisp/slash example"
grep -Fq 'documentation-only and must not be copied into a terminal' "$agents" || fail "AGENTS template: missing prose dispatch shell warning"
grep -Fq 'opens a subshell' "$agents" || fail "AGENTS template: missing subshell caveat"
grep -Fq 'disambiguates `~/.cursor`-routed commands from agent-builtin slash surfaces' "$agents" || fail "AGENTS template: missing prose dispatch purpose"
grep -Fq 'does not need to match the runtime path (`~/.cursor/`) or the repo-source directory (`cursor/`)' "$agents" || fail "AGENTS template: missing prose/path decoupling invariant"
if grep -Fq 'cursor /' "$agents"; then
  fail "AGENTS template: old cursor slash prose dispatch must stay absent"
fi

grep -Eq "^# Repository Contract" "$repo" || fail "REPOSITORY template: missing title"
grep -Fq "## 4) Mutation Protocol and Ownership" "$repo" || fail "REPOSITORY template: missing mutation protocol heading"
grep -Fq '<!-- TODO(agent):' "$repo" || fail "REPOSITORY template: missing TODO(agent) placeholders"
grep -Fq "## 5) Validation Modes" "$repo" || fail "REPOSITORY template: missing validation modes heading"

echo "PASS: agent scaffold templates satisfy the bootstrap contract"
