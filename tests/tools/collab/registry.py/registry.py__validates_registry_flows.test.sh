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
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Discussion",
      "moderatorRole": "mod",
      "participants": [
        {"role": "tw", "agentId": ""},
        {"role": "pe", "agentId": ""},
        {"role": "mod", "agentId": ""}
      ],
      "turnOrder": ["tw", "pe"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "createdOn": "2026-04-27",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON

python3 "$ROOT/tools/collab/registry.py" --registry "$registry" validate >/dev/null
timestamp="$(python3 "$ROOT/tools/collab/registry.py" timestamp)"
[[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}\ [+-][0-9]{2}:[0-9]{2}$ ]] || fail "registry helper: timestamp format must be YYYY-MM-DD HH:MM ±HH:MM"
role_row="$(python3 "$ROOT/tools/collab/registry.py" role-row pe --roles-dir "$ROOT/cursor/_roles")"
[[ "$role_row" == "| 1 | pe | Platform Engineer |  | effectiveness; efficiency; completeness; optimization |" ]] || fail "registry helper: role row must match catalog shape (Agent from registry only elsewhere)"
pa_role_row="$(python3 "$ROOT/tools/collab/registry.py" role-row pa --roles-dir "$ROOT/cursor/_roles" --index 4)"
[[ "$pa_role_row" == "| 4 | pa | Principal Architect |  | depth; coherence; judgment; risk |" ]] || fail "registry helper: pa role row must match agreed concerns"
roles_list="$(python3 "$ROOT/tools/collab/registry.py" roles --roles-dir "$ROOT/cursor/_roles")"
grep -Fq '| 3 | pe | Platform Engineer |  | effectiveness; efficiency; completeness; optimization |' <<<"$roles_list" || fail "registry helper: roles catalog must list pe"
grep -Fq '| 4 | tw | Technical Writer |  | clarity; conciseness; accuracy; developer experience |' <<<"$roles_list" || fail "registry helper: roles catalog must list tw"
[[ "$(python3 "$ROOT/tools/collab/registry.py" summary-role '<summary>pe</summary>')" == "pe" ]] || fail "registry helper: summary parser must accept key-only summary"
[[ "$(python3 "$ROOT/tools/collab/registry.py" summary-role '<summary>pe — Platform Engineer</summary>')" == "pe" ]] || fail "registry helper: summary parser must accept legacy summary"

shorthand_registry="$tmpdir/shorthand.json"
cp "$registry" "$shorthand_registry"
python3 - "$shorthand_registry" <<'PY'
import copy
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
beta = copy.deepcopy(data["collabs"][0])
beta["id"] = "2026-04-27-beta"
beta["slug"] = "beta"
beta["title"] = "beta"
beta["description"] = "beta collab"
beta["transcriptPath"] = ".collabs/records/2026-04-27-beta.md"
data["collabs"].append(beta)
data["activeCollabId"] = "2026-04-27-beta"
json.dump(data, open(path, "w"))
PY
shorthand_list="$(python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" list)"
grep -Fq '[ ] #1 - alpha    alpha' <<<"$shorthand_list" || fail "registry helper: list must preserve stable numeric selector for inactive collab"
grep -Fq '[*] #2 - beta    beta' <<<"$shorthand_list" || fail "registry helper: list must prefix active collab with active marker"
grep -Fq 'open · Discussion · 3 participants · 2026-04-27' <<<"$shorthand_list" || fail "registry helper: list must include status, phase, participants, and date"
status_list="$(python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" list --status open)"
grep -Fq '[*] #2 - beta    beta' <<<"$status_list" || fail "registry helper: status filter must include matching collabs"
! python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" list --status missing >/dev/null 2>&1 || fail "registry helper: invalid status filter must fail"
python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" set 2 title "beta updated" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" use 1 >/dev/null
python3 - "$shorthand_registry" <<'PY' || fail "registry helper: numeric shorthand must resolve registry array positions"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["activeCollabId"] == "2026-04-27-alpha"
assert data["collabs"][1]["title"] == "beta updated"
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$shorthand_registry" use 3 >/dev/null 2>&1 || fail "registry helper: numeric shorthand outside registry array must fail"

python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha title "alpha updated" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha turn-order "pe tw" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" advance alpha prev >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" use alpha >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" participant alpha ux >/dev/null 2>"$tmpdir/participant-warning.txt"
grep -Fq 'warning: participant is deprecated; use join-participants so transcript metadata is rendered' "$tmpdir/participant-warning.txt" || fail "registry helper: participant subcommand must warn about deprecation"
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha turn-order "mod tw pe" >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" set alpha active-phase Discussion --force >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" speak-lifecycle alpha mod tw pe >/dev/null

python3 - "$registry" <<'PY' || fail "registry helper: expected successful mutations to persist"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["activeCollabId"] == "2026-04-27-alpha"
assert entry["title"] == "alpha updated"
assert [p["role"] for p in entry["participants"]] == ["tw", "pe", "mod", "ux"]
assert entry["turnOrder"] == ["mod", "tw", "pe"]
assert entry["activePhase"] == "Discussion"
PY

python3 "$ROOT/tools/collab/registry.py" --registry "$registry" advance alpha next >/dev/null
python3 - "$registry" <<'PY' || fail "registry helper: manual advance to Conclusion must remove moderator from turn order"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["turnOrder"] == ["tw", "pe"]
assert entry["activePhase"] == "Conclusion"
PY

one_speak_registry="$tmpdir/one-speak.json"
cp "$registry" "$one_speak_registry"
! python3 "$ROOT/tools/collab/registry.py" --registry "$one_speak_registry" speak-lifecycle alpha tw tw pe >/dev/null 2>&1 || fail "registry helper: one-speak phases must reject duplicate role contributions"
python3 "$ROOT/tools/collab/registry.py" --registry "$registry" speak-lifecycle alpha tw pe >/dev/null
python3 - "$registry" <<'PY' || fail "registry helper: completed one-speak phase must auto-advance"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["activePhase"] == "Action Plan"
assert "mod" not in entry["turnOrder"]
PY

python3 "$ROOT/tools/collab/registry.py" --registry "$registry" advance alpha next >/dev/null
python3 - "$registry" <<'PY' || fail "registry helper: manual advance to Handoff must not re-add moderator to turn order"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["activePhase"] == "Handoff"
assert "mod" not in entry["turnOrder"]
PY

mod_leak_registry="$tmpdir/mod-leak.json"
cp "$registry" "$mod_leak_registry"
python3 - "$mod_leak_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
entry = data["collabs"][0]
entry["activePhase"] = "Conclusion"
entry["turnOrder"] = ["mod", "tw", "pe"]
json.dump(data, open(path, "w"))
PY
python3 "$ROOT/tools/collab/registry.py" --registry "$mod_leak_registry" advance alpha next >/dev/null
python3 - "$mod_leak_registry" <<'PY' || fail "registry helper: manual advance to Action Plan must strip leaked moderator from turn order"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["activePhase"] == "Action Plan"
assert "mod" not in entry["turnOrder"]
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
entry["id"] = "2026-04-27-beta"
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
data["activeCollabId"] = "missing"
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
data["collabs"][0]["turnOrder"] = ["pe", "ghost"]
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$turn_registry" validate >/dev/null 2>&1 || fail "registry helper: turn-order participant mismatch must fail"

reviewer_registry="$tmpdir/reviewer.json"
cat >"$reviewer_registry" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Audit",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": ""},
        {"role": "tw", "agentId": ""},
        {"role": "pe", "agentId": ""},
        {"role": "pa", "agentId": ""}
      ],
      "turnOrder": ["mod", "tw", "pe"],
      "reviewerRole": "pa",
      "reviewerMode": "last-in-convergent-phases",
      "reviewerOptionalPhases": ["Discussion"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "createdOn": "2026-04-27",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_registry" validate >/dev/null
! python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_registry" set alpha turn-order "tw pa" >/dev/null 2>&1 || fail "registry helper: turn-order must reject reviewerRole"
python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_registry" set alpha reviewer --clear >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_registry" set alpha reviewer pa >/dev/null
python3 - "$reviewer_registry" <<'PY' || fail "registry helper: set reviewer must persist reviewer metadata"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["reviewerRole"] == "pa"
assert entry["reviewerMode"] == "last-in-convergent-phases"
assert entry["reviewerOptionalPhases"] == ["Discussion"]
PY
unset_reviewer_root="$tmpdir/unset-reviewer"
mkdir -p "$unset_reviewer_root/.collabs/records"
cp "$reviewer_registry" "$unset_reviewer_root/.collabs/registry.json"
cat >"$unset_reviewer_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | mod, tw, pe | pa |

**Reviewer**

**pa** — registered in **Participants** and active as the convergent-phase reviewer per `.collabs/registry.json` (`reviewerMode: last-in-convergent-phases`). Reviewer gating is now in effect for convergent phases.

---

## Audit
MD
(cd "$unset_reviewer_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json unset alpha reviewer --roles-dir "$ROOT/cursor/_roles" >/dev/null)
python3 - "$unset_reviewer_root/.collabs/registry.json" <<'PY' || fail "registry helper: unset reviewer must remove reviewer metadata"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert "reviewerRole" not in entry
assert "reviewerMode" not in entry
assert "reviewerOptionalPhases" not in entry
PY
grep -Fq '| open | Audit | mod, tw, pe | — |' "$unset_reviewer_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: unset reviewer must render status without reviewer"
grep -Fxq '—' "$unset_reviewer_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: unset reviewer must clear reviewer section"
(cd "$unset_reviewer_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json unset alpha reviewer --roles-dir "$ROOT/cursor/_roles" >/dev/null)
python3 - "$unset_reviewer_root/.collabs/registry.json" <<'PY' || fail "registry helper: unset reviewer must be idempotent when reviewer is absent"
import json
import sys
entry = json.load(open(sys.argv[1]))["collabs"][0]
assert "reviewerRole" not in entry
PY
! (cd "$unset_reviewer_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json unset alpha title >/dev/null 2>&1) || fail "registry helper: unset must reject fields beyond reviewer in this pass"

deferred_reviewer_registry="$tmpdir/deferred-reviewer.json"
cat >"$deferred_reviewer_registry" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Audit",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": ""},
        {"role": "tw", "agentId": ""}
      ],
      "turnOrder": ["mod", "tw"],
      "reviewerRole": "pa",
      "reviewerMode": "last-in-convergent-phases",
      "reviewerOptionalPhases": ["Discussion"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "createdOn": "2026-04-27",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
python3 "$ROOT/tools/collab/registry.py" --registry "$deferred_reviewer_registry" validate >/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$deferred_reviewer_registry" reviewer-state alpha >"$tmpdir/deferred-reviewer-state.json"
python3 - "$tmpdir/deferred-reviewer-state.json" <<'PY' || fail "registry helper: pending reviewer state must be registry-owned"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state == {"reviewerRole": "pa", "state": "pending"}
PY
pending_reviewer_live="$tmpdir/pending-reviewer-live"
mkdir -p "$pending_reviewer_live/.collabs/records"
cp "$deferred_reviewer_registry" "$pending_reviewer_live/.collabs/registry.json"
cat >"$pending_reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Audit
MD
pending_reviewer_reject="$({ cd "$pending_reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha mod; } 2>&1 || true)"
[[ "$pending_reviewer_reject" == "pending reviewerRole: pa" ]] || fail "registry helper: speak-state must abort while reviewerRole is pending"
[[ "$(python3 "$ROOT/tools/collab/registry.py" --registry "$deferred_reviewer_registry" speak-lifecycle alpha mod tw)" == "Discussion" ]] || fail "registry helper: deferred reviewer must not block lifecycle before joining"
python3 "$ROOT/tools/collab/registry.py" --registry "$deferred_reviewer_registry" participant alpha pa >/dev/null 2>/dev/null
python3 "$ROOT/tools/collab/registry.py" --registry "$deferred_reviewer_registry" reviewer-state alpha >"$tmpdir/active-reviewer-state.json"
python3 - "$tmpdir/active-reviewer-state.json" <<'PY' || fail "registry helper: active reviewer state must be registry-owned"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state == {"reviewerRole": "pa", "state": "active"}
PY
python3 - "$deferred_reviewer_registry" <<'PY' || fail "registry helper: joining deferred reviewer must not add reviewer to ordinary turn order"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert entry["reviewerRole"] == "pa"
assert [p["role"] for p in entry["participants"]] == ["mod", "tw", "pa"]
assert entry["turnOrder"] == ["mod", "tw"]
PY

invalid_reviewer_registry="$tmpdir/invalid-reviewer.json"
cp "$reviewer_registry" "$invalid_reviewer_registry"
python3 - "$invalid_reviewer_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["reviewerRole"] = "mod"
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$invalid_reviewer_registry" validate >/dev/null 2>&1 || fail "registry helper: reviewer must not equal moderator"

reviewer_turn_registry="$tmpdir/invalid-reviewer-turn.json"
cp "$reviewer_registry" "$reviewer_turn_registry"
python3 - "$reviewer_turn_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["turnOrder"] = ["mod", "tw", "pe", "pa"]
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_turn_registry" validate >/dev/null 2>&1 || fail "registry helper: reviewer must not be in ordinary turnOrder"

old_key_registry="$tmpdir/old-key.json"
cp "$registry" "$old_key_registry"
python3 - "$old_key_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["schema_version"] = data["schemaVersion"]
data["collabs"][0]["turn_order"] = data["collabs"][0]["turnOrder"]
json.dump(data, open(path, "w"))
PY
! python3 "$ROOT/tools/collab/registry.py" --registry "$old_key_registry" validate >/dev/null 2>&1 || fail "registry helper: old snake_case registry keys must fail"

bad_roles="$tmpdir/roles"
mkdir -p "$bad_roles"
cat >"$bad_roles/pe.json" <<'JSON'
{
  "key": "pe",
  "concerns": ["effectiveness"]
}
JSON
! python3 "$ROOT/tools/collab/registry.py" role-row pe --roles-dir "$bad_roles" >/dev/null 2>&1 || fail "registry helper: role row must reject invalid role JSON"

archive_registry="$tmpdir/archive.json"
cp "$registry" "$archive_registry"
python3 "$ROOT/tools/collab/registry.py" --registry "$archive_registry" archive alpha >/dev/null
python3 - "$archive_registry" <<'PY' || fail "registry helper: soft archive must clear active pointer and preserve registry entry"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["activeCollabId"] is None
assert entry["status"] == "archived"
assert entry["archived"] is True
PY

delete_root="$tmpdir/delete-root"
mkdir -p "$delete_root/.collabs/records"
delete_registry="$delete_root/.collabs/registry.json"
cp "$registry" "$delete_registry"
cat >"$delete_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha
MD
! (cd "$delete_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json delete alpha >/dev/null 2>&1) || fail "registry helper: hard delete must require confirmation"
(cd "$delete_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json delete alpha --yes >/dev/null)
python3 - "$delete_registry" "$delete_root/.collabs/records/2026-04-27-alpha.md" <<'PY' || fail "registry helper: confirmed hard delete must remove registry entry and transcript"
import json
import pathlib
import sys
registry_path, transcript_path = sys.argv[1:]
data = json.load(open(registry_path))
assert data["activeCollabId"] is None
assert data["collabs"] == []
assert not pathlib.Path(transcript_path).exists()
PY

execution_registry="$tmpdir/execution.json"
cp "$registry" "$execution_registry"
python3 "$ROOT/tools/collab/registry.py" --registry "$execution_registry" execution alpha tw completed 2026-04-28 --assigned-role tw --assigned-role pe --auto-close >/dev/null
python3 - "$execution_registry" <<'PY' || fail "registry helper: incomplete assigned execution must leave record open"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["activeCollabId"] == "2026-04-27-alpha"
assert entry["status"] == "open"
assert entry["execution"]["tw"]["status"] == "completed"
PY
python3 "$ROOT/tools/collab/registry.py" --registry "$execution_registry" execution alpha pe completed 2026-04-28 --assigned-role tw --assigned-role pe --auto-close >/dev/null
python3 - "$execution_registry" <<'PY' || fail "registry helper: all completed assigned execution must close record"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert data["activeCollabId"] is None
assert entry["status"] == "closed"
assert entry["execution"]["pe"]["status"] == "completed"
PY

live_root="$tmpdir/live-root"
mkdir -p "$live_root/.collabs/records"
live_registry="$live_root/.collabs/registry.json"
cat >"$live_registry" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Discussion",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": ""},
        {"role": "tw", "agentId": ""},
        {"role": "pe", "agentId": ""}
      ],
      "turnOrder": ["mod", "tw", "pe"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "createdOn": "2026-04-27",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
cat >"$live_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Discussion

<details>
<summary>mod</summary>
old loaded state
</details>
MD
stale_loaded="$(cat "$live_root/.collabs/records/2026-04-27-alpha.md")"
cat >"$live_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Discussion

<details>
<summary>mod</summary>
first
</details>

<details>
<summary>tw</summary>
second
</details>
MD
printf 'source sentinel\n' >"$live_root/source.txt"
(cd "$live_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pe >state.json)
python3 - "$live_root/state.json" <<'PY' || fail "registry helper: speak-state must resolve expected speaker from the live transcript"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["activePhase"] == "Discussion"
assert state["contributors"] == ["mod", "tw"]
assert state["expectedRole"] == "pe"
PY
[[ "$(cat "$live_root/source.txt")" == "source sentinel" ]] || fail "registry helper: speak-state must not edit source files outside .collabs"
! (cd "$live_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha tw >/dev/null 2>&1) || fail "registry helper: speak-state must reject a stale expected role"

nested_history_root="$tmpdir/nested-history"
mkdir -p "$nested_history_root/.collabs/records"
cp "$live_registry" "$nested_history_root/.collabs/registry.json"
cat >"$nested_history_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Discussion

<details>
<summary>mod</summary>
active

<details>
<summary>tw</summary>
prior revision must not count as live
</details>

</details>

<details>
<summary>tw</summary>
live
</details>
MD
(cd "$nested_history_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pe >nested-state.json)
python3 - "$nested_history_root/nested-state.json" <<'PY' || fail "registry helper: nested revision history must not count as live contributions"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["contributors"] == ["mod", "tw"]
assert state["expectedRole"] == "pe"
PY

python3 - "$live_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["activePhase"] = "Action Plan"
data["collabs"][0]["turnOrder"] = ["tw", "pe"]
json.dump(data, open(path, "w"))
PY
cat >"$live_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Action Plan

<details>
<summary>tw</summary>
one
</details>

<details>
<summary>pe</summary>
two
</details>
MD
(cd "$live_root" && [[ "$(python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-lifecycle-live alpha)" == "Handoff" ]]) || fail "registry helper: live lifecycle must auto-advance completed one-speak phases"
python3 - "$live_registry" <<'PY' || fail "registry helper: live lifecycle must persist helper-owned auto-advance"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["collabs"][0]["activePhase"] == "Handoff"
PY
python3 - "$live_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["activePhase"] = "Action Plan"
data["collabs"][0]["turnOrder"] = ["tw", "pe"]
json.dump(data, open(path, "w"))
PY
cat >"$live_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Action Plan

<details open>
<summary>tw</summary>
**pe — `tools/collab/registry.py`**
<details>
<summary>pe</summary>
nested note, not a top-level contribution
</details>
</details>

<details>
<summary>pe</summary>
two
</details>
MD
(cd "$live_root" && [[ "$(python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-lifecycle-live alpha)" == "Handoff" ]]) || fail "registry helper: contribution parser must ignore body labels and nested details summaries"
python3 - "$live_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["activePhase"] = "Discussion"
data["collabs"][0]["turnOrder"] = ["mod", "tw", "pe"]
json.dump(data, open(path, "w"))
PY
cat >"$live_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

## Discussion

<details>
<summary>mod</summary>
one
</details>

<details>
<summary>tw</summary>
two
</details>

<details>
<summary>pe</summary>
three
</details>
MD
(cd "$live_root" && [[ "$(python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-lifecycle-live alpha)" == "unchanged" ]]) || fail "registry helper: live lifecycle must exempt Discussion from auto-advance"

reviewer_live="$tmpdir/reviewer-live"
mkdir -p "$reviewer_live/.collabs/records"
reviewer_live_registry="$reviewer_live/.collabs/registry.json"
cp "$reviewer_registry" "$reviewer_live_registry"
cat >"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

**Status**

| Status | Active phase | Turn order |
|--------|--------------|------------|
| open | Audit | mod, tw, pe |

## Audit

<details>
<summary>mod</summary>
one
</details>

<details>
<summary>tw</summary>
two
</details>

<details>
<summary>pe</summary>
three
</details>
MD
(cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pa >state.json)
python3 - "$reviewer_live/state.json" <<'PY' || fail "registry helper: reviewer must speak last in Audit"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["expectedRole"] == "pa"
assert state["reviewerRole"] == "pa"
assert state["turnOrder"] == ["mod", "tw", "pe"]
PY
(cd "$reviewer_live" && [[ "$(python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-lifecycle-live alpha)" == "unchanged" ]]) || fail "registry helper: reviewer-required Audit must not advance before reviewer speaks"
cat >>"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'

<details>
<summary>pa</summary>
four
</details>
MD
(cd "$reviewer_live" && [[ "$(python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-lifecycle-live alpha)" == "Discussion" ]]) || fail "registry helper: reviewer-complete Audit must advance"

python3 - "$reviewer_live_registry" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
entry = data["collabs"][0]
entry["activePhase"] = "Discussion"
entry["turnOrder"] = ["mod", "tw", "pe"]
json.dump(data, open(path, "w"))
PY
cat >"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'
# alpha

**Status**

| Status | Active phase | Turn order |
|--------|--------------|------------|
| open | Discussion | mod, tw, pe |

## Discussion

<details>
<summary>mod</summary>
one
</details>

<details>
<summary>tw</summary>
two
</details>
MD
optional_reject="$({ cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pa; } 2>&1 || true)"
[[ "$optional_reject" == "reviewer may speak after all turn-order participants have contributed in this round" ]] || fail "registry helper: reviewer must be rejected before Discussion round boundary"
cat >>"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'

<details>
<summary>pe</summary>
three
</details>
MD
(cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pa >optional-state.json)
python3 - "$reviewer_live/optional-state.json" <<'PY' || fail "registry helper: reviewer must be optional at Discussion round boundary"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["expectedRole"] == "mod"
assert "pa" in state["allowedRoles"]
PY
cat >>"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'

<details>
<summary>pa</summary>
four
</details>
MD
(cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha mod >post-reviewer-state.json)
python3 - "$reviewer_live/post-reviewer-state.json" <<'PY' || fail "registry helper: ordinary rotation must resume after reviewer opt-in"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["expectedRole"] == "mod"
assert state["allowedRoles"] == ["mod"]
PY
cat >>"$reviewer_live/.collabs/records/2026-04-27-alpha.md" <<'MD'

<details>
<summary>mod</summary>
five
</details>

<details>
<summary>tw</summary>
six
</details>

<details>
<summary>pe</summary>
seven
</details>
MD
(cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pa >second-round-state.json)
python3 - "$reviewer_live/second-round-state.json" <<'PY' || fail "registry helper: reviewer must be optional at recurring Discussion round boundary"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["expectedRole"] == "mod"
assert "pa" in state["allowedRoles"]
PY
(cd "$reviewer_live" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json render-status alpha >/dev/null)
grep -Fq '| Status | Active phase | Turn order | Reviewer |' "$reviewer_live/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: render-status must add Reviewer cell"
grep -Fq '| open | Discussion | mod, tw, pe | pa |' "$reviewer_live/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: render-status must mirror reviewer"

python3 "$ROOT/tools/collab/registry.py" --registry "$reviewer_live_registry" execution alpha pe completed 2026-04-28 --assigned-role pe --validation-result passed --touched-path tools/collab/registry.py >/dev/null
python3 - "$reviewer_live_registry" <<'PY' || fail "registry helper: execution metadata must record validation result and touched paths"
import json
import sys
data = json.load(open(sys.argv[1]))
state = data["collabs"][0]["execution"]["pe"]
assert state["validationResult"] == "passed"
assert state["touchedPaths"] == ["tools/collab/registry.py"]
PY
python3 "$ROOT/tools/collab/registry.py" write-guard speak .collabs/records/alpha.md >/dev/null
! python3 "$ROOT/tools/collab/registry.py" write-guard speak README.md >/dev/null 2>&1 || fail "registry helper: non-execute routes must be guarded to .collabs writes"
python3 "$ROOT/tools/collab/registry.py" write-guard execute README.md >/dev/null

join_root="$tmpdir/join-live"
mkdir -p "$join_root/.collabs/records"
cat >"$join_root/.collabs/registry.json" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Audit",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": "Cursor Composer"},
        {"role": "tw", "agentId": "Claude Sonnet"}
      ],
      "turnOrder": ["mod", "tw"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
cat >"$join_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | stale | — |

**Participants**

| # | Key | Role | Agent | Responsibilities |
|---|-----|------|-------|------------------|
| 1 | tw | Stale Writer | Unknown | stale |

## Audit
MD
(cd "$join_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json render-participants alpha --roles-dir "$ROOT/cursor/_roles" >/dev/null)
grep -Fq '| 1 | mod | Moderator | Cursor Composer | scope; sequencing; framing; pacing; integrity |' "$join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: render-participants must render mod from registry"
grep -Fq '| 2 | tw | Technical Writer | Claude Sonnet | clarity; conciseness; accuracy; developer experience |' "$join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: render-participants must render tw from registry order"
! grep -Fq 'Stale Writer' "$join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: render-participants must replace stale table rows"

(cd "$join_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants alpha pe --roles-dir "$ROOT/cursor/_roles" --agent-id "Codex GPT" >/dev/null)
python3 - "$join_root/.collabs/registry.json" <<'PY' || fail "registry helper: join-participants must persist participant and turn-order changes"
import json
import sys
data = json.load(open(sys.argv[1]))
entry = data["collabs"][0]
assert [p["role"] for p in entry["participants"]] == ["mod", "tw", "pe"]
assert entry["turnOrder"] == ["mod", "tw", "pe"]
PY
grep -Fq '| open | Audit | mod, tw, pe | — |' "$join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must render status from next registry state"
grep -Fq '| 3 | pe | Platform Engineer | Codex GPT | effectiveness; efficiency; completeness; optimization |' "$join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must render joined role in participants table"

reviewer_join_root="$tmpdir/reviewer-join"
mkdir -p "$reviewer_join_root/.collabs/records"
cat >"$reviewer_join_root/.collabs/registry.json" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Audit",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": "Cursor Composer"},
        {"role": "tw", "agentId": "Claude Sonnet"}
      ],
      "turnOrder": ["mod", "tw"],
      "reviewerRole": "pa",
      "reviewerMode": "last-in-convergent-phases",
      "reviewerOptionalPhases": ["Discussion"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
cat >"$reviewer_join_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | stale | pa |

**Participants**

| # | Key | Role | Agent | Responsibilities |
|---|-----|------|-------|------------------|
| 1 | mod | Moderator | Cursor Composer | scope; sequencing; framing; pacing; integrity |
| 2 | tw | Technical Writer | Claude Sonnet | clarity; conciseness; accuracy; developer experience |

Agents must wait for the moderator to call `/collab speak` before contributing.

**Reviewer**

| Role | Status |
|------|--------|
| pa (Principal Architect) | (pending) |

`pa` is assigned as reviewer but has not yet joined. Run `/collab join --role pa` before any participant may contribute.

---

## Audit
MD
(cd "$reviewer_join_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants alpha pa --roles-dir "$ROOT/cursor/_roles" --agent-id "Claude Opus" >/dev/null)
grep -Fq '**pa** — registered in **Participants** and active as the convergent-phase reviewer' "$reviewer_join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must flip reviewer section to active when reviewer joins"
! grep -Fq '(pending)' "$reviewer_join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must remove (pending) label when reviewer joins"

non_reviewer_join_root="$tmpdir/non-reviewer-join"
cp -R "$reviewer_join_root" "$non_reviewer_join_root"
python3 - "$non_reviewer_join_root/.collabs/registry.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
entry = data["collabs"][0]
entry["participants"] = [
    {"role": "mod", "agentId": "Cursor Composer"},
    {"role": "tw", "agentId": "Claude Sonnet"},
]
entry["turnOrder"] = ["mod", "tw"]
json.dump(data, open(path, "w"))
PY
cat >"$non_reviewer_join_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | stale | pa |

**Participants**

| # | Key | Role | Agent | Responsibilities |
|---|-----|------|-------|------------------|
| 1 | mod | Moderator | Cursor Composer | scope; sequencing; framing; pacing; integrity |
| 2 | tw | Technical Writer | Claude Sonnet | clarity; conciseness; accuracy; developer experience |

Agents must wait for the moderator to call `/collab speak` before contributing.

**Reviewer**

| Role | Status |
|------|--------|
| pa (Principal Architect) | (pending) |

`pa` is assigned as reviewer but has not yet joined. Run `/collab join --role pa` before any participant may contribute.

---

## Audit
MD
(cd "$non_reviewer_join_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants alpha pe --roles-dir "$ROOT/cursor/_roles" --agent-id "Codex GPT" >/dev/null)
grep -Fq '(pending)' "$non_reviewer_join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must keep (pending) label when a non-reviewer role joins"
! grep -Fq 'active as the convergent-phase reviewer' "$non_reviewer_join_root/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: join-participants must not flip reviewer to active when non-reviewer joins"

fail_root="$tmpdir/join-fail"
cp -R "$join_root" "$fail_root"
python3 - "$fail_root/.collabs/registry.json" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
entry = data["collabs"][0]
entry["participants"] = [
    {"role": "mod", "agentId": "Cursor Composer"},
    {"role": "tw", "agentId": "Claude Sonnet"},
]
entry["turnOrder"] = ["mod", "tw"]
json.dump(data, open(path, "w"))
PY
before_registry="$(cat "$fail_root/.collabs/registry.json")"
before_transcript="$(cat "$fail_root/.collabs/records/2026-04-27-alpha.md")"
! (cd "$fail_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants alpha ghost --roles-dir "$ROOT/cursor/_roles" >/dev/null 2>&1) || fail "registry helper: join-participants must fail when joined role JSON is missing"
[[ "$(cat "$fail_root/.collabs/registry.json")" == "$before_registry" ]] || fail "registry helper: join-participants missing-role abort must leave registry unchanged"
[[ "$(cat "$fail_root/.collabs/records/2026-04-27-alpha.md")" == "$before_transcript" ]] || fail "registry helper: join-participants missing-role abort must leave transcript unchanged"

missing_table_root="$tmpdir/join-missing-table"
cp -R "$join_root" "$missing_table_root"
cat >"$missing_table_root/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | mod, tw | — |

## Audit
MD
before_registry="$(cat "$missing_table_root/.collabs/registry.json")"
! (cd "$missing_table_root" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants alpha pa --roles-dir "$ROOT/cursor/_roles" >/dev/null 2>&1) || fail "registry helper: join-participants must fail when participants table is missing"
[[ "$(cat "$missing_table_root/.collabs/registry.json")" == "$before_registry" ]] || fail "registry helper: missing-table abort must leave registry unchanged"

echo "PASS: registry helper validates registry-backed collab flows"
