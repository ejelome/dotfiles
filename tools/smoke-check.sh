#!/usr/bin/env bash
# Smoke checks for shell, launcher, Python, git config, and Starship TOML.
# Fails when macOS metadata files (.DS_Store) are present in the repo tree.
#
# Shellcheck (when installed) runs on bash entrypoints: link.sh, this script,
# tools/check-agent-adapters.sh,
# tools/manual/manual-link-fallback.sh,
# tools/cursor-cli/clear-chat.sh, tools/cursor-cli/factory-reset.sh.
# Markdownlint (when installed) uses repo-root .markdownlint.json.
# Launcher lib/*.sh and zshrc are zsh; they are syntax-checked with zsh -n, not shellcheck.
#
# Cursor runtime validation is intentionally outside this repository. This
# repository owns only Cursor User settings under cursor/.
#
# Usage: ./tools/smoke-check.sh
#
# When SKIP_TESTS_RUN=1, nested ./tests/run.sh is skipped (avoids recursion when
# smoke-check is exercised from tests/tools/smoke-check.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TMP_PYTHONPYCACHEPREFIX=""
if [[ -z "${PYTHONPYCACHEPREFIX:-}" ]]; then
  TMP_PYTHONPYCACHEPREFIX="$(mktemp -d /tmp/smoke-check-pycache-XXXXXX)"
  export PYTHONPYCACHEPREFIX="$TMP_PYTHONPYCACHEPREFIX"
fi

cleanup() {
  if [[ -n "$TMP_PYTHONPYCACHEPREFIX" ]]; then
    rm -rf "$TMP_PYTHONPYCACHEPREFIX"
  fi
}
trap cleanup EXIT

# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"

first_ds_store=""
while IFS= read -r f; do
  first_ds_store="$f"
  break
done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -name '.DS_Store' -print)
if [[ -n "$first_ds_store" ]]; then
  rel="${first_ds_store#"$ROOT"/}"
  echo "smoke-check: remove macOS metadata file: ${rel}" >&2
  exit 1
fi

die() {
  echo "smoke-check: $*" >&2
  exit 1
}

validate_cursor_ownership() {
  local tracked bad_path

  echo "smoke-check: cursor ownership guard …"
  while IFS= read -r tracked; do
    case "$tracked" in
      cursor/settings.json|cursor/keybindings.json) ;;
      cursor/*)
        die "cursor/ may contain only settings.json and keybindings.json (found ${tracked})"
        ;;
      tools/cursor/*|tools/collab/*|tools/check-cursor-*.sh|tools/check-cursor-*.py)
        die "Cursor runtime tooling belongs in dotcursor, not dotfiles (found ${tracked})"
        ;;
      tests/cursor/*|tests/tools/cursor/*|tests/tools/collab/*)
        die "Cursor runtime tests belong in dotcursor, not dotfiles (found ${tracked})"
        ;;
    esac
  done < <(git ls-files)

  bad_path=""
  # shellcheck disable=SC2016
  if LC_ALL=C grep -En '(\$HOME/\.cursor|~/\.cursor|[[:space:]"'\'']\.cursor/|cp[[:space:]].*\.cursor|rsync[[:space:]].*\.cursor)' "$ROOT/link.sh" >/tmp/smoke-check-link-cursor-refs.txt; then
    bad_path="$(head -n 1 /tmp/smoke-check-link-cursor-refs.txt)"
  fi
  rm -f /tmp/smoke-check-link-cursor-refs.txt
  [[ -z "$bad_path" ]] || die "link.sh must not write/copy/sync into ~/.cursor (${bad_path})"
}

echo "smoke-check: bash -n …"
bash -n "${ROOT}/link.sh"
bash -n "${ROOT}/tools/smoke-check.sh"
bash -n "${ROOT}/tools/check-agent-adapters.sh"
bash -n "${ROOT}/tools/manual/manual-link-fallback.sh"
bash -n "${ROOT}/tools/cursor-cli/dcc"
bash -n "${ROOT}/tools/cursor-cli/clear-chat.sh"
bash -n "${ROOT}/tools/cursor-cli/factory-reset.sh"
bash -n "${ROOT}/tools/zsh/install-plugins.sh"

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
python3 -m py_compile "${ROOT}/tools/narrative/state.py"

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

validate_cursor_ownership

[[ -x "${ROOT}/link.sh" ]] || die "link.sh must be executable"
[[ -x "${ROOT}/tools/smoke-check.sh" ]] || die "tools/smoke-check.sh must be executable"
[[ -x "${ROOT}/tools/check-agent-adapters.sh" ]] || die "tools/check-agent-adapters.sh must be executable"
[[ -x "${ROOT}/tools/manual/manual-link-fallback.sh" ]] || die "tools/manual/manual-link-fallback.sh must be executable"
[[ -x "${ROOT}/tools/cursor-cli/dcc" ]] || die "tools/cursor-cli/dcc must be executable"
[[ -x "${ROOT}/launcher/setup-cursor-workspace-launcher.sh" ]] || die "launcher setup must be executable"

if command -v shellcheck >/dev/null 2>&1; then
  echo "smoke-check: shellcheck …"
  shellcheck -x "${ROOT}/link.sh" "${ROOT}/tools/smoke-check.sh" \
    "${ROOT}/tools/check-agent-adapters.sh" \
    "${ROOT}/tools/manual/manual-link-fallback.sh" \
    "${ROOT}/tools/cursor-cli/dcc" \
    "${ROOT}/tools/cursor-cli/clear-chat.sh" "${ROOT}/tools/cursor-cli/factory-reset.sh"
else
  echo "smoke-check: [warn] shellcheck not in PATH; skipping." >&2
fi

if command -v markdownlint >/dev/null 2>&1; then
  echo "smoke-check: markdownlint …"
  tmp_md="$(mktemp)"
  git -C "$ROOT" ls-files '*.md' >"$tmp_md" || true
  if [[ -s "$tmp_md" ]]; then
    xargs markdownlint <"$tmp_md"
  fi
  rm -f "$tmp_md"
else
  echo "smoke-check: [warn] markdownlint not in PATH; skipping." >&2
fi

if [[ "${SKIP_TESTS_RUN:-0}" == "1" ]]; then
  echo "smoke-check: tests skipped (SKIP_TESTS_RUN=1)"
else
  echo "smoke-check: tests …"
  "$ROOT/tests/run.sh"
fi

echo "smoke-check: OK"
