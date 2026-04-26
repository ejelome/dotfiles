#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"

cursor_root="$ROOT/cursor"
harness_root="$cursor_root/_tests"

extract_roster_items() {
  local file="$1"
  local line in_section
  in_section=0

  while IFS= read -r line; do
    if [[ "$line" == "## Required roster" || "$line" == "## Required rosters" ]]; then
      in_section=1
      continue
    fi
    if [[ $in_section -eq 1 && "$line" == "## Output" ]]; then
      break
    fi
    if [[ $in_section -eq 1 && "$line" =~ ^-\ \`([^\`]+)\`$ ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
    fi
  done < "$file"
}

sorted_lines() {
  local input=("$@")
  printf '%s\n' "${input[@]}" | sed '/^$/d' | sort
}

compare_roster() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  [[ "$expected" == "$actual" ]] || fail "${label} roster drift.
expected:
${expected}
actual:
${actual}"
}

expected_harness_bases=()
while IFS='|' read -r source_rel _dest_rel source_kind _requiredness; do
  [[ "$source_kind" == "dir" ]] || continue
  expected_harness_bases+=("$(basename "$source_rel")")
  assert_exists "$harness_root/$(basename "$source_rel").md"
done < <(cursor_runtime_link_specs)
expected_harness_bases+=("_settings")
assert_exists "$harness_root/_settings.md"

expected_harness_bases_sorted="$(sorted_lines "${expected_harness_bases[@]}")"

# 2) Every harness file must map back to a symlinked top-level ~/.cursor/ directory or explicit projection harness.
while IFS= read -r harness_file; do
  base="$(basename "$harness_file" .md)"
  printf '%s\n' "$expected_harness_bases_sorted" | grep -Fxq "$base" || fail "unexpected harness file: $harness_file"
done < <(find "$harness_root" -maxdepth 1 -type f -name '*.md' | sort)

expected=()
while IFS= read -r f; do
  expected+=("$(basename "$f")")
done < <(find "$cursor_root/commands" -maxdepth 1 -type f -name '*.md' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/commands.md" | sort)"
compare_roster "commands.md" "$expected_sorted" "$actual_sorted"

expected=()
while IFS= read -r f; do
  expected+=("$(basename "$f")")
done < <(find "$cursor_root/rules" -maxdepth 1 -type f -name '*.mdc' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/rules.md" | sort)"
compare_roster "rules.md" "$expected_sorted" "$actual_sorted"

expected=()
while IFS= read -r f; do
  expected+=("${f#"$cursor_root/_functions/"}")
done < <(find "$cursor_root/_functions" -type f -name '*.md' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/_functions.md" | sort)"
compare_roster "_functions.md" "$expected_sorted" "$actual_sorted"

expected=()
while IFS= read -r f; do
  expected+=("$(basename "$f")")
done < <(find "$cursor_root/_mdc/auto" "$cursor_root/_mdc/shared" -maxdepth 1 -type f -name '*.mdc' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/_mdc.md" | sort)"
compare_roster "_mdc.md" "$expected_sorted" "$actual_sorted"

while IFS= read -r f; do
  base="$(basename "$f")"
  case "$base" in
    auto-*.mdc) ;;
    *) fail "_mdc/auto filename must use auto-* prefix: $base" ;;
  esac
done < <(find "$cursor_root/_mdc/auto" -maxdepth 1 -type f -name '*.mdc' | sort)

while IFS= read -r f; do
  base="$(basename "$f")"
  case "$base" in
    shared-*.mdc) ;;
    *) fail "_mdc/shared filename must use shared-* prefix: $base" ;;
  esac
done < <(find "$cursor_root/_mdc/shared" -maxdepth 1 -type f -name '*.mdc' | sort)

expected=()
while IFS= read -r f; do
  expected+=("$(basename "$f")")
done < <(find "$cursor_root/_core" -maxdepth 1 -type f -name '*.md' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/_core.md" | sort)"
compare_roster "_core.md" "$expected_sorted" "$actual_sorted"

expected=()
while IFS='|' read -r source_rel dest_name source_kind _requiredness; do
  [[ "$source_kind" == "file" && "$source_rel" == _settings/*.json ]] || continue
  expected+=("$(basename "$source_rel")")
  [[ "$(basename "$source_rel")" == "$dest_name" ]] || fail "_settings runtime target drift: $source_rel -> $dest_name"
done < <(cursor_user_settings_link_specs)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/_settings.md" | sort)"
compare_roster "_settings.md" "$expected_sorted" "$actual_sorted"

expected=()
while IFS= read -r f; do
  expected+=("$(basename "$f")")
done < <(find "$cursor_root/_tests" -maxdepth 1 -type f -name '*.md' | sort)
expected_sorted="$(sorted_lines "${expected[@]}")"
actual_sorted="$(extract_roster_items "$harness_root/_tests.md" | sort)"
compare_roster "_tests.md" "$expected_sorted" "$actual_sorted"

echo "PASS: cursor directory harness files and rosters match cursor tree"
