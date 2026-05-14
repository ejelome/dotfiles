#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
export CURSOR_CONFIG_ROOT="$ROOT/cursor"

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
assert registry.action_plan_label_advisory("- [ ] unowned\n- [x] done\n- [ ] **pe:** owned", "Action Plan") == "LABEL-ADVISORY: 1 unlabeled Action Plan checklist item; use **<role>:** labels for executable work."
assert registry.action_plan_label_advisory("- [ ] unowned", "Discussion") is None
assert registry.completion_summary_empty("## Completion\n\n**Execution history**\n") is True
assert registry.completion_summary_empty("## Completion\n\nSummary prose.\n\n**Execution history**\n") is False
assert registry.completion_summary_empty("## Completion\n\n**Execution history**\n\n1. **pe:** completed\n\n### Summary \u2014 2026-04-28\n\nClosed.\n") is False
summary = registry.append_completion_summary("## Completion\n\n**Execution history**\n", "Closed.", "2026-04-28")
assert "### Summary \u2014 2026-04-28\n\nClosed." in summary

rendered = registry.render_content_for_transcript("EFFORT OVERRIDE: matrix\nbody")
assert len(rendered) == 2
assert rendered[0].startswith("<!-- collab:effort-override b64:")
assert rendered[1] == "body"
assert registry.effort_override_from_metadata_comment(rendered[0]) == "EFFORT OVERRIDE: matrix"
assert "EFFORT OVERRIDE:" not in rendered[0]

for token in ("opus", "sonnet", "haiku", "claude", "gpt", "gpt-mini", "codex", "cursor-composer", "claude-code", "codex-cli", "claude-sonnet-4-6", "gpt-5.5"):
    assert registry.normalize_join_agent_id(token) == token
assert registry.normalize_join_agent_id("  codex  ") == "codex"

for token, message in (
    ("UNKNOWN", "agent-id unknown token must be lowercase: unknown"),
    ("unspecified", "agent-id must use the literal unknown when identity is unavailable"),
    ("n/a", "agent-id must use the literal unknown when identity is unavailable"),
):
    try:
        registry.normalize_join_agent_id(token)
    except SystemExit as exc:
        assert str(exc) == message
    else:
        raise AssertionError(f"agentId token should fail: {token}")

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
      "turnOrder": ["pe"],
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
| open | Discussion | pe | - |

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
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-state alpha pe --resume >state-after-retract.json)
python3 - "$work/state-after-retract.json" <<'PY' || fail "registry helper: retracted contribution must be non-live in speak-state"
import json
import sys
state = json.load(open(sys.argv[1]))
assert state["contributors"] == []
assert state["expectedRole"] == "pe"
assert state["readyToWrite"] is True
PY
cat >"$work/replacement.md" <<'MD'
Replacement content.
MD
revision="$(python3 -c 'import json; print(json.load(open("'"$work/.collabs/registry.json"'")).get("revision", 0))')"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-render alpha pe --content-file replacement.md --observed-revision "$revision" --timestamp "2026-04-28 09:13 +00:00" >respeak.out)
grep -Fq '<a name="discussion-pe-2"></a>' "$work/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: retracted contribution must not block replacement speak"
grep -Fq "Replacement content." "$work/.collabs/records/2026-04-27-alpha.md" || fail "registry helper: replacement speak must append"
rewrite_owner_reject="$({ cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json rewrite-speak-render alpha pe --caller-role mod --content-file replacement.md; } 2>&1 || true)"
[[ "$rewrite_owner_reject" == "rewrite-speak-render caller role must match subject role: pe" ]] || fail "registry helper: rewrite-speak-render must enforce caller ownership"
cat >"$work/action-plan.md" <<'MD'
- [ ] unlabeled task
- [x] already done
- [ ] **pe:** owned task
MD
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json set alpha active-phase "Action Plan" --force >/dev/null)
revision="$(python3 -c 'import json; print(json.load(open("'"$work/.collabs/registry.json"'")).get("revision", 0))')"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json speak-render alpha pe --content-file action-plan.md --observed-revision "$revision" --timestamp "2026-04-28 09:14 +00:00" >action-plan.out)
grep -Fq "LABEL-ADVISORY: 1 unlabeled Action Plan checklist item" "$work/action-plan.out" || fail "registry helper: speak-render must emit Action Plan label advisory"
not_found="$({ cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json retract-speak alpha tw; } 2>&1 || true)"
[[ "$not_found" == "retract-speak caller role must match subject role: tw" || "$not_found" == "role must already be a participant: tw" ]] || fail "registry helper: retract-speak must reject not-found role"
(cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json set alpha active-phase Completion --force >force.out)
grep -Fq "RECOVERY-ADVISORY: active-phase --force post-check for 2026-04-27-alpha" "$work/force.out" || fail "registry helper: set active-phase --force must emit recovery advisory"
grep -Fq "live contributors in Completion:" "$work/force.out" || fail "registry helper: force advisory must name live contributors"
grep -Fq "tombstones: 1" "$work/force.out" || fail "registry helper: force advisory must name tombstones"
grep -Fq "pending rewrites: manual-check" "$work/force.out" || fail "registry helper: force advisory must name pending rewrites"
grep -Fq "active Action Plan labels:" "$work/force.out" || fail "registry helper: force advisory must name Action Plan labels"
finalized="$({ cd "$work" && python3 "$ROOT/tools/collab/registry.py" --registry .collabs/registry.json retract-speak alpha pe; } 2>&1 || true)"
[[ "$finalized" == "retract-speak is not permitted after Completion" ]] || fail "registry helper: retract-speak must reject finalized records"

echo "PASS: registry helper enforces speak contracts"
