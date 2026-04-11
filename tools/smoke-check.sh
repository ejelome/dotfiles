#!/usr/bin/env bash
# Smoke checks for shell, launcher, Python, git config, and Starship TOML.
# Does not read cursor/rules/*.mdc (no rule-content validation).
#
# Shellcheck (when installed) runs on bash entrypoints: link.sh, this script,
# tools/cursor-cli/install-extensions.sh, tools/cursor-cli/clear-chat.sh.
# Markdownlint (when installed) uses repo-root .markdownlint.json.
# Launcher lib/*.sh and zshrc are zsh; they are syntax-checked with zsh -n, not shellcheck.
#
# Cursor config tree checks use CURSOR_CONFIG_ROOT (default: $ROOT/cursor in this clone).
# Ensures commands/commands.md links every playbook under commands/*.md, extensions.txt
# exists, and nested-mirror paths are absent. skills-cursor/ is managed by Cursor itself
# and is not tracked in this repo.
#
# Usage: ./tools/smoke-check.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT/cursor}"

# Same nested-mirror strip as link.sh (Cursor may recreate these in-repo while the IDE is open).
strip_cursor_nested_mirrors() {
  local r="$CURSOR_CONFIG_ROOT"
  rm_self_symlink() {
    local nest="$1" want="$2"
    [[ -L "$nest" ]] || return 0
    [[ "$(readlink "$nest")" == "$want" ]] || return 0
    rm -f "$nest"
  }
  rm_self_symlink "$r/commands/commands" "$r/commands"
  rm_self_symlink "$r/rules/rules" "$r/rules"
  rm_self_symlink "$r/core/core" "$r/core"
}
strip_cursor_nested_mirrors

die() {
  echo "smoke-check: $*" >&2
  exit 1
}

echo "smoke-check: bash -n …"
bash -n "${ROOT}/link.sh"
bash -n "${ROOT}/tools/smoke-check.sh"
bash -n "${ROOT}/scripts/ext.sh"
bash -n "${ROOT}/tools/cursor-cli/install-extensions.sh"
bash -n "${ROOT}/tools/cursor-cli/clear-chat.sh"

echo "smoke-check: zsh -n …"
zsh -n "${ROOT}/launcher/setup-cursor-workspace-launcher.sh"
shopt -s nullglob
for lib in "${ROOT}/launcher/lib"/*.sh; do
  zsh -n "$lib"
done
shopt -u nullglob
zsh -n "${ROOT}/launcher/workspace-launcher.local.sh.example"
zsh -n "${ROOT}/launcher/templates/cursor-workspace-launcher.zsh.tpl"
zsh -n "${ROOT}/zshrc"

echo "smoke-check: python …"
python3 -m py_compile "${ROOT}/launcher/lib/dock_update.py"

echo "smoke-check: gitconfig …"
git config --file "${ROOT}/gitconfig" --list >/dev/null

if [[ "$(uname -s)" == Darwin ]] && command -v swiftc >/dev/null 2>&1; then
  echo "smoke-check: swift template parse …"
  tmp_swift="$(mktemp /tmp/smoke-check-picker-XXXXXX.swift)"
  sed -e 's/__PICKER_ITEMS__/"QA"/g' \
    -e 's/__WORKSPACE_PATHS__/"\/tmp"/g' \
    -e 's/__DEFAULT_SELECTION_INDEX__/0/g' \
    "${ROOT}/launcher/templates/cursor-workspace-picker.swift.tpl" >"$tmp_swift"
  swiftc -parse "$tmp_swift"
  rm -f "$tmp_swift"
elif [[ "$(uname -s)" == Darwin ]]; then
  echo "smoke-check: [warn] swiftc not in PATH; skipping Swift template parse" >&2
fi

if command -v starship >/dev/null 2>&1; then
  echo "smoke-check: starship config …"
  for toml in "${ROOT}/config"/starship*.toml; do
    [[ -e "$toml" ]] || continue
    STARSHIP_CONFIG="$toml" starship print-config >/dev/null
  done
fi

strip_cursor_nested_mirrors

echo "smoke-check: cursor layout (no rules content) …"
[[ -d "${CURSOR_CONFIG_ROOT}/commands" ]] || die "missing CURSOR_CONFIG_ROOT/commands ($CURSOR_CONFIG_ROOT)"
[[ -d "${CURSOR_CONFIG_ROOT}/rules" ]] || die "missing CURSOR_CONFIG_ROOT/rules ($CURSOR_CONFIG_ROOT)"
[[ -f "${CURSOR_CONFIG_ROOT}/extensions.txt" ]] || die "missing CURSOR_CONFIG_ROOT/extensions.txt ($CURSOR_CONFIG_ROOT)"
[[ ! -e "${CURSOR_CONFIG_ROOT}/rules/rules" ]] || die "remove nested rules/rules under CURSOR_CONFIG_ROOT"
[[ ! -e "${CURSOR_CONFIG_ROOT}/commands/commands" ]] || die "remove nested commands/commands under CURSOR_CONFIG_ROOT"
[[ ! -e "${CURSOR_CONFIG_ROOT}/core/core" ]] || die "remove nested core/core under CURSOR_CONFIG_ROOT"
shopt -s nullglob
cmds=( "${CURSOR_CONFIG_ROOT}/commands"/*.md )
shopt -u nullglob
((${#cmds[@]} > 0)) || die "CURSOR_CONFIG_ROOT/commands should contain at least one .md"
catalog="${CURSOR_CONFIG_ROOT}/commands/commands.md"
[[ -f "$catalog" ]] || die "missing commands catalog ($catalog)"
for f in "${cmds[@]}"; do
  base=$(basename "$f" .md)
  if ! grep -Fq "](${base}.md)" "$catalog"; then
    die "commands.md must link each playbook; missing ](${base}.md) for $(basename "$f")"
  fi
done

[[ -x "${ROOT}/link.sh" ]] || die "link.sh must be executable"
[[ -x "${ROOT}/tools/smoke-check.sh" ]] || die "tools/smoke-check.sh must be executable"
[[ -x "${ROOT}/scripts/ext.sh" ]] || die "scripts/ext.sh must be executable"
[[ -x "${ROOT}/launcher/setup-cursor-workspace-launcher.sh" ]] || die "launcher setup must be executable"

if command -v shellcheck >/dev/null 2>&1; then
  echo "smoke-check: shellcheck …"
  shellcheck -x "${ROOT}/link.sh" "${ROOT}/tools/smoke-check.sh" "${ROOT}/scripts/ext.sh" \
    "${ROOT}/tools/cursor-cli/install-extensions.sh" "${ROOT}/tools/cursor-cli/clear-chat.sh"
fi

if command -v markdownlint >/dev/null 2>&1; then
  echo "smoke-check: markdownlint …"
  tmp_md="$(mktemp)"
  git -C "$ROOT" ls-files '*.md' | grep -v '^cursor/rules/' >"$tmp_md" || true
  if [[ -s "$tmp_md" ]]; then
    xargs markdownlint <"$tmp_md"
  fi
  rm -f "$tmp_md"
fi

echo "smoke-check: OK"
