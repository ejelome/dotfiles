#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT}"
ROLES_DIR="${ROLES_DIR:-$CURSOR_CONFIG_ROOT/_roles}"

die() {
  echo "check-cursor-roles: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: ./tools/check-cursor-roles.sh [--roles-dir <path>]

Options:
  --roles-dir <path>  Validate a role catalog other than _roles.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --roles-dir)
      [[ $# -ge 2 ]] || die "--roles-dir requires a path"
      ROLES_DIR="$2"
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

python3 - "$ROLES_DIR" <<'PY'
import json
import pathlib
import sys

roles_dir = pathlib.Path(sys.argv[1])
required = ("key", "displayName", "concerns")


def die(message: str) -> None:
    raise SystemExit(f"check-cursor-roles: {message}")


if not roles_dir.is_dir():
    die(f"roles directory does not exist: {roles_dir}")

paths = sorted(roles_dir.glob("*.json"))
if not paths:
    die(f"no role JSON files found: {roles_dir}")

seen: dict[str, pathlib.Path] = {}
for path in paths:
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        die(f"{path}: invalid JSON: {exc}")

    if not isinstance(data, dict):
        die(f"{path}: role must be a JSON object")

    for field in required:
        if field not in data:
            die(f"{path}: missing required key: {field}")

    key = data["key"]
    if not isinstance(key, str) or not key.strip():
        die(f"{path}: key must be a non-empty string")
    if key != path.stem:
        die(f"{path}: key must match filename stem")
    if key in seen:
        die(f"{path}: duplicate key also declared by {seen[key]}")
    seen[key] = path

    if not isinstance(data["displayName"], str) or not data["displayName"].strip():
        die(f"{path}: displayName must be a non-empty string")

    concerns = data["concerns"]
    if not isinstance(concerns, list) or not concerns:
        die(f"{path}: concerns must be a non-empty array")
    if any(not isinstance(item, str) or not item.strip() for item in concerns):
        die(f"{path}: concerns must contain only non-empty strings")

    prohibitions = data.get("prohibitions")
    if prohibitions is not None:
        if not isinstance(prohibitions, list):
            die(f"{path}: prohibitions must be an array when present")
        if any(not isinstance(item, str) or not item.strip() for item in prohibitions):
            die(f"{path}: prohibitions must contain only non-empty strings")

print("check-cursor-roles: OK")
PY
