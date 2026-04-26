# /collab join

Register one participant in the active collaboration record from command-owned role JSON.

## Trigger

**Slash:** `/collab join`
**Signature:** `/collab join --role <role>`
**Phrases:** collab join, join collaboration record, register collab role

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Resolve `<role>` from `--role <role>`. If missing, **ABORT**: `--role <role>` is required.
3. Read `roles/<role>.json` beside this playbook. If unreadable, **ABORT**: role file unreadable; name the expected path.
4. Validate the role JSON against **Role schema** in **Notes**. If invalid, **ABORT**: invalid role JSON; name the failed field.
5. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
6. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
7. Append `<role>` to the registry `participants` list when missing. If the role already exists, leave the registry roster unchanged.
8. If the registry `turn_order` is empty, seed it from `participants`. If the role is new and `turn_order` exists, append the role at the end.
9. Replace `**Participants:** none` with `**Participants:**` followed by one participant line, or append a participant line below an existing participants block.
10. If the same role already appears in the transcript participants block, replace that role's participant line only.
11. Sync the `**Turn order:**` metadata line from the registry after any roster change.
12. Stop after updating registry and transcript participants. Do not write a phase contribution.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first positional token after `join`; when absent, resolved per **Registry targeting** in **Notes**. `--role <role>` — required role acronym.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Role schema:** JSON object with `acronym` matching `<role>`, non-empty string `display_name`, and non-empty string array `concerns`.
- **Participant line format:** `- **<acronym> — <display_name>:** <concern>; <concern>`.
- **Role data boundary:** Role JSON files are command-owned data, not route playbooks.
