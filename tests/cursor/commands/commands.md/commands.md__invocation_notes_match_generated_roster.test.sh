#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/commands/commands.md"

python3 - "$file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

begin = "<!-- BEGIN GENERATED:COMMANDS_ROSTER -->"
end = "<!-- END GENERATED:COMMANDS_ROSTER -->"

if text.count(begin) != 1 or text.count(end) != 1:
    raise SystemExit("commands.md: generated roster markers must appear exactly once")

block = text.split(begin, 1)[1].split(end, 1)[0].strip()
if not re.search(r"^\| `", block, re.M):
    raise SystemExit("commands.md: generated roster block must not be empty")

# The contract is substring match; tightening to exact-match is a fresh collab.
# Reference-only routes are covered by explicit marker assertion on the
# `(reference only — not an invocable route)` text.
if "(reference only — not an invocable route)" not in block:
    raise SystemExit("commands.md: generated roster must explicitly mark reference-only routes")

notes_match = re.search(
    r"\*\*Invocation notes by command:\*\*\n\n(?P<body>.*?)(?:\n\*\*Related principal workflows:\*\*)",
    text,
    re.S,
)
if not notes_match:
    raise SystemExit("commands.md: missing invocation notes block")

notes = re.findall(r"^- \*\*`([^`]+)`\*\*", notes_match.group("body"), re.M)
if not notes:
    raise SystemExit("commands.md: invocation notes block must not be empty")

row_values = []
for line in block.splitlines():
    if not line.startswith("| `"):
        continue
    cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
    row_values.append((line, cells[0].strip("`")))

def table_escape(value: str) -> str:
    return value.replace("|", r"\|")

def route_prefix(note: str) -> str:
    stripped = re.sub(r"\s+<.*$", "", note)
    stripped = re.sub(r"\s+\.\.\.$", "", stripped)
    return stripped

missing = []
for note in notes:
    candidates = [table_escape(note), table_escape(route_prefix(note))]
    if not any(candidate and candidate in row for candidate in candidates for row, _ in row_values):
        missing.append(note)

if missing:
    raise SystemExit(
        "commands.md: invocation note signature missing from generated roster row: "
        + ", ".join(missing)
    )
PY

echo "PASS: commands.md invocation notes match generated roster"
