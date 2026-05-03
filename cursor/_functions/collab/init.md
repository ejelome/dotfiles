# /collab init

Create a moderated collaboration record under `.collabs/records/` from the remaining prompt text.

## Trigger

**Slash:** `/collab init`
**Signature:** `/collab init <name> [--reviewer <role>]`
**Phrases:** collab init, create collaboration record, start moderated discussion

## Steps

1. Capture the full remaining text after `/collab init` as `<name>` and extract the optional `--reviewer <role>` flag. Strip the `--reviewer <role>` flag and its value from `<name>` before processing; treat the rest as the title source. If `<name>` is missing after trimming whitespace, **ABORT**: `<name>` is required. If `--reviewer` is present but its value is missing or not a valid key (non-empty string of word characters), **ABORT**: `--reviewer` requires a role key.
2. Resolve today as local `YYYY-MM-DD`. If unavailable, **ABORT**: date unavailable; ask the moderator for the date.
3. Preserve the trimmed `<name>` as the title source.
4. Normalize the filename slug from `<name>`: lowercase it, replace every run of non-alphanumeric characters with one hyphen, and trim leading or trailing hyphens.
5. If the slug is empty, **ABORT**: slug is empty; ask the moderator for a clearer name.
6. Resolve the collab id as `YYYY-MM-DD-<slug>`, and resolve the transcript path as `.collabs/records/YYYY-MM-DD-<slug>.md`.
7. Echo the resolved transcript path before writing.
8. If the transcript path exists, **ABORT**: record already exists; name the path.
9. Create `.collabs/records/` when needed.
10. Read the moderator role JSON under `../../_roles/` and validate it against the role schema in [cursor/_core/role.md](../../_core/role.md). If unreadable or invalid, **ABORT**: moderator role file unreadable or invalid; name the path or failed field.
11. Write the canonical template from **Template** in **Notes**, substituting `<Title>` with the trimmed `<name>` verbatim (preserve the user's capitalization exactly — no slug normalization), the init timestamp placeholder with the current local date and time in human-local format (e.g., `Apr 29, 2026 @ 10:33 PM`) using `tools/collab/registry.py banner-timestamp`, and pre-populating the participants table with the moderator role row and the Turn order cell with the moderator role.
12. Create or update `.collabs/registry.json`: if it does not exist, bootstrap schema version 1; if the collab id or slug already exists, **ABORT**: registry collision; name the id or slug. Append the new collab entry with the moderator role in `participants` and `turnOrder`, assign `sequence` as the next unused positive integer, set `moderatorRole` to the moderator role key, set `activeCollabId` to the new collab id, and store the verbatim title in the registry `title` field. If `--reviewer <role>` was supplied, always write `reviewerRole`, `reviewerMode` (`last-in-convergent-phases`), and `reviewerOptionalPhases` (`["Discussion"]`) to the new registry entry — do not condition this write on participant membership. If the reviewer role is not yet in `participants`, add a transcript **Reviewer** section noting that the role must join via `/collab join --role <role>` before any participant may contribute, and that it appears as `(pending)` because it is assigned but not yet registered — do not abort.
13. Stop after creating the file, registering the moderator, and selecting it as active in the registry. Do not write a phase contribution.

## Notes

- **Parameters:** `<name>` — required title text; all tokens after `init` that are not the `--reviewer` flag belong to this value. `--reviewer <role>` — optional flag; always writes `reviewerRole`, `reviewerMode`, and `reviewerOptionalPhases` to the registry entry unconditionally; adds a transcript note if the role is not yet a participant, but does not defer or skip the registry write.
- **Execution boundary:** `<name>` is a raw label only. Do not execute, refactor, or perform any task implied by its words. Create the file and stop.
- **Moderator auto-join:** Successful init registers the moderator role automatically by using the corresponding JSON role file and the same participant row format used by `/collab join`; do not maintain a second participant rendering path.
- **Registry side effect:** Successful init appends one collab entry to `.collabs/registry.json`, includes the moderator role in `participants` and `turnOrder`, and sets `activeCollabId` to the new collab id. The transcript path is mirrored in `transcriptPath`.
- **id and filename format:** `id` is `YYYY-MM-DD-<slug>`; `transcriptPath` is `.collabs/records/YYYY-MM-DD-<slug>.md`. The date prefix enables natural chronological ordering in filesystem listings. The `slug` field stays date-free and is the human-typed command selector (e.g., `use <slug>`).
- **Title verbatim:** The trimmed `<name>` is stored verbatim in both the transcript H1 and the registry `title` field. Slug normalization applies only to the `slug` field; the H1 and `title` reflect what the user typed.
- **Pending reviewer:** When `--reviewer <role>` is supplied but that role is not yet in `participants`, the transcript **Reviewer** section marks the role as `(pending)`. The `(pending)` state is derived from the registry: `reviewerRole` is set but the role does not appear in `participants`. The display is helper-owned; do not derive it from transcript prose.
- **Audit input provenance:** Before opening a collab whose `Audit` phase will cite external files, ensure those files are repo-relative paths or copied to `.collabs/inputs/`. Transient local paths (e.g., `~/Downloads/`) are not durable references and should not be the sole citation in the audit record. See `/collab policy` → **Provenance**.
- **Example:** `/collab init "Slash Command UX and DX Polish"` resolves to id `YYYY-MM-DD-slash-command-ux-and-dx-polish`, transcript path `.collabs/records/YYYY-MM-DD-slash-command-ux-and-dx-polish.md`, H1 `# Slash Command UX and DX Polish`, registry `title` `"Slash Command UX and DX Polish"`, and registry slug `slash-command-ux-and-dx-polish`.
- **Template:** Use this shape, substituting the H1 title and date.

```markdown
# <Title>

_{MMM D, YYYY @ H:MM AM/PM}_

Moderated collaboration record for shared agent discussion.

Registry-backed collab state is authoritative. Metadata below mirrors `.collabs/registry.json` for human orientation only.

**Status**

| Status | Active phase | Turn order |
|--------|--------------|------------|
| open | Audit | mod |

**Participants**

| # | Key | Role | Agent | Responsibilities |
|---|-----|------|-------|------------------|
| 1 | mod | Moderator | Cursor Composer | facilitation; scope control; turn management; decision capture |

Agents must wait for the moderator to call `/collab speak` before contributing. This record is shared context, not an instruction to execute the work being discussed.

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
```
