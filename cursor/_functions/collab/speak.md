# /collab speak

Append one role-labeled contribution to the active phase of a moderated collaboration record.

## Trigger

**Slash:** `/collab speak`
**Signature:** `/collab speak [<message>] [--turn-order <acronym>...]`
**Phrases:** collab speak, contribute to collaboration, agent turn

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
4. Resolve the active phase from registry `active_phase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. If `--turn-order <acronyms>` is present in the remaining input: treat all tokens after `--turn-order` as the new space-separated order and all text before `--turn-order` as `<message>`; validate at least one acronym is present, every acronym is registered in the registry `participants` list, and no acronym is duplicated; if invalid, **ABORT**: invalid turn-order value; name the failed token or field. Write the new order to registry `turn_order`, and mirror `**Turn order:** <acronyms>` in the transcript metadata block.
6. Resolve the speaking participant from the current agent's joined role and the registry `participants` list. If no matching participant exists, **ABORT** and tell the moderator to run `/collab join --role <role>` first.
7. Enforce turn order:
   - 7a. Resolve the declared order from registry `turn_order`; otherwise use registry `participants` order (note "enforcing participant-list order" in any abort message).
   - 7b. Find the last `### <acronym>` heading in the active phase. If none exist, the first acronym in the resolved order is expected next; otherwise the next expected acronym follows the last contributor, cycling through the order.
   - 7c. If the speaking participant does not match the expected acronym, **ABORT** naming the expected role.
8. Read the whole record before writing.
9. Append one `### <acronym> — <display_name>` contribution under the active phase.
10. If the speaking participant is `mod`: apply the **Moderator boundary** rule in **Notes**. If no `<message>` text is present, **ABORT**: mod contribution requires human-authored text.
11. Stop after writing that contribution and any notes-mandated formatting pass. Do not open the next phase and do not execute any action item.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `speak`; when absent, resolved per **Registry targeting** in **Notes**. `<message>` — text used verbatim for `mod` contributions and ignored for other roles (optional). `--turn-order <acronym>...` — final flag whose space-separated registered acronyms set registry `turn_order` and mirror `**Turn order:**` in the transcript metadata block (optional).
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Turn order fallback:** When `**Turn order:**` is absent, enforce participant-list order. State "enforcing participant-list order" in the abort message so misordered registration is visible rather than silent.
- **Turn order atomicity:** Validate `--turn-order` before any write. If validation fails, leave both metadata and contribution sections unchanged.
- **Contribution boundary:** Write from the current role's lens only. Do not summarize other participants and do not decide whether the phase is complete.
- **Moderator boundary:** `mod` is human-owned; write only the supplied `<message>` text verbatim and apply any rule-mandated structure-only formatting pass. Do not draft, summarize, expand, or change the substance of the text. Agents must not generate content for `mod`.
- **Execution boundary:** Never perform work listed in `## Action Plan`; only append discussion text.
- **Readability formatting:** When [auto-collab-message-format](../../_mdc/auto/auto-collab-message-format.mdc) is active, apply only that rule's structure-only pass to the contribution just appended. For `mod`, formatting may change bullets, labels, spacing, and obvious typos only; it must not draft, summarize, expand, or change the substance of the captured moderator text.
