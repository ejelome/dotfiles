#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

python3 - "$ROOT/cursor/_roles" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
expected = {"tw", "pe", "pa", "mod"}
actual = {path.stem for path in root.glob("*.json")}
if actual != expected:
    raise SystemExit(f"role roster drift: expected {sorted(expected)}, got {sorted(actual)}")

seen = {}
for path in sorted(root.glob("*.json")):
    data = json.loads(path.read_text())
    if "display_name" in data:
        raise SystemExit(f"{path}: display_name is not allowed; use displayName")
    if data.get("key") != path.stem:
        raise SystemExit(f"{path}: key must match filename")
    key = data["key"]
    if key in seen:
        raise SystemExit(f"{path}: duplicate key also declared by {seen[key]}")
    seen[key] = path
    if not isinstance(data.get("displayName"), str) or not data["displayName"].strip():
        raise SystemExit(f"{path}: displayName must be a non-empty string")
    concerns = data.get("concerns")
    if not isinstance(concerns, list) or not concerns:
        raise SystemExit(f"{path}: concerns must be a non-empty array")
    if any(not isinstance(item, str) or not item.strip() for item in concerns):
        raise SystemExit(f"{path}: concerns must contain only non-empty strings")
PY

python3 "$ROOT/tools/cursor/roles.py" --roles-dir "$ROOT/cursor/_roles" validate >/dev/null

mkdir -p "$tmp/duplicate"
cat >"$tmp/duplicate/pe.json" <<'JSON'
{
  "key": "pe",
  "displayName": "Platform Engineer",
  "concerns": ["effectiveness"]
}
JSON
cat >"$tmp/duplicate/platform.json" <<'JSON'
{
  "key": "pe",
  "displayName": "Platform Engineer",
  "concerns": ["effectiveness"]
}
JSON
if python3 "$ROOT/tools/cursor/roles.py" --roles-dir "$tmp/duplicate" validate >/dev/null 2>&1; then
  echo "FAIL: role helper must reject duplicate or mismatched keys" >&2
  exit 1
fi

mkdir -p "$tmp/invalid-json"
printf '{' >"$tmp/invalid-json/pe.json"
if python3 "$ROOT/tools/cursor/roles.py" --roles-dir "$tmp/invalid-json" validate >/dev/null 2>&1; then
  echo "FAIL: role helper must reject invalid JSON" >&2
  exit 1
fi

echo "PASS: role JSON files match the shared role contract"
