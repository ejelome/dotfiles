#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

consumer="$tmp/consumer"
mkdir -p "$consumer"

cp "$ROOT/cursor/_templates/CLAUDE.md" "$consumer/CLAUDE.md"
cp "$ROOT/cursor/_templates/REPOSITORY.md" "$consumer/REPOSITORY.md"

cat >"$consumer/AGENTS.md" <<'FIXTURE'
# Agent guide
<!-- scaffold-version: 2026-05-01 -->

Agents edit tracked source in this repository. Global Cursor guidance lives in `~/.cursor/_CURSOR.md`.

To invoke a global Cursor command, prefix the prompt with `cursor`: `cursor /<namespace> ...` routes through `~/.cursor/commands/<namespace>.md`.
FIXTURE

grep -Fq 'cursor /<namespace>' "$consumer/AGENTS.md" || fail "fixture: missing old cursor slash prose"

# Simulate the confirmed /agent upgrade write for AGENTS.md: the route writes the
# accepted scaffold file from the current template.
cp "$ROOT/cursor/_templates/AGENTS.md" "$consumer/AGENTS.md"

grep -Fq '(<namespace> <command> <arg> ...)' "$consumer/AGENTS.md" || fail "upgrade fixture: missing parenthesized dispatch form"
grep -Fq '(collab join --role tw)' "$consumer/AGENTS.md" || fail "upgrade fixture: missing concrete parenthesized dispatch example"
grep -Fq '/collab join --role tw' "$consumer/AGENTS.md" || fail "upgrade fixture: missing paired slash command example"
if grep -Fq 'cursor /' "$consumer/AGENTS.md"; then
  fail "upgrade fixture: old cursor slash prose survived upgrade"
fi

if grep -R -n -E '^\*\*(Slash|Signature):\*\* `\(' "$ROOT/cursor/_functions" "$ROOT/cursor/commands"; then
  fail "upgrade fixture: prose dispatch rewrite changed slash route declarations"
fi

echo "PASS: upgrade fixture moves old cursor prose to parenthesized dispatch"
