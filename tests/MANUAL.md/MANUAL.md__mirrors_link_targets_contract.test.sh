#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"
# shellcheck source=tools/lib/cursor-layout.sh
source "$ROOT/tools/lib/cursor-layout.sh"

manual="$(<"$ROOT/MANUAL.md")"
golden="$ROOT/tests/MANUAL.md/MANUAL.md.golden"

cmp -s "$ROOT/MANUAL.md" "$golden" || fail "MANUAL.md: differs from tests/MANUAL.md/MANUAL.md.golden"

python3 - "$ROOT/MANUAL.md" <<'PY' || fail "MANUAL.md: TOC must be wrapped with --- before and after"
import sys

text = open(sys.argv[1], encoding="utf-8").read()
expected = """---

**Table of contents**

- [Prerequisites](#prerequisites)
- [Reproduce the automated link pass by hand](#reproduce-the-automated-link-pass-by-hand)
  - [1. Clean nested mirrors under the Cursor config root, then assert](#1-clean-nested-mirrors-under-the-cursor-config-root-then-assert)
  - [2. Link required top-level home files](#2-link-required-top-level-home-files)
  - [3. Remove legacy `~/.cursor/core` if present as a symlink](#3-remove-legacy-cursorcore-if-present-as-a-symlink)
  - [4. Mirror `config/` into `~/.config/`](#4-mirror-config-into-config)
  - [5. Link the Cursor runtime tree](#5-link-the-cursor-runtime-tree)
  - [6. Link Cursor user settings (platform-specific User folder)](#6-link-cursor-user-settings-platform-specific-user-folder)
  - [7. Optional: install Cursor and expose the `cursor` CLI (macOS-oriented)](#7-optional-install-cursor-and-expose-the-cursor-cli-macos-oriented)
  - [8. Optional: build the workspace launcher app (macOS)](#8-optional-build-the-workspace-launcher-app-macos)
  - [9. Optional: zsh plugin directories](#9-optional-zsh-plugin-directories)
  - [10. Final mirror strip and assert](#10-final-mirror-strip-and-assert)
- [Verification](#verification)
- [Status](#status)

---"""

if expected not in text:
    raise SystemExit(1)
PY

while IFS='|' read -r source_rel dest_rel _source_kind _required; do
  [[ -n "$source_rel" ]] || continue
  assert_contains "$manual" "| \`$source_rel\` | \`$dest_rel\` |"
done < <(dotfiles_home_link_specs)

while IFS='|' read -r source_rel dest_rel source_kind _required; do
  [[ -n "$source_rel" ]] || continue
  case "$source_kind" in
    dir) manual_kind="directory" ;;
    file) manual_kind="file" ;;
    *) fail "unknown source kind in cursor_runtime_link_specs: $source_kind" ;;
  esac
  assert_contains "$manual" "| \`$source_rel\` | \`$dest_rel\` | $manual_kind |"
done < <(cursor_runtime_link_specs)

while IFS='|' read -r source_rel dest_name _source_kind _required; do
  [[ -n "$source_rel" ]] || continue
  assert_contains "$manual" "- \`$source_rel\` → \`$dest_name\` in that \`User\` directory"
done < <(cursor_user_settings_link_specs)

while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  assert_contains "$manual" "- \`$rel\`"
done < <(cursor_nested_mirror_rel_paths)

assert_contains "$manual" 'tools/zsh/install-plugins.sh'
assert_contains "$manual" 'launcher/setup-cursor-workspace-launcher.sh'
assert_contains "$manual" 'SKIP_TESTS_RUN=1 ./tools/smoke-check.sh'
assert_contains "$manual" './tests/run.sh'

echo "PASS: MANUAL.md mirrors link target and nested-layout contracts"
