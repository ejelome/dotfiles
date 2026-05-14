#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
export CURSOR_CONFIG_ROOT="$ROOT/cursor"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

registry_revision() {
  local role="$1"
  (cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state pilot "$role" --resume | python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])')
}

work="$tmpdir/pilot"
mkdir -p "$work/.collabs/records"
cat >"$work/.collabs/registry.json" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-05-07-pilot",
  "collabs": [
    {
      "id": "2026-05-07-pilot",
      "slug": "pilot",
      "title": "pilot",
      "description": "pilot collab",
      "status": "open",
      "activePhase": "Audit",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": "cursor-composer"}
      ],
      "turnOrder": ["mod"],
      "reviewerRole": "pa",
      "reviewerMode": "last-in-convergent-phases",
      "reviewerOptionalPhases": ["Discussion"],
      "transcriptPath": ".collabs/records/2026-05-07-pilot.md",
      "sequence": 1,
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
cat >"$work/.collabs/records/2026-05-07-pilot.md" <<'MD'
# pilot

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Audit | mod | pa |

**Participants**

| # | Key | Role | Agent | Responsibilities |
|---|-----|------|-------|------------------|
| 1 | mod | Moderator | cursor-composer | scope; sequencing; framing; pacing; integrity |

**Reviewer**

| Role | Status |
|------|--------|
| pa (Principal Architect) | (pending) |

---

**Table of contents**

- [Audit](#audit)
- [Discussion](#discussion)
- [Conclusion](#conclusion)
- [Action Plan](#action-plan)
- [Handoff](#handoff)
- [Completion](#completion)

---

## Audit

## Discussion

## Conclusion

## Action Plan

## Handoff

## Completion

**Execution history**
MD

grep -Fq 'tools/collab/registry.py init --agent-id <agentId>' "$ROOT/cursor/_functions/collab/init.md" || fail "pilot fixture: init must route through the helper-owned transaction"

for role in tw pe pa; do
  (cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json join-participants pilot "$role" --agent-id "agent-$role" --roles-dir "$ROOT/cursor/_roles" >/dev/null)
done
grep -Fq '| 4 | pa | Principal Architect | agent-pa | depth; coherence; judgment; risk |' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: join must render participants from registry state"

(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json set pilot active-phase Discussion --force >/dev/null)
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json render-status pilot >/dev/null)
printf 'moderator text\n' >"$work/mod.md"
printf 'writer text\n' >"$work/tw.md"
printf 'platform text\n' >"$work/pe.md"
revision="$(registry_revision mod)"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-render pilot mod --content-file mod.md --observed-revision "$revision" --timestamp '2026-05-07 10:00 +00:00' >/dev/null)
revision="$(registry_revision tw)"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-render pilot tw --content-file tw.md --observed-revision "$revision" --timestamp '2026-05-07 10:01 +00:00' >/dev/null)
revision="$(registry_revision pe)"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-render pilot pe --content-file pe.md --observed-revision "$revision" --timestamp '2026-05-07 10:02 +00:00' >/dev/null)
grep -Fq '  - [pe](#discussion-pe-1)' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: speak must insert TOC entries"

printf 'platform replacement\n' >"$work/pe-rewrite.md"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json rewrite-speak-render pilot pe --content-file pe-rewrite.md --timestamp '2026-05-07 10:03 +00:00' >/dev/null)
grep -Fq 'platform replacement' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: rewrite speak must replace active content"
grep -Fq 'Previous revision, 2026-05-07 10:02 +00:00:' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: rewrite speak must preserve revision history"
! grep -Fq '  - [pe](#discussion-pe-2)' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: rewrite speak must not add a TOC entry"

(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json advance pilot next >/dev/null)
grep -Fq '| open | Conclusion | tw, pe | pa |' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: advance must render status from registry"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json advance pilot prev >/dev/null)
grep -Fq '| open | Discussion | mod, tw, pe | pa |' "$work/.collabs/records/2026-05-07-pilot.md" || fail "pilot fixture: restore must render status and restored turn order"

echo "PASS: registry helper models constrained-bootstrap collab pilot"
