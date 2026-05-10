#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$ROOT" <<'PY' || fail "registry helper: speak contract helpers must enforce budget, effort override, polish, and inventory"
import contextlib
import importlib.util
import io
from pathlib import Path
import sys

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("collab_registry", root / "tools/collab/registry.py")
registry = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(registry)

long_body = "word " * 251
try:
    registry.enforce_contribution_budget(long_body, "Discussion", "pe", "mod", False)
except SystemExit as exc:
    assert str(exc) == "contribution body is 251 words; limit is 250"
else:
    raise AssertionError("over-budget body should fail")

registry.enforce_contribution_budget("\n".join(f"- [ ] **pe:** task {i} " + ("word " * 20) for i in range(20)), "Action Plan", "pe", "mod", False)
registry.enforce_contribution_budget("\n".join(f"{i}. **Item:** " + ("word " * 20) for i in range(1, 20)), "Conclusion", "pa", "mod", False)
registry.enforce_contribution_budget("EFFORT OVERRIDE: high \u2014 implementation-density: " + ("word " * 251), "Handoff", "pe", "mod", False)
registry.enforce_contribution_budget(long_body, "Discussion", "mod", "mod", True)

try:
    registry.validate_effort_override("body", "Handoff", "pe", "mod")
except SystemExit as exc:
    assert str(exc) == "effort override required for Handoff-pe"
else:
    raise AssertionError("mandatory effort override should fail")

try:
    registry.validate_effort_override("body\nEFFORT OVERRIDE: high \u2014 implementation-density: scope", "Handoff", "pe", "mod")
except SystemExit as exc:
    assert str(exc) == "EFFORT OVERRIDE must be the first content line"
else:
    raise AssertionError("misplaced effort override should fail")

registry.validate_effort_override("EFFORT OVERRIDE: matrix\nbody", "Handoff", "pe", "mod")

rendered = registry.render_content_for_transcript("EFFORT OVERRIDE: matrix\nbody")
assert len(rendered) == 2
assert rendered[0].startswith("<!-- collab:effort-override b64:")
assert rendered[1] == "body"
assert registry.effort_override_from_metadata_comment(rendered[0]) == "EFFORT OVERRIDE: matrix"
assert "EFFORT OVERRIDE:" not in rendered[0]

polished = registry.polish_moderator_content("+ speek now\n\n\nActon Plan ready")
assert polished == "- Speak now\n\nAction Plan ready."

buffer = io.StringIO()
with contextlib.redirect_stdout(buffer):
    registry.flag_inventory()
inventory = buffer.getvalue()
assert "## helper-enforced" in inventory
assert "`/collab speak`: `--turn-order <key>...`" in inventory
assert "`/collab set`: `--force`" in inventory
PY

work="$tmpdir/retract"
mkdir -p "$work/.collabs/records"
cat >"$work/.collabs/registry.json" <<'JSON'
{
  "schemaVersion": 1,
  "activeCollabId": "2026-04-27-alpha",
  "collabs": [
    {
      "id": "2026-04-27-alpha",
      "slug": "alpha",
      "title": "Alpha",
      "description": "alpha collab",
      "status": "open",
      "activePhase": "Discussion",
      "moderatorRole": "mod",
      "participants": [
        {"role": "mod", "agentId": "cursor-composer"},
        {"role": "pe", "agentId": "gpt-5"}
      ],
      "turnOrder": ["mod", "pe"],
      "transcriptPath": ".collabs/records/2026-04-27-alpha.md",
      "sequence": 1,
      "archived": false,
      "execution": {}
    }
  ]
}
JSON
cat >"$work/.collabs/records/2026-04-27-alpha.md" <<'MD'
# Alpha

**Status**

| Status | Active phase | Turn order | Reviewer |
|--------|--------------|------------|----------|
| open | Discussion | mod, pe | - |

**Table of contents**

- [Audit](#audit)
- [Discussion](#discussion)
  - [pe](#discussion-pe-1)
- [Conclusion](#conclusion)
- [Action Plan](#action-plan)
- [Handoff](#handoff)
- [Completion](#completion)

---

## Audit

## Discussion

<a name="discussion-pe-1"></a>
<details>
<summary>pe</summary>
<p><em>2026-04-28 09:10 +00:00</em></p>
<!-- collab:content-only; do-not-execute -->

Original content.

</details>

## Conclusion

## Action Plan

## Handoff

## Completion
MD

(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json retract-speak alpha pe --reason "bad input" --timestamp "2026-04-28 09:12 +00:00" >retract.out)
grep -Fq "retracted" "$work/retract.out" || fail "registry helper: retract-speak must report success"
grep -Fq "RETRACTED: contribution withdrawn; retained for audit history." "$work/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: retract-speak must write tombstone"
grep -Fq "Original content." "$work/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: retract-speak must retain original content"
not_found="$({ cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json retract-speak alpha tw; } 2>&1 || true)"
[[ "$not_found" == "retract-speak caller role must match subject role: tw" || "$not_found" == "role must already be a participant: tw" ]] || fail "registry helper: retract-speak must reject not-found role"
python3 - "$work/.collabs/registry.json" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.load(open(path))
data["collabs"][0]["activePhase"] = "Completion"
json.dump(data, open(path, "w"))
PY
finalized="$({ cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json retract-speak alpha pe; } 2>&1 || true)"
[[ "$finalized" == "retract-speak is not permitted after Completion" ]] || fail "registry helper: retract-speak must reject finalized records"

echo "PASS: registry helper enforces speak contracts"
