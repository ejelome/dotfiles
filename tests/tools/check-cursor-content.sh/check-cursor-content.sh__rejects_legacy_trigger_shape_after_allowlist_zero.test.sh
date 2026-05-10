#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

targets=(
  "commands/agent.md"
  "_functions/agent/install.md"
  "_functions/agent/patch.md"
  "_functions/agent/upgrade.md"
)

write_route() {
  local path="$1" title="$2" slash="$3" signature="$4" prose="$5" old_shape="$6"
  mkdir -p "$(dirname "$tmp/$path")"
  {
    printf '# %s\n\n' "$title"
    printf 'Exercise the trigger contract for %s.\n\n' "$title"
    printf '## Trigger\n\n'
    printf '**Slash:** `%s`\n' "$slash"
    printf '**Signature:** `%s`\n' "$signature"
    if [[ "$old_shape" == "old" ]]; then
      printf '**Phrases:** old trigger shape\n'
    else
      printf '**Prose dispatch:** `%s` — for non-Cursor agents; not terminal-executable in Cursor.\n' "$prose"
      printf '**Search phrases:** trigger contract check\n'
    fi
    printf '\n## Steps\n\n'
    printf '1. Resolve the route.\n\n'
    printf '## Notes\n\n'
    printf -- '- **Parameters:** none.\n'
  } >"$tmp/$path"
}

run_case() {
  local old_target="$1" output status target

  rm -rf "$tmp/commands" "$tmp/_functions" "$tmp/rules" "$tmp/_mdc"
  mkdir -p "$tmp/rules" "$tmp/_mdc"

  for target in "${targets[@]}"; do
    case "$target" in
      commands/agent.md)
        write_route "$target" "/agent" "/agent" "/agent <install | patch | upgrade>" "(agent <install | patch | upgrade>)" "$([[ "$target" == "$old_target" ]] && printf old || printf good)"
        ;;
      _functions/agent/install.md)
        write_route "$target" "/agent install" "/agent install" "/agent install" "(agent install)" "$([[ "$target" == "$old_target" ]] && printf old || printf good)"
        ;;
      _functions/agent/patch.md)
        write_route "$target" "/agent patch" "/agent patch" "/agent patch" "(agent patch)" "$([[ "$target" == "$old_target" ]] && printf old || printf good)"
        ;;
      _functions/agent/upgrade.md)
        write_route "$target" "/agent upgrade" "/agent upgrade" "/agent upgrade" "(agent upgrade)" "$([[ "$target" == "$old_target" ]] && printf old || printf good)"
        ;;
    esac
  done

  set +e
  output="$({
    CURSOR_CONFIG_ROOT="$tmp" \
    "$ROOT/tools/check-cursor-content.sh"
  } 2>&1)"
  status=$?
  set -e

  [[ $status -ne 0 ]] || fail "check-cursor-content should reject old trigger shape for cursor/${old_target}"
  assert_contains "$output" "trigger contract expected exactly one '**Prose dispatch:**' line"
}

for target in "${targets[@]}"; do
  run_case "$target"
done

echo "PASS: check-cursor-content rejects old trigger shape for /agent after allow-list zero"
