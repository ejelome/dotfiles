#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

output="$(CURSOR_CONFIG_ROOT="$ROOT/cursor" "$ROOT/tools/cursor/command-reference.py" --check 2>&1)"

assert_contains "$output" "command-reference: OK"
artifact="$(cat "$ROOT/cursor/_generated/command-reference.md")"
assert_contains "$artifact" '  `--role`    required    dynamic: `role keys from _roles/`'
assert_contains "$artifact" '  `--reviewer`    optional    dynamic: `role keys from _roles/`'
if grep -Fq 'literal: `mod | pa | pe | tw`' "$ROOT/cursor/_generated/command-reference.md"; then
  fail "command-reference: role sourced params must render as dynamic role keys"
fi

python3 - "$ROOT" <<'PY' || fail "command-reference: role sourced params must resolve through registry roles"
import importlib.util
import os
from pathlib import Path
import sys

root = Path(sys.argv[1])
os.environ["CURSOR_CONFIG_ROOT"] = str(root / "cursor")
spec = importlib.util.spec_from_file_location("command_reference", root / "tools/cursor/command-reference.py")
command_reference = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = command_reference
spec.loader.exec_module(command_reference)
route = next(route for route in command_reference.load_routes() if route.path.name == "join.md")
role_param = next(param for param in route.params if param.name == "--role")
assert role_param.value_class == "dynamic"
assert role_param.detail == "role keys from _roles/"
PY

echo "PASS: command-reference check passes when artifact is fresh"
