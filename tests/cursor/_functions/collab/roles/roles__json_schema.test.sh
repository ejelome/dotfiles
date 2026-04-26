#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"

python3 - "$ROOT/cursor/_functions/collab/roles" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
expected = {"tw", "pe", "mod"}
actual = {path.stem for path in root.glob("*.json")}
if actual != expected:
    raise SystemExit(f"role roster drift: expected {sorted(expected)}, got {sorted(actual)}")

for path in sorted(root.glob("*.json")):
    data = json.loads(path.read_text())
    if data.get("acronym") != path.stem:
        raise SystemExit(f"{path}: acronym must match filename")
    if not isinstance(data.get("display_name"), str) or not data["display_name"].strip():
        raise SystemExit(f"{path}: display_name must be a non-empty string")
    concerns = data.get("concerns")
    if not isinstance(concerns, list) or not concerns:
        raise SystemExit(f"{path}: concerns must be a non-empty array")
    if any(not isinstance(item, str) or not item.strip() for item in concerns):
        raise SystemExit(f"{path}: concerns must contain only non-empty strings")
PY

echo "PASS: collab role JSON files match the join schema"
