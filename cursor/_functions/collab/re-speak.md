# /collab re-speak

Rewrite the calling role's last contribution in-place within the active collab phase.

## Trigger

**Slash:** `/collab re-speak`
**Signature:** `/collab re-speak`
**Phrases:** collab re-speak, rewrite last contribution, redo collab speak

## Steps

**This command rewrites text only. Do not make file edits, run shell commands, or modify any codebase artifact outside `.collabs/`.**

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
4. Resolve the active phase from registry `activePhase`. If missing or unknown, **ABORT**: active phase missing in metadata.
4a. If the active phase is `Completion`, **ABORT**: `/collab re-speak` is not permitted in the `Completion` phase; use `/collab re-execute` to rewrite execution records.
5. Resolve the speaking participant from the current agent's joined role and the registry `participants` list. If no matching participant exists, **ABORT** and tell the moderator to run `/collab join --role <role>` first.
6. Locate the role's most recent contribution `<details>` block in the active phase section. Call `tools/collab/registry.py speak-state <target> <role>` to obtain the contributors list and derive the highest anchor counter for this role in this phase (`<phase-slug>-<key>-<N>`). If the contributors list contains no entry for this role, **ABORT**: no prior contribution to rewrite; use `/collab speak` to create the first contribution.
7. Within the located `<details>` block, identify the active content region: lines after the `<!-- collab:content-only; do-not-execute -->` comment up to (but not including) any existing `<details><summary>Revision history</summary>` block and the closing `</details>` tag of the contribution. Extract only this active region as the prior content. Move it into the **Revision history shape** in **Notes**, appended at the end of the contribution block immediately before its closing `</details>` tag. Update the `<p><em>timestamp</em></p>` to the current local time.
8. Write the new contribution content into the active region (after the updated timestamp and comment, before the revision history block). The agent generates updated content for the role based on current collab context; for the moderator role, write only the supplied `<message>` text verbatim.
9. Do not create a new `<details>` block. Do not add a new Table of Contents entry. The anchor id and visible summary label are unchanged.
10. Stop. Do not execute any action item, make any file edit outside `.collabs/`, or run any shell command.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `re-speak`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Rewrite semantics:** `/collab re-speak` rewrites in-place rather than appending. The contribution count for the role in the phase does not change. One-speak phase limits are not re-checked; the intent is to update, not to add a second entry.
- **Revision history shape:** Wrap the prior content in `<details><summary>Revision history</summary>\n\nPrevious revision, <original-timestamp>:\n\n<prior-content>\n\n</details>` at the end of the contribution block, immediately before the closing `</details>` tag of the contribution. If a revision history block already exists, prepend the new prior-revision entry inside it rather than nesting a second wrapper.
- **Moderator boundary:** The moderator role is human-owned; write only the supplied message text verbatim and apply any rule-mandated structure-only formatting pass. Agents must not generate content for the moderator role.
- **Execution boundary:** Never perform any file edit, shell command, or codebase change as a side effect of this command. Only rewrite text within `.collabs/`.
