#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cfg="$tmp/cursor-root"
mkdir -p "$cfg"
cp -R "$ROOT/cursor"/. "$cfg/"
[[ ! -e "$cfg/cursor" ]] || fail "root-layout fixture must not contain a nested cursor/ directory"

CURSOR_CONFIG_ROOT="$cfg" "$ROOT/tools/cursor/sync-commands-catalog.sh" --check >/dev/null
CURSOR_CONFIG_ROOT="$cfg" "$ROOT/tools/cursor/command-reference.py" --check >/dev/null
CURSOR_CONFIG_ROOT="$cfg" "$ROOT/tools/cursor/sync-framework-boundaries.sh" --check >/dev/null
CURSOR_CONFIG_ROOT="$cfg" "$ROOT/tools/cursor/sync-roles-roster.sh" --check >/dev/null
CURSOR_CONFIG_ROOT="$cfg" "$ROOT/tools/collab/registry.py" roles >/dev/null

repo="$tmp/repo"
mkdir -p "$repo"
CURSOR_CONFIG_ROOT="$cfg" python3 "$ROOT/tools/narrative/state.py" audit \
  --repo-root "$repo" \
  --state "$tmp/narrative.json" \
  --role pe >/dev/null
CURSOR_CONFIG_ROOT="$cfg" python3 "$ROOT/tools/narrative/state.py" validate "$tmp/narrative.json" >/dev/null

echo "PASS: Cursor helpers validate root layout without nested cursor directory"
