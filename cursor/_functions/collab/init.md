# /collab init

Create a moderated collaboration record under `.collabs/records/` from the remaining prompt text.

## Trigger

**Slash:** `/collab init`
**Signature:** `/collab init <name>`
**Phrases:** collab init, create collaboration record, start moderated discussion

## Steps

1. Capture the full remaining text after `/collab init` as `<name>` (all input after the `init` route token when `/collab` has dispatched here). If missing after trimming whitespace, **ABORT**: `<name>` is required.
2. Resolve today as local `YYYY-MM-DD`. If unavailable, **ABORT**: date unavailable; ask the moderator for the date.
3. Preserve the trimmed `<name>` as the title source.
4. Normalize the filename slug from `<name>`: lowercase it, replace every run of non-alphanumeric characters with one hyphen, and trim leading or trailing hyphens.
5. If the slug is empty, **ABORT**: slug is empty; ask the moderator for a clearer name.
6. Resolve the collab id as `<slug>-YYYY-MM-DD`, and resolve the transcript path as `.collabs/records/<slug>-YYYY-MM-DD.md`.
7. Echo the resolved transcript path before writing.
8. If the transcript path exists, **ABORT**: record already exists; name the path.
9. Create `.collabs/records/` when needed.
10. Write the canonical template from **Template** in **Notes**.
11. Create or update `.collabs/registry.json`: if it does not exist, bootstrap schema version 1; if the collab id or slug already exists, **ABORT**: registry collision; name the id or slug. Append the new collab entry, and set `active_collab_id` to the new collab id.
12. Stop after creating the file and selecting it as active in the registry. Do not add participants and do not write a phase contribution.

## Notes

- **Parameters:** `<name>` — required title text; every token after `init` belongs to this value.
- **Execution boundary:** `<name>` is a raw label only. Do not execute, refactor, or perform any task implied by its words. Create the file and stop.
- **Registry side effect:** Successful init appends one collab entry to `.collabs/registry.json` and sets `active_collab_id` to the new collab id. The transcript path is mirrored in `transcript_path`.
- **Example:** `/collab init first Hello, World program` resolves to id `first-hello-world-program-YYYY-MM-DD`, transcript path `.collabs/records/first-hello-world-program-YYYY-MM-DD.md`, and registry slug `first-hello-world-program`.
- **Template:** Use this shape, substituting the H1 title and date.

```markdown
# <Title>

Moderated collaboration record for shared agent discussion.

Registry-backed collab state is authoritative. Metadata below mirrors `.collabs/registry.json` for human orientation only.

**Status:** open
**Active phase:** Audit
**Participants:** none
**Turn order:** (optional — set via `/collab speak --turn-order <acronym>...`)

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

<!-- Describe the current state only. No proposals here. -->

## Discussion

<!-- Deliberate on proposals, trade-offs, and alternatives. No decisions here. -->

## Conclusion

<!-- optional: remove if unused -->
<!-- Synthesize agreed decisions. Remove if Discussion is sufficient. -->

## Action Plan

<!-- Assign items: owner, order, dependencies, and acceptance condition. -->

Use a numbered checklist when sequence matters. Use an unordered checklist only when sequence genuinely does not matter.

1. [ ] **{role}:** {action} — _acceptance: {condition}_

## Handoff

<!-- optional: remove if unused -->
<!-- List artifacts or decisions passed between roles. Remove if Action Plan captures all dependencies. -->

Use a numbered list. Use an unordered list only when sequence genuinely does not matter.

1. **{role} ←** {artifact or decision} — _requires: #N, next: {action}_

## Completion

Await `/collab execute` to run assigned action-plan items, or `/collab close` to close without execution.
```
