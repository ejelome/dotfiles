# /collab list

List the registry-backed collabs so the moderator can inspect status and active selection without navigating the filesystem.

## Trigger

**Slash:** `/collab list`
**Signature:** `/collab list`
**Phrases:** collab list, list collaborations, list collab records

## Steps

1. Read `.collabs/registry.json`. If unreadable, **ABORT**: registry unreadable; name the path.
2. Validate the registry structure and active pointer.
3. Return one line per collab with active marker, slug, status, active phase, and participant count.
4. Stop without mutating the registry or any transcript.

## Notes

- **Parameters:** none.
- **Output shape:** Use `*` for the active collab and `-` for every other collab. Include `slug`, `status`, `active_phase`, and participant count on each line.
- **Registry boundary:** `/collab list` is read-only. It never creates, edits, archives, or selects a collab.
