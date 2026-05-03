#!/usr/bin/env bash
# Smoke checks for shell, launcher, Python, git config, and Starship TOML.
# Fails when macOS metadata files (.DS_Store) are present in the repo tree.
# Includes adapter-sync checks and Cursor markdown semantics checks.
#
# Shellcheck (when installed) runs on bash entrypoints: link.sh, this script,
# tools/check-agent-adapters.sh, tools/check-cursor-content.sh,
# tools/cursor/sync-commands-catalog.sh, tools/cursor/sync-roles-roster.sh,
# tools/manual/manual-link-fallback.sh,
# tools/cursor-cli/clear-chat.sh, tools/cursor-cli/factory-reset.sh.
# Markdownlint (when installed) uses repo-root .markdownlint.json.
# Launcher lib/*.sh and zshrc are zsh; they are syntax-checked with zsh -n, not shellcheck.
#
# Cursor config tree checks use CURSOR_CONFIG_ROOT (default: $ROOT/cursor in this clone).
# Ensures commands/commands.md links every public command under commands/*.md
# and every private route function under _functions/**/*.md. Ensures roles and rules/
# exposes only router files and private rule bodies live under _mdc/{auto,shared}/.
# Nested-mirror paths are absent. skills-cursor/ is managed by Cursor itself and
# is not tracked in this repo.
# By default this script is read-only; set SMOKE_CHECK_FIX_NESTED_MIRRORS=1 to
# remove known self-symlink nested mirrors before validation.
#
# Optional project-local .cursor validation runs only when PROJECT_DOT_CURSOR is
# set to an absolute path. That guard rejects authoring-core references and
# collisions with global command/rule router names so app repos consume
# installed rules/commands without depending on this repo's canon.
#
# Optional runtime projection validation runs only when SMOKE_CHECK_RUNTIME=1.
# In runtime mode, required runtime destinations must exist as copied files or
# directories matching the expected CURSOR_CONFIG_ROOT sources.
#
# Usage: ./tools/smoke-check.sh
#
# When SKIP_TESTS_RUN=1, nested ./tests/run.sh is skipped (avoids recursion when
# smoke-check is exercised from tests/tools/smoke-check.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT/cursor}"
SMOKE_CHECK_RUNTIME="${SMOKE_CHECK_RUNTIME:-0}"
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

# shellcheck source=tools/lib/cursor-layout.sh
source "$ROOT/tools/lib/cursor-layout.sh"
# shellcheck source=tools/lib/link-targets.sh
source "$ROOT/tools/lib/link-targets.sh"

if [[ "${SMOKE_CHECK_FIX_NESTED_MIRRORS:-0}" == "1" ]]; then
  echo "smoke-check: fixing nested self-symlink mirrors (SMOKE_CHECK_FIX_NESTED_MIRRORS=1) …"
  cursor_strip_nested_mirrors "$CURSOR_CONFIG_ROOT"
fi
cursor_assert_no_nested_mirrors "$CURSOR_CONFIG_ROOT" "smoke-check" || exit 1

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

case "$SMOKE_CHECK_RUNTIME" in
  0|1) ;;
  *) die "SMOKE_CHECK_RUNTIME must be 0 or 1 (got: $SMOKE_CHECK_RUNTIME)" ;;
esac

project_overlay_collision_is_allowlisted() {
  local rel_path="$1"
  case "$rel_path" in
    commands/commands.md) return 0 ;;
    *) return 1 ;;
  esac
}

validate_project_overlay_router_collisions() {
  local project="$1"
  local router_dir="$2"
  local glob="$3"
  local singular="${router_dir%?}"
  local overlay_dir="$project/$router_dir"
  local source_dir="$CURSOR_CONFIG_ROOT/$router_dir"
  local path base rel

  [[ -d "$overlay_dir" ]] || return 0

  while IFS= read -r path; do
    base="$(basename "$path")"
    rel="${router_dir}/${base}"
    [[ -f "${source_dir}/${base}" ]] || continue

    if project_overlay_collision_is_allowlisted "$rel"; then
      continue
    fi

    die "PROJECT_DOT_CURSOR must not override global ${singular} router: ${rel}"
  done < <(find "$overlay_dir" -maxdepth 1 -type f -name "$glob" | sort)
}

validate_project_dot_cursor() {
  local project="${PROJECT_DOT_CURSOR:-}" bad_file
  [[ -n "$project" ]] || return 0

  case "$project" in
    /*) ;;
    *) die "PROJECT_DOT_CURSOR must be an absolute path: $project" ;;
  esac

  [[ -d "$project" ]] || die "PROJECT_DOT_CURSOR directory does not exist: $project"
  [[ ! -e "$project/_core" ]] || die "PROJECT_DOT_CURSOR must not contain _core/ ($project/_core)"
  [[ ! -e "$project/core" ]] || die "PROJECT_DOT_CURSOR must not contain legacy core/ ($project/core)"

  echo "smoke-check: project .cursor guard ($project) …"
  bad_file=""
  while IFS= read -r -d '' f; do
    if LC_ALL=C grep -Eq '(\.\./_?core/|cursor/_?core|~/.cursor/_?core|@cursor/_?core)' "$f"; then
      bad_file="$f"
      break
    fi
  done < <(find "$project" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.json' \) -print0)

  [[ -z "$bad_file" ]] || die "PROJECT_DOT_CURSOR must not reference authoring core: ${bad_file#"$project"/}"
  validate_project_overlay_router_collisions "$project" "commands" "*.md"
  validate_project_overlay_router_collisions "$project" "rules" "*.mdc"
}

validate_runtime_projection() {
  local source_rel dest_rel source_kind required expected actual
  local cursor_user_dir dest_name

  [[ "$SMOKE_CHECK_RUNTIME" == "1" ]] || return 0

  echo "smoke-check: runtime projection (SMOKE_CHECK_RUNTIME=1) …"

  while IFS='|' read -r source_rel dest_rel source_kind required; do
    [[ -n "$source_rel" ]] || continue
    expected="${CURSOR_CONFIG_ROOT}/${source_rel}"
    actual="${HOME}/${dest_rel}"

    if [[ ! -e "$actual" ]]; then
      [[ "$required" == "optional" ]] && continue
      die "runtime projection missing destination: ${actual} (expected -> ${expected})"
    fi
    [[ ! -L "$actual" ]] || die "runtime projection expects copied path, not symlink: ${actual}"
    case "$source_kind" in
      dir)
        [[ -d "$actual" ]] || die "runtime projection expects directory at ${actual}"
        diff -qr "$expected" "$actual" >/dev/null || die "runtime projection differs at ${actual}: expected copy of ${expected}"
        ;;
      file)
        [[ -f "$actual" ]] || die "runtime projection expects file at ${actual}"
        cmp -s "$expected" "$actual" || die "runtime projection differs at ${actual}: expected copy of ${expected}"
        ;;
      *)
        die "unknown runtime source kind: ${source_kind}"
        ;;
    esac
  done < <(cursor_runtime_link_specs)

  cursor_user_dir="$(cursor_user_dir_for_home "$HOME" "$OSTYPE" "${XDG_CONFIG_HOME:-}")"
  while IFS='|' read -r source_rel dest_name source_kind required; do
    [[ -n "$source_rel" ]] || continue
    expected="${CURSOR_CONFIG_ROOT}/${source_rel}"
    actual="${cursor_user_dir}/${dest_name}"

    if [[ ! -e "$actual" ]]; then
      [[ "$required" == "optional" ]] && continue
      die "runtime projection missing destination: ${actual} (expected -> ${expected})"
    fi
    [[ -L "$actual" ]] || die "runtime projection expects symlink at ${actual}"
    [[ "$(readlink "$actual")" == "$expected" ]] || die "runtime projection mismatch at ${actual}: expected ${expected}"
  done < <(cursor_user_settings_link_specs)
}

echo "smoke-check: bash -n …"
bash -n "${ROOT}/link.sh"
bash -n "${ROOT}/tools/smoke-check.sh"
bash -n "${ROOT}/tools/check-agent-adapters.sh"
bash -n "${ROOT}/tools/check-cursor-content.sh"
bash -n "${ROOT}/tools/cursor/sync-commands-catalog.sh"
bash -n "${ROOT}/tools/cursor/sync-roles-roster.sh"
bash -n "${ROOT}/tools/manual/manual-link-fallback.sh"
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
python3 -m py_compile "${ROOT}/tools/cursor/roles.py"
python3 -m py_compile "${ROOT}/tools/collab/registry.py"
python3 -m py_compile "${ROOT}/tools/revamp/state.py"

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

echo "smoke-check: cursor layout (no rules content) …"
while IFS='|' read -r source_rel dest_rel source_kind required; do
  [[ -n "$source_rel" ]] || continue
  [[ "$required" == "required" ]] || continue
  source_path="${CURSOR_CONFIG_ROOT}/${source_rel}"
  if ! link_source_exists "$source_path" "$source_kind"; then
    die "missing CURSOR_CONFIG_ROOT/${source_rel} ($CURSOR_CONFIG_ROOT)"
  fi
done < <(cursor_runtime_link_specs)

if find "${CURSOR_CONFIG_ROOT}/commands" -mindepth 1 -type d | grep -q .; then
  die "commands/ must contain only public slash .md files; move route bodies to _functions/"
fi
if find "${CURSOR_CONFIG_ROOT}/rules" -mindepth 1 -type d | grep -q .; then
  die "rules/ must contain only router .mdc files; move rule bodies to _mdc/"
fi
while IFS= read -r f; do
  die "commands/ contains unexpected file; keep only .md routers (found ${f#"${CURSOR_CONFIG_ROOT}"/commands/})"
done < <(find "${CURSOR_CONFIG_ROOT}/commands" -maxdepth 1 -type f ! -name '*.md' | sort)
while IFS= read -r f; do
  die "rules/ contains unexpected file; keep only .mdc routers (found ${f#"${CURSOR_CONFIG_ROOT}"/rules/})"
done < <(find "${CURSOR_CONFIG_ROOT}/rules" -maxdepth 1 -type f ! -name '*.mdc' | sort)
for router in auto.mdc shared.mdc; do
  [[ -f "${CURSOR_CONFIG_ROOT}/rules/${router}" ]] || die "missing rules router (${router})"
done
while IFS= read -r f; do
  base="$(basename "$f")"
  case "$base" in
    auto.mdc|shared.mdc) ;;
    *) die "rules/ contains unexpected file; keep only auto.mdc and shared.mdc (found ${base})" ;;
  esac
done < <(find "${CURSOR_CONFIG_ROOT}/rules" -maxdepth 1 -type f -name '*.mdc' | sort)
[[ -d "${CURSOR_CONFIG_ROOT}/_mdc/auto" ]] || die "missing CURSOR_CONFIG_ROOT/_mdc/auto"
[[ -d "${CURSOR_CONFIG_ROOT}/_mdc/shared" ]] || die "missing CURSOR_CONFIG_ROOT/_mdc/shared"
find "${CURSOR_CONFIG_ROOT}/_mdc/auto" -maxdepth 1 -type f -name '*.mdc' | grep -q . || die "_mdc/auto should contain at least one .mdc"
find "${CURSOR_CONFIG_ROOT}/_mdc/shared" -maxdepth 1 -type f -name '*.mdc' | grep -q . || die "_mdc/shared should contain at least one .mdc"
for f in "${CURSOR_CONFIG_ROOT}/_mdc/auto/"*.mdc; do
  [[ -f "$f" ]] || continue
  rel="${f#"${CURSOR_CONFIG_ROOT}"/_mdc/}"
  grep -Fq "](../_mdc/${rel})" "${CURSOR_CONFIG_ROOT}/rules/auto.mdc" || die "rules/auto.mdc must link ../_mdc/${rel}"
done
for f in "${CURSOR_CONFIG_ROOT}/_mdc/shared/"*.mdc; do
  [[ -f "$f" ]] || continue
  rel="${f#"${CURSOR_CONFIG_ROOT}"/_mdc/}"
  grep -Fq "](../_mdc/${rel})" "${CURSOR_CONFIG_ROOT}/rules/shared.mdc" || die "rules/shared.mdc must link ../_mdc/${rel}"
done
cmds=()
while IFS= read -r f; do
  cmds+=("$f")
done < <(find "${CURSOR_CONFIG_ROOT}/commands" -maxdepth 1 -type f -name '*.md' | sort)
((${#cmds[@]} > 0)) || die "CURSOR_CONFIG_ROOT/commands should contain at least one .md"
catalog="${CURSOR_CONFIG_ROOT}/commands/commands.md"
[[ -f "$catalog" ]] || die "missing commands catalog ($catalog)"
for f in "${cmds[@]}"; do
  rel="${f#"${CURSOR_CONFIG_ROOT}"/commands/}"
  case "$rel" in
    commands.md) continue ;;
  esac
  if ! grep -Fq "](${rel})" "$catalog"; then
    die "commands.md must link each playbook; missing ](${rel})"
  fi
done
functions=()
while IFS= read -r f; do
  functions+=("$f")
done < <(find "${CURSOR_CONFIG_ROOT}/_functions" -type f -name '*.md' | sort)
((${#functions[@]} > 0)) || die "CURSOR_CONFIG_ROOT/_functions should contain at least one .md"
for f in "${functions[@]}"; do
  rel="${f#"${CURSOR_CONFIG_ROOT}"/_functions/}"
  if ! grep -Fq "](../_functions/${rel})" "$catalog"; then
    die "commands.md must link each private function; missing ](../_functions/${rel})"
  fi
done

echo "smoke-check: command catalog sync …"
CURSOR_CONFIG_ROOT="$CURSOR_CONFIG_ROOT" "$ROOT/tools/cursor/sync-commands-catalog.sh" --check

echo "smoke-check: role roster sync …"
CURSOR_CONFIG_ROOT="$CURSOR_CONFIG_ROOT" "$ROOT/tools/cursor/sync-roles-roster.sh" --check

echo "smoke-check: adapter sync …"
"$ROOT/tools/check-agent-adapters.sh"

echo "smoke-check: cursor content …"
CURSOR_CONFIG_ROOT="$CURSOR_CONFIG_ROOT" "$ROOT/tools/check-cursor-content.sh"

validate_project_dot_cursor
validate_runtime_projection

[[ -x "${ROOT}/link.sh" ]] || die "link.sh must be executable"
[[ -x "${ROOT}/tools/smoke-check.sh" ]] || die "tools/smoke-check.sh must be executable"
[[ -x "${ROOT}/tools/check-agent-adapters.sh" ]] || die "tools/check-agent-adapters.sh must be executable"
[[ -x "${ROOT}/tools/check-cursor-content.sh" ]] || die "tools/check-cursor-content.sh must be executable"
[[ -x "${ROOT}/tools/cursor/sync-commands-catalog.sh" ]] || die "tools/cursor/sync-commands-catalog.sh must be executable"
[[ -x "${ROOT}/tools/cursor/sync-roles-roster.sh" ]] || die "tools/cursor/sync-roles-roster.sh must be executable"
[[ -x "${ROOT}/tools/manual/manual-link-fallback.sh" ]] || die "tools/manual/manual-link-fallback.sh must be executable"
[[ -x "${ROOT}/launcher/setup-cursor-workspace-launcher.sh" ]] || die "launcher setup must be executable"

if command -v shellcheck >/dev/null 2>&1; then
  echo "smoke-check: shellcheck …"
  shellcheck -x "${ROOT}/link.sh" "${ROOT}/tools/smoke-check.sh" \
    "${ROOT}/tools/check-agent-adapters.sh" "${ROOT}/tools/check-cursor-content.sh" \
    "${ROOT}/tools/cursor/sync-commands-catalog.sh" "${ROOT}/tools/cursor/sync-roles-roster.sh" \
    "${ROOT}/tools/manual/manual-link-fallback.sh" \
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
