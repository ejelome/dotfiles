"""Remove stale Dock tiles for the Cursor workspace launcher app; plist is rewritten only."""
from __future__ import annotations

import pathlib
import plistlib
import sys
from typing import Optional
from urllib.parse import unquote, urlparse


def normalize_entry_path(raw: str) -> Optional[pathlib.Path]:
    if not raw:
        return None
    if raw.startswith("file://"):
        parsed = urlparse(raw)
        if parsed.scheme != "file":
            return None
        raw = unquote(parsed.path)
    return pathlib.Path(raw).expanduser().resolve()


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: dock_update.py <app_bundle_path>", file=sys.stderr)
        return 2

    app_path = pathlib.Path(sys.argv[1]).expanduser().resolve()
    app_name = app_path.name

    plist_path = pathlib.Path.home() / "Library/Preferences/com.apple.dock.plist"
    with plist_path.open("rb") as f:
        data = plistlib.load(f)

    persistent_apps = data.get("persistent-apps", [])
    filtered_apps = []
    for app in persistent_apps:
        tile_data = app.get("tile-data", {})
        file_data = tile_data.get("file-data", {})
        url = file_data.get("_CFURLString", "")
        label = tile_data.get("file-label", "")
        entry_path = normalize_entry_path(url)
        if entry_path is not None and entry_path == app_path:
            continue
        if label == app_name.removesuffix(".app"):
            continue
        if not url:
            filtered_apps.append(app)
            continue
        if entry_path != app_path:
            filtered_apps.append(app)

    data["persistent-apps"] = filtered_apps
    with plist_path.open("wb") as f:
        plistlib.dump(data, f)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
