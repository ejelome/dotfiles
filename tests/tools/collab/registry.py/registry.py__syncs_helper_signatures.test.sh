#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

python3 - "$ROOT" <<'PY' || fail "registry helper: helper signatures must stay in sync with route-owned expectations"
import importlib.util
import sys
from pathlib import Path

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("collab_registry", root / "tools/collab/registry.py")
registry = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(registry)

parser = registry.build_parser()
subparser_action = next(
    action for action in parser._actions
    if getattr(action, "choices", None)
)
choices = subparser_action.choices

expected_subcommands = {
    "advance",
    "archive",
    "close",
    "delete",
    "execution",
    "flag-inventory",
    "join-participants",
    "retract-speak",
    "set",
    "speak-render",
    "unset",
}
assert expected_subcommands.issubset(set(choices)), sorted(expected_subcommands - set(choices))


def option_dests(command):
    return {
        option
        for action in choices[command]._actions
        for option in action.option_strings
    }


def required_positionals(command):
    return [
        action.dest
        for action in choices[command]._actions
        if not action.option_strings and action.dest != "help"
    ]


assert required_positionals("join-participants") == ["target", "role"]
assert {"--agent-id", "--roles-dir", "--json"}.issubset(option_dests("join-participants"))

assert required_positionals("speak-render") == ["target", "role"]
assert {"--content-file", "--observed-revision", "--timestamp", "--json", "--caller-role", "--verbatim"}.issubset(option_dests("speak-render"))

assert required_positionals("execution") == ["target", "role", "status", "date"]
assert {"--assigned-role", "--auto-close", "--validation-result", "--validation-scope", "--touched-path", "--caller-role"}.issubset(option_dests("execution"))

for command in ("advance", "archive", "close", "delete", "set", "unset"):
    assert "--caller-role" in option_dests(command), command
PY

echo "PASS: collab helper signatures expose required args, flags, and caller-role gates"
