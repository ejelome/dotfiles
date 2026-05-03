# /collab delete

Permanently remove a collab record from the registry and disk. This operation is destructive and requires explicit confirmation.

## Trigger

**Slash:** `/collab delete`
**Signature:** `/collab delete [<target>]`
**Phrases:** collab delete, hard delete collab, permanently remove collaboration record

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. Require explicit confirmation before proceeding: display the collab slug, id, and transcript path, then prompt the moderator to confirm with `yes` or abort with anything else. If the moderator does not confirm, stop without any change.
4. Remove the collab entry from the registry entirely.
5. Clear `activeCollabId` when it points at the deleted collab.
6. Delete the transcript file from disk.
7. Stop after registry removal and transcript deletion.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `delete`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Destructive by default:** `delete` is always a hard delete — it removes both the registry entry and the transcript file. For non-destructive deactivation, use `/collab archive` instead.
- **Confirmation required:** Always show the target details and require an explicit `yes` before writing. Never skip the confirmation prompt.
