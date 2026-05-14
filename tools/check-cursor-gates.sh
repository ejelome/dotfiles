#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT}"

die() {
  echo "check-cursor-gates: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: ./tools/check-cursor-gates.sh [--cursor-config-root <path>]

Options:
  --cursor-config-root <path>  Validate a Cursor source tree other than ./cursor.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cursor-config-root)
      [[ $# -ge 2 ]] || die "--cursor-config-root requires a path"
      CURSOR_CONFIG_ROOT="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

python3 - "$CURSOR_CONFIG_ROOT" <<'PY'
import pathlib
import re
import sys

cursor_root = pathlib.Path(sys.argv[1])
functions_dir = cursor_root / "_functions"
required_fields = (
    "gate-class",
    "proceed",
    "abort",
    "operand-format",
    "invalid-input",
    "re-prompt-template",
)
allowed_classes = {"standard", "destructive"}
destructive_verbs = {"delete", "archive", "kick", "purge", "reset", "overwrite"}
failures: list[str] = []


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(cursor_root.parent))
    except ValueError:
        return str(path)


def add_failure(path: pathlib.Path, field: str, reason: str) -> None:
    failures.append(f"{rel(path)}: {field}: {reason}")


def cursor_gate_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    lines = text.splitlines()
    in_block = False
    fence = ""
    body: list[str] = []

    for line in lines:
        opener = re.match(r"^\s*(`{3,}|~{3,})cursor-gate\s*$", line)
        if not in_block and opener:
            in_block = True
            fence = opener.group(1)
            body = []
            continue

        if in_block:
            closer = re.match(rf"^\s*{re.escape(fence)}\s*$", line)
            if closer:
                blocks.append("\n".join(body))
                in_block = False
                fence = ""
                body = []
                continue
            body.append(line.strip())

    if in_block:
        blocks.append("\n".join(body))

    return blocks


def parse_block(path: pathlib.Path, block: str) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw_line in block.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if ":" not in line:
            add_failure(path, "block", f"malformed line: {line}")
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if key in data:
            add_failure(path, key, "duplicate field")
        data[key] = value
    return data


if not cursor_root.is_dir():
    raise SystemExit(f"check-cursor-gates: Cursor config root does not exist: {cursor_root}")
if not functions_dir.is_dir():
    raise SystemExit(f"check-cursor-gates: functions directory does not exist: {functions_dir}")

gate_files = 0
for path in sorted(functions_dir.rglob("*.md")):
    text = path.read_text()
    blocks = cursor_gate_blocks(text)
    cites_argument_contract = "cursor/_core/command-argument.md" in text or "_core/command-argument.md" in text
    cites_gate_contract = cites_argument_contract and (
        "Gate contract:" in text
        or re.search(r"\bgate\b.{0,80}_core/command-argument\.md", text, re.IGNORECASE)
        or re.search(r"_core/command-argument\.md.{0,80}\bgate\b", text, re.IGNORECASE)
    )

    if not blocks and not cites_gate_contract:
        continue

    gate_files += 1
    if not cites_argument_contract:
        add_failure(path, "gate-contract", "missing cursor/_core/command-argument.md citation")
    if len(blocks) != 1:
        add_failure(path, "cursor-gate", f"expected exactly one block, found {len(blocks)}")
        continue

    data = parse_block(path, blocks[0])
    for field in required_fields:
        if field not in data:
            add_failure(path, field, "missing required field")
        elif not data[field].strip():
            add_failure(path, field, "empty required field")

    if any(field not in data for field in required_fields):
        continue

    gate_class = data["gate-class"]
    proceed = data["proceed"]
    abort = data["abort"]
    operand_format = data["operand-format"]
    invalid_input = data["invalid-input"]
    proceed_verb = proceed.split(maxsplit=1)[0] if proceed else ""

    if gate_class not in allowed_classes:
        add_failure(path, "gate-class", "must be standard or destructive")
    if abort != "cancel":
        add_failure(path, "abort", "must be cancel")
    if invalid_input != "re-prompt":
        add_failure(path, "invalid-input", "must be re-prompt")

    if gate_class == "standard":
        if proceed != "confirm":
            add_failure(path, "proceed", "standard gates must use confirm")
        if operand_format != "none":
            add_failure(path, "operand-format", "standard gates must use none")
    elif gate_class == "destructive":
        if proceed_verb not in destructive_verbs:
            add_failure(path, "proceed", "destructive proceed verb is not in the closed set")
        if proceed == proceed_verb:
            add_failure(path, "proceed", "destructive gates require an operand")
        if operand_format == "none":
            add_failure(path, "operand-format", "destructive gates require a non-none operand description")

if gate_files == 0:
    failures.append(f"{rel(functions_dir)}: cursor-gate: no gate declarations found")

if failures:
    print("check-cursor-gates: FAIL", file=sys.stderr)
    for failure in failures:
        print(f"check-cursor-gates: {failure}", file=sys.stderr)
    raise SystemExit(1)

print("check-cursor-gates: OK")
PY
