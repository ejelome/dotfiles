#!/usr/bin/env bash

# Shared Cursor layout guards for link.sh and smoke-check.sh.

cursor_nested_mirror_rel_paths() {
  cat <<'EOF'
commands/commands
rules/rules
_functions/_functions
_core/_core
_mdc/_mdc
_tests/_tests
_roles/_roles
_templates/_templates
EOF
}

cursor_strip_nested_mirrors() {
  local cursor_root="$1"
  local rel nest want

  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    nest="${cursor_root}/${rel}"
    want="${cursor_root}/${rel%/*}"
    [[ -L "$nest" ]] || continue
    [[ "$(readlink "$nest")" == "$want" ]] || continue
    rm -f "$nest"
  done < <(cursor_nested_mirror_rel_paths)
}

cursor_assert_no_nested_mirrors() {
  local cursor_root="$1"
  local prefix="${2:-cursor-layout}"
  local rel bad

  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    bad="${cursor_root}/${rel}"
    if [[ -e "$bad" ]]; then
      echo "${prefix}: remove ${bad} (nested mirror or unknown layout under CURSOR_CONFIG_ROOT)." >&2
      return 1
    fi
  done < <(cursor_nested_mirror_rel_paths)

  for rel in core user; do
    bad="${cursor_root}/${rel}"
    if [[ -e "$bad" ]]; then
      echo "${prefix}: private Cursor folders under CURSOR_CONFIG_ROOT must be underscore-prefixed: ${bad}" >&2
      return 1
    fi
  done
}
