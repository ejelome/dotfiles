#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

targets=(
  "$ROOT/cursor/_templates"
  "$ROOT/cursor/_functions"
  "$ROOT/cursor/commands"
)

old_dispatch_regex='cursor[[:space:]]+/'
exclude_directory_path='(^|[`[:space:]])(~?/?.?cursor/|cursor/)'
exclude_markdown_link='\]\([^)]*cursor/[^)]*\)'
exclude_product_noun='Cursor([[:space:][:punct:]]|$)'

is_excluded_cursor_line() {
  local text="$1"
  [[ "$text" =~ $exclude_directory_path ]] && return 0
  [[ "$text" =~ $exclude_markdown_link ]] && return 0
  [[ "$text" =~ $exclude_product_noun ]] && return 0
  return 1
}

while IFS= read -r match; do
  line_text="${match#*:}"
  line_text="${line_text#*:}"
  if [[ "$line_text" =~ $old_dispatch_regex ]]; then
    fail "old cursor slash prose dispatch remains: $match"
  fi
  is_excluded_cursor_line "$line_text" || true
done < <(grep -R -n -E 'cursor|Cursor' "${targets[@]}" || true)

if grep -R -n -E '^\*\*(Slash|Signature):\*\* `\(' "$ROOT/cursor/_functions" "$ROOT/cursor/commands"; then
  fail "slash route declarations must not become parenthesized dispatch forms"
fi

grep -Fq '**Slash:** `/collab`' "$ROOT/cursor/commands/collab.md" || fail "collab router slash declaration changed"
grep -Fq '**Slash:** `/agent`' "$ROOT/cursor/commands/agent.md" || fail "agent router slash declaration changed"
grep -Fq '**Slash:** `/agent install`' "$ROOT/cursor/_functions/agent/install.md" || fail "agent install slash declaration changed"
grep -Fq '**Signature:** `/collab <' "$ROOT/cursor/commands/collab.md" || fail "collab router signature changed"
grep -Fq '**Signature:** `/agent <' "$ROOT/cursor/commands/agent.md" || fail "agent router signature changed"

dispatch_refs="$(grep -R -n -E -o '`\((agent|collab|docs|eval|git|revamp|test) [^`]*\)`' "${targets[@]}" || true)"
[[ -n "$dispatch_refs" ]] || fail "missing concrete parenthesized prose dispatch examples"

while IFS= read -r ref; do
  form="${ref##*:}"
  form="${form#\`}"
  form="${form%\`}"
  [[ "$form" =~ ^\([a-z][a-z0-9-]*(\ [^[:space:]()]+)+\)$ ]] || fail "noncanonical parenthesized dispatch example: $ref"
done <<< "$dispatch_refs"

grep -Fq '(<namespace> <command> <arg> ...)' "$ROOT/cursor/_templates/AGENTS.md" || fail "AGENTS template: missing canonical parenthesized dispatch placeholder"

echo "PASS: command docs preserve slash routes and prose dispatch boundary"
