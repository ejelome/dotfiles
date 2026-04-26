#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT/cursor}"

die() {
  echo "check-cursor-content: $*" >&2
  exit 1
}

relpath() {
  local path="$1"
  if [[ "$path" == "$ROOT/"* ]]; then
    printf '%s\n' "${path#"$ROOT"/}"
  else
    printf '%s\n' "$path"
  fi
}

h1_count_without_fences() {
  local file="$1"
  awk '
    BEGIN { in_fence = 0; count = 0 }
    /^```/ || /^~~~/ { in_fence = !in_fence; next }
    !in_fence && /^# / { count++ }
    END { print count }
  ' "$file"
}

section_line() {
  local file="$1" heading="$2" out count line
  out="$(grep -n "^## ${heading}\$" "$file" || true)"
  count="$(printf '%s\n' "$out" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || die "$(relpath "$file"): expected exactly one '## ${heading}' heading"
  line="${out%%:*}"
  printf '%s\n' "$line"
}

check_line_budget() {
  local file lines
  while IFS= read -r file; do
    lines="$(wc -l < "$file" | tr -d ' ')"
    (( lines <= 250 )) || die "$(relpath "$file"): exceeds 250-line budget (${lines})"
  done < <(find "$CURSOR_CONFIG_ROOT" -type f \( -name '*.md' -o -name '*.mdc' \) | sort)
}

check_command_shapes() {
  local file h1_count trigger_line steps_line notes_line
  while IFS= read -r file; do
    h1_count="$(h1_count_without_fences "$file")"
    [[ "$h1_count" == "1" ]] || die "$(relpath "$file"): expected exactly one H1 outside code fences"

    trigger_line="$(section_line "$file" "Trigger")"
    steps_line="$(section_line "$file" "Steps")"
    notes_line="$(section_line "$file" "Notes")"
    (( trigger_line < steps_line && steps_line < notes_line )) || die "$(relpath "$file"): section order must be Trigger -> Steps -> Notes"
  done < <(
    find "$CURSOR_CONFIG_ROOT/commands" -maxdepth 1 -type f -name '*.md' | sort
    find "$CURSOR_CONFIG_ROOT/_functions" -type f -name '*.md' | sort
  )
}

check_rule_shapes() {
  local file front_matter h1_count
  while IFS= read -r file; do
    [[ "$(head -n 1 "$file")" == "---" ]] || die "$(relpath "$file"): missing YAML front matter start ('---')"

    front_matter="$(
      awk '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm { print }
      ' "$file"
    )"
    [[ -n "$front_matter" ]] || die "$(relpath "$file"): missing YAML front matter body"
    grep -Eq '^description:' <<<"$front_matter" || die "$(relpath "$file"): front matter must include description"
    grep -Eq '^alwaysApply:' <<<"$front_matter" || die "$(relpath "$file"): front matter must include alwaysApply"

    h1_count="$(h1_count_without_fences "$file")"
    [[ "$h1_count" == "1" ]] || die "$(relpath "$file"): expected exactly one H1 outside code fences"
    grep -Fq '**Triggers:**' "$file" || die "$(relpath "$file"): missing '**Triggers:**' line"
  done < <(
    find "$CURSOR_CONFIG_ROOT/rules" -maxdepth 1 -type f -name '*.mdc' | sort
    find "$CURSOR_CONFIG_ROOT/_mdc" -type f -name '*.mdc' | sort
  )
}

[[ -d "$CURSOR_CONFIG_ROOT" ]] || die "CURSOR_CONFIG_ROOT directory does not exist: $CURSOR_CONFIG_ROOT"

check_line_budget
check_command_shapes
check_rule_shapes

echo "check-cursor-content: OK"
