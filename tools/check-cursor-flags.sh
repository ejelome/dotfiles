#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT/cursor}"

die() {
  echo "check-cursor-flags: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: ./tools/check-cursor-flags.sh [--cursor-config-root <path>]

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
required_routes = {
    "agent/install.md": ("eligible", "hard-abort"),
    "agent/patch.md": ("eligible", "gated-overwrite"),
    "agent/upgrade.md": ("eligible", "gated-overwrite"),
    "doc/compact.md": ("ineligible", "output-mode-policy"),
    "collab/init.md": ("ineligible", "registry-integrity"),
}
required_fields = ("flag", "eligibility", "guard-class")
allowed_flags = {"force"}
allowed_eligibility = {"eligible", "ineligible"}
eligible_guard_classes = {"hard-abort", "gated-overwrite"}
ineligible_guard_classes = {
    "registry-integrity",
    "output-mode-policy",
    "lifecycle-gate",
    "role-gate",
    "schema-validation",
    "unreadable-context",
    "destructive-delete",
}
allowed_guard_classes = eligible_guard_classes | ineligible_guard_classes
canonical_phrase = "the candidate patch"
failures: list[str] = []


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(cursor_root.parent))
    except ValueError:
        return str(path)


def route_rel(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(functions_dir))
    except ValueError:
        return str(path)


def add_failure(path: pathlib.Path, field: str, reason: str) -> None:
    failures.append(f"{rel(path)}: {field}: {reason}")


def cursor_flag_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    lines = text.splitlines()
    in_block = False
    fence = ""
    body: list[str] = []

    for line in lines:
        opener = re.match(r"^\s*(`{3,}|~{3,})cursor-flag\s*$", line)
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
    raise SystemExit(f"check-cursor-flags: Cursor config root does not exist: {cursor_root}")
if not functions_dir.is_dir():
    raise SystemExit(f"check-cursor-flags: functions directory does not exist: {functions_dir}")

seen_required: dict[str, dict[str, str]] = {}

for path in sorted(functions_dir.rglob("*.md")):
    text = path.read_text()
    blocks = cursor_flag_blocks(text)
    if not blocks:
        continue

    if "cursor/_core/command-argument.md" not in text and "_core/command-argument.md" not in text:
        add_failure(path, "flag-contract", "missing cursor/_core/command-argument.md citation")

    seen_flags: set[str] = set()
    parsed_blocks: list[dict[str, str]] = []
    for block in blocks:
        data = parse_block(path, block)
        parsed_blocks.append(data)

        for field in required_fields:
            if field not in data:
                add_failure(path, field, "missing required field")
            elif not data[field].strip():
                add_failure(path, field, "empty required field")

        if any(field not in data for field in required_fields):
            continue

        flag = data["flag"]
        eligibility = data["eligibility"]
        guard_class = data["guard-class"]

        if flag in seen_flags:
            add_failure(path, "flag", f"duplicate cursor-flag block for {flag}")
        seen_flags.add(flag)

        if flag not in allowed_flags:
            add_failure(path, "flag", "unknown flag")
        if eligibility not in allowed_eligibility:
            add_failure(path, "eligibility", "must be eligible or ineligible")
        if guard_class not in allowed_guard_classes:
            add_failure(path, "guard-class", "unknown guard class")

        if eligibility == "eligible" and guard_class in ineligible_guard_classes:
            add_failure(path, "guard-class", "eligible force blocks cannot use an ineligible guard class")
        if eligibility == "ineligible":
            reason = data.get("ineligibility-reason", "").strip()
            if not reason:
                add_failure(path, "ineligibility-reason", "missing required field for ineligible flag")
        elif "ineligibility-reason" in data and data["ineligibility-reason"].strip():
            add_failure(path, "ineligibility-reason", "must be absent for eligible flag")

        if flag == "force" and eligibility == "eligible":
            phrase_count = text.count(canonical_phrase)
            if phrase_count < 2:
                add_failure(path, "canonical-phrase", f"eligible force routes must mention `{canonical_phrase}` at least twice")
            alternate_patch_names = sorted(
                {
                    match.group(0)
                    for match in re.finditer(r"\bthe [a-z][a-z-]* patch\b", text)
                    if match.group(0) != canonical_phrase
                }
            )
            if alternate_patch_names:
                add_failure(path, "patch-reference", f"non-canonical patch reference(s): {', '.join(alternate_patch_names)}")

    req_key = route_rel(path)
    if req_key in required_routes:
        force_blocks = [data for data in parsed_blocks if data.get("flag") == "force"]
        if len(force_blocks) == 1:
            seen_required[req_key] = force_blocks[0]

for req_key, (expected_eligibility, expected_guard_class) in required_routes.items():
    path = functions_dir / req_key
    data = seen_required.get(req_key)
    if data is None:
        add_failure(path, "cursor-flag", "missing required first-batch force declaration")
        continue
    if data.get("eligibility") != expected_eligibility:
        add_failure(path, "eligibility", f"expected {expected_eligibility}")
    if data.get("guard-class") != expected_guard_class:
        add_failure(path, "guard-class", f"expected {expected_guard_class}")

if failures:
    print("check-cursor-flags: FAIL", file=sys.stderr)
    for failure in failures:
        print(f"check-cursor-flags: {failure}", file=sys.stderr)
    raise SystemExit(1)

print("check-cursor-flags: OK")
PY
