# Collab participant guide

First-time on-ramp. Scope: join through phase completion. Reference transcript: `2026-05-13-prose-and-schema-nudges-to-keep-mod-role-writes-inside-collabs` (collab #4, closed).

---

## Acceptance checks

After one read, a first-time participant should be able to:

- Identify the repo purpose from `README.md`.
- Find this guide from the Cursor/agent runtime context.
- Complete one collab path from join through phase completion without private context.

---

## What a collab is

A collab is a structured multi-agent planning and implementation session. Each participant holds a role (e.g., `tw`, `pe`, `pa`). Contributions are appended to a transcript (`.collabs/records/<slug>.md`) under phases: Audit → Discussion → Conclusion → Action Plan → Handoff → Completion. The registry (`.collabs/registry.json`) is truth; the transcript is the human-readable ledger.

The moderator (`mod`) drives pacing and is human-owned. Agents write only their assigned role; they never draft moderator text.

---

## Before you do anything

**Read invariants.** They govern everything:

```
~/.cursor/_functions/collab/_invariants.md
```

Key rules:
- **Invariant #4 (Disk-state authority):** Registry and transcript on disk are truth. Your conversation cache is stale. Always call the helper fresh.
- **Invariant #5 (Context-changing events):** After `/compact`, agent swap, phase transition, or subagent return — re-run `speak-state --resume` before any write.

---

## Step 1 — Join

Invoke as a prose dispatch from `AGENTS.md`:

```
(collab join --role tw)
```

Behind the scenes, this calls:

```bash
python3 tools/collab/registry.py join-participants <target> tw --agent-id <your-agent-id>
```

**Agent ID:** Use your model's stable family token per `~/.cursor/_functions/collab/_agent-id.md`. For Claude Sonnet 4.x: `sonnet`. Pass `unknown` only if the harness exposes nothing.

**After join,** the helper emits:
```
NEXT: Run /collab show policy before first speak.
EFFORT: ...
IDENTITY: <recorded-agent-id>
```

Run `/collab show policy` to read gate rules before your first speak.

---

## Step 2 — Before every speak: re-establish state

This is **mandatory** before every write — not optional.

```bash
python3 tools/collab/registry.py speak-state --resume <target> <role>
```

Capture `registryRevision` from the JSON output. Example:

```json
{
  "activePhase": "Audit",
  "expectedRole": "tw",
  "registryRevision": 42,
  "readyToWrite": true
}
```

If `readyToWrite` is `false` or `expectedRole` is not your role, **stop** — it is not your turn.

---

## Step 3 — Write your contribution

Write your content to a temp file:

```bash
cat > /tmp/my-contribution.md << 'EOF'
Your contribution body here.
EOF
```

Word limit: **250 words** per contribution body (enforced by the helper).

**Effort override (Handoff and mandatory turns):** When required, the first line of your content must be:

```
EFFORT OVERRIDE: <level> — <category>: <concrete signal>
```

Valid categories: `coherence-risk`, `implementation-density`, `deadlock-or-disagreement`, `delivery-or-migration-risk`, `reviewer-concern-raised`.

---

## Step 4 — Append with speak-render

```bash
python3 tools/collab/registry.py speak-render <target> <role> \
  --content-file /tmp/my-contribution.md \
  --observed-revision <registryRevision>
```

`--observed-revision` is a stale-write guard — it must match the revision you captured in Step 2. If the registry changed since then, the helper aborts and tells you to re-run `speak-state --resume`.

On success:
```
NEXT: Run /collab speak for role pe.
appended
{"phaseState": "unchanged"}
```

Mirror any `phaseState` change in the transcript status table.

---

## Phase movement

Phases advance automatically when all assigned roles in that phase have contributed. The helper (`speak-lifecycle-live`) owns this — you never advance manually.

- **Discussion:** exempt from auto-advance; multiple contributions per role are allowed.
- **One-speak phases (Audit, Conclusion, Action Plan, Handoff):** one contribution per role. If you try to write twice, the helper aborts.
- **Completion:** reached only by `/collab run plan`, not by `/collab speak`.

---

## Reviewer behavior

The reviewer role (`pa`) is the last in convergent phases (Conclusion, Action Plan, Handoff). It gates phase advance: once all non-reviewer roles contribute, `pa` is admitted. Until `pa` speaks, the phase does not advance.

In **Discussion**, `pa` is optional (tail opt-in).

If you see `"expectedRole": "pa"` in `speak-state` output when you tried to speak, the reviewer needs to go next.

---

## One full round — what it looks like

Using collab #4 as the reference:

1. `mod` opens the collab with `/collab init`.
2. `tw`, `pe`, `pa` each run `/collab join --role <role>`.
3. `mod` runs `/collab advance` to enter Audit.
4. Each participant runs `speak-state --resume`, writes content, calls `speak-render`. Turn order: `tw` → `pe` → `pa`.
5. After `pa` appends in Audit, the phase auto-advances to Discussion.
6. Discussion repeats — multiple rounds allowed.
7. `mod` advances to Conclusion; participants write one convergent contribution each.
8. Action Plan: `tw` and `pe` write flat checklist items (`- [ ] **tw:** Do the thing.`).
9. Handoff: each role writes execution-ready notes.
10. `pa` closes Handoff; phase advances to Completion.
11. Each role runs `/collab run plan` to implement its Action Plan items.

---

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Skipping `speak-state --resume` after `/compact` | Stale `registryRevision` → `speak-render` aborts | Always re-run before any write |
| Wrong turn order | Helper aborts naming the expected role | Wait; do not force |
| Over 250 words | Helper aborts with word-count error | Trim and retry |
| Missing effort override when required | Helper aborts | Add `EFFORT OVERRIDE: ...` as first line |
| Hand-editing anchors or TOC | Transcript diverges from registry | Never hand-edit; let the helper own these |

---

## Key paths

| Resource | Path |
|---|---|
| Route specs | `~/.cursor/_functions/collab/` |
| Role definitions | `~/.cursor/_roles/` |
| Registry (truth) | `.collabs/registry.json` |
| Transcripts | `.collabs/records/<slug>.md` |
| Helper | `tools/collab/registry.py` |
| Invariants | `~/.cursor/_functions/collab/_invariants.md` |
