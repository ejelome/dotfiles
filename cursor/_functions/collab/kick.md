# /collab kick

Remove one participant from the registry roster and transcript metadata when the moderator needs to change the collaboration roster.

## Trigger

**Slash:** `/collab kick`
**Signature:** `/collab kick <role>`
**Phrases:** collab kick, remove collab participant, drop collaboration role

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Resolve `<role>` from the next positional token after `kick`. If missing, **ABORT**: `<role>` is required.
3. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
4. If `<role>` is not listed in registry `participants`, report that the role is already absent and stop.
5. If `<role>` equals registry `moderator_role`, **ABORT**: moderator cannot be removed by `/collab kick`; replace the moderator first.
6. Remove `<role>` from registry `participants` and registry `turn_order`.
7. Remove the role's participant line from the transcript participants block, and sync the transcript `**Turn order:**` line from the registry.
8. Stop after updating registry and transcript. Do not remove prior phase contributions.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `kick`; when absent, resolved per **Registry targeting** in **Notes**. `<role>` — required participant acronym to remove.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Ownership boundary:** `participants` are owned by `join` and `kick`. `/collab set` must not replace the roster during normal operation.
