#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

registry="$tmpdir/registry.json"
cat >"$registry" <<'JSON'
{
  "schema_version": 1,
  "active_collab_id": "alpha-2026-04-27",
  "collabs": [
    {
      "id": "alpha-2026-04-27",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "active_phase": "Discussion",
      "moderator_role": "mod",
      "participants": ["tw", "pe", "mod"],
      "turn_order": ["tw", "pe"],
      "transcript_path": ".collabs/records/alpha-2026-04-27.md",
      "created_on": "2026-04-27",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON

python3 "$ROOT/tools/collab/registry.py" --registry "$registry" validate >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha title "alpha updated" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha turn-order "pe tw" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" advance alpha prev >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" use alpha >/dev/null

python3 - "$registry" <<'PY' || fail "registry helper: expected successful mutations to persist"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["active_collab_id"] == "alpha-2026-04-27"
assert entry["title"] == "alpha updated"
assert entry["turn_order"] == ["pe", "tw"]
assert entry["active_phase"] == "Audit"
PY

! python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha status closed >/dev/null 2>&1 || fail "registry helper: status must not be settable without a dedicated route"
! python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha active-phase Completion >/dev/null 2>&1 || fail "registry helper: active-phase must require --force"

dup_registry="$tmpdir/duplicate.json"
cp "$registry" "$dup_registry"
python3 - "$dup_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
entry = dict(data["collabs"][0])
entry["id"] = "beta-2026-04-27"
entry["slug"] = "alpha"
data["collabs"].append(entry)
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$dup_registry" validate >/dev/null 2>&1 || fail "registry helper: duplicate slug validation must fail"

active_registry="$tmpdir/invalid-active.json"
cp "$registry" "$active_registry"
python3 - "$active_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["active_collab_id"] = "missing"
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$active_registry" validate >/dev/null 2>&1 || fail "registry helper: invalid active pointer must fail"

turn_registry="$tmpdir/invalid-turn.json"
cp "$registry" "$turn_registry"
python3 - "$turn_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["turn_order"] = ["pe", "ghost"]
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$turn_registry" validate >/dev/null 2>&1 || fail "registry helper: turn-order participant mismatch must fail"

archive_registry="$tmpdir/archive.json"
cp "$registry" "$archive_registry"
python3 "$ROOT/tools/collab/registry.py" --registry "$archive_registry" archive alpha >/dev/null
python3 - "$archive_registry" <<'PY' || fail "registry helper: soft archive must clear active pointer and preserve registry entry"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["active_collab_id"] is None
assert entry["status"] == "archived"
assert entry["archived"] is True
PY

echo "PASS: registry helper validates registry-backed collab flows"
