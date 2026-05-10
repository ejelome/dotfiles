#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/agent.md"
catalog="$ROOT/cursor/commands/commands.md"

grep -Fq '**Signature:** `/agent <install | patch | upgrade>`' "$file" || fail "agent.md: missing routed signature"
for route in install patch upgrade; do
  grep -Fq "\`${route}\` -> [_functions/agent/${route}](../_functions/agent/${route}.md)" "$file" || fail "agent.md: missing ${route} route"
  grep -Fq "[agent/${route}.md](../_functions/agent/${route}.md)" "$catalog" || fail "commands.md: missing agent/${route}.md catalog entry"
done
grep -Fq '/agent install' "$file" || fail "agent.md: missing install example"
grep -Fq '/agent patch' "$file" || fail "agent.md: missing patch example"
grep -Fq '/agent upgrade' "$file" || fail "agent.md: missing upgrade example"
grep -Fq 'does not write to' "$file" || fail "agent.md: missing boundary note on ~/.cursor/ mutation"
grep -Fq 'agent settings JSON' "$file" || fail "agent.md: missing agent settings JSON exclusion boundary"
grep -Fq '/agent <install' "$catalog" || fail "commands.md: missing /agent invocation note"

install_file="$ROOT/cursor/_functions/agent/install.md"
patch_file="$ROOT/cursor/_functions/agent/patch.md"

grep -Fq '~/.cursor/_templates/' "$install_file" || fail "install.md: missing template source path"
grep -Fq 'ABORT' "$install_file" || fail "install.md: missing abort on existing files"
grep -Fq '<!-- TODO(agent):' "$install_file" || fail "install.md: missing placeholder standard reference"
grep -Fq 'Validate scaffold-local install state' "$install_file" || fail "install.md: missing scaffold-local validation step"
grep -Fq 'CLAUDE.md` routes to `AGENTS.md' "$install_file" || fail "install.md: missing CLAUDE -> AGENTS validation"
grep -Fq '`AGENTS.md` references `~/.cursor/_CURSOR.md`' "$install_file" || fail "install.md: missing AGENTS runtime reference validation"
grep -Fq 'the `AGENTS.md` prose dispatch sentence' "$install_file" || fail "install.md: missing prose dispatch validation"
grep -Fq 'every Markdown link in the installed `AGENTS.md` whose target does not begin with `~` or `http` resolves as a file path relative to the repo root' "$install_file" || fail "install.md: missing consumer-root Markdown link validation"
grep -Fq '**ABORT** naming the unresolvable path' "$install_file" || fail "install.md: missing unresolvable Markdown link abort"
grep -Fq '/agent patch' "$install_file" || fail "install.md: missing next-step reference to patch"
if grep -Fq 'Emit one notice per agent that may inject itself into git commits, naming the agent and the setting used to disable commit injection.' "$install_file"; then
  fail "install.md: removed commit-injection notice step must stay absent"
fi

grep -Fq 'REPOSITORY.md' "$patch_file" || fail "patch.md: missing REPOSITORY.md target reference"
grep -Fq 'ABORT' "$patch_file" || fail "patch.md: missing abort conditions"
grep -Fq '<!-- TODO(agent):' "$patch_file" || fail "patch.md: missing placeholder standard reference"
grep -Fq 'Validate scaffold-local patch state' "$patch_file" || fail "patch.md: missing scaffold-local validation step"
grep -Fq 'Idempotency' "$patch_file" || fail "patch.md: missing idempotency note"
grep -Fq '/agent install' "$patch_file" || fail "patch.md: missing reference to install prerequisite"
grep -Fq 'For validation commands, only include a command path when that exact path exists in the target repo' "$patch_file" || fail "patch.md: missing target-repo validation command discovery rule"
grep -Fq 'do not copy validation commands from any other repository' "$patch_file" || fail "patch.md: missing cross-repo validation command ban"
grep -Fq '<!-- TODO(agent): list repo-specific validation commands -->' "$patch_file" || fail "patch.md: missing bounded validation-command TODO fallback"
grep -Eiq '\binfer\b' "$patch_file" || fail "patch.md: missing infer-before-confirm wording"
grep -Eiq '\bdisplay\b' "$patch_file" || fail "patch.md: missing display-before-confirm wording"
grep -Eiq '\bconfirm\b' "$patch_file" || fail "patch.md: missing confirm-before-write wording"
if grep -Fq 'prompt for or accept' "$patch_file"; then
  fail "patch.md: must not retain old prompt-or-accept wording"
fi

echo "PASS: agent.md routes the multi-agent scaffold workflow"
