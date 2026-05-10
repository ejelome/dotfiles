#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"

python3 - "$ROOT/cursor/_settings/settings.json" <<'PY'
import json
import sys

settings_path = sys.argv[1]
with open(settings_path, encoding="utf-8") as handle:
    settings = json.load(handle)

expected_title = "${process}"
actual_title = settings.get("terminal.integrated.tabs.title")
if actual_title != expected_title:
    raise SystemExit(
        "FAIL: terminal tab title should be "
        f"{expected_title!r}, got {actual_title!r}"
    )

actual_description = settings.get("terminal.integrated.tabs.description")
if actual_description != "":
    raise SystemExit(
        "FAIL: terminal tab description should be blank, "
        f"got {actual_description!r}"
    )
PY

echo "PASS: Cursor terminal tabs omit workspace-derived titles"
