#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for bin in codex claude; do
  cat >"$tmpdir/$bin" <<'SH'
#!/usr/bin/env bash
printf '\033]0;child-title\007'
{
  printf 'argv0=%s\n' "$0"
  printf 'args=%s\n' "$*"
} >"$DCC_CAPTURE"
sleep 0.12
SH
  chmod +x "$tmpdir/$bin"
done

while IFS='|' read -r shortcut binary model agent_id flag effort_arg service_tier; do
  [[ -n "$shortcut" ]] || continue

  capture="$tmpdir/${shortcut}.txt"
  title_output="$(DCC_FORCE_TITLE=1 DCC_TITLE_REASSERTS=4 DCC_TITLE_INTERVAL=0.03 DCC_CAPTURE="$capture" PATH="$tmpdir:$PATH" "$ROOT/tools/cursor-cli/dcc" "$shortcut" --sandbox workspace-write)"
  expected_title="$(printf '\033]0;%s (%s)\007' "$shortcut" "$agent_id")"
  child_title="$(printf '\033]0;child-title\007')"

  output="$(cat "$capture")"
  assert_contains "$title_output" "$child_title"
  [[ "$title_output" == *"$expected_title" ]] || fail "dcc should leave terminal title as role plus agentId for $shortcut"
  assert_contains "$output" "argv0=$tmpdir/$binary"
  if [[ "$binary" == codex ]]; then
    assert_contains "$output" "args=$flag $model -c service_tier=\"$service_tier\" -c model_reasoning_effort=$effort_arg --sandbox workspace-write"
    [[ "$output" != *"--ask-for-approval"* ]] || fail "dcc should let Codex config control approvals"
  elif [[ "$binary" == claude ]]; then
    assert_contains "$output" "args=$flag $model --effort $effort_arg --sandbox workspace-write"
    assert_contains "$output" "--sandbox workspace-write"
    [[ "$output" != *"--permission-mode"* ]] || fail "dcc should let Claude settings control permissions"
    [[ "$output" != *"--add-dir"* ]] || fail "dcc should not pass Claude add-dir defaults"
    [[ "$output" != *"--allowedTools"* ]] || fail "dcc should not pass Claude allowedTools defaults"
  else
    assert_contains "$output" "args=$flag $model --sandbox workspace-write"
  fi
done <<'CASES'
mod|codex|gpt-5.4-mini|gpt-5.4-mini|-m|low|fast
tw|claude|claude-sonnet-4-6|claude-sonnet-4-6|--model|medium|
pa|claude|claude-opus-4-7|claude-opus-4-7|--model|xhigh|
pe|codex|gpt-5.5|gpt-5.5|-m|medium|fast
CASES

while IFS='|' read -r shortcut binary forbidden_prompt_arg alias; do
  [[ -n "$shortcut" ]] || continue

  capture="$tmpdir/${shortcut}-${alias}.txt"
  DCC_FORCE_TITLE=1 DCC_TITLE_REASSERTS=0 DCC_CAPTURE="$capture" PATH="$tmpdir:$PATH" "$ROOT/tools/cursor-cli/dcc" "$shortcut" "$alias" --sandbox workspace-write >/dev/null
  output="$(cat "$capture")"
  assert_contains "$output" "argv0=$tmpdir/$binary"
  [[ "$output" != *"$forbidden_prompt_arg"* ]] || fail "dcc should ignore $alias prompt flag for $shortcut"
  assert_contains "$output" "--sandbox workspace-write"
done <<'CASES'
mod|codex|--ask-for-approval never|--yes-all
tw|claude|--permission-mode dontAsk|--skip-all-prompts
CASES

echo "PASS: dcc routes all role shortcuts to the right CLI models"
