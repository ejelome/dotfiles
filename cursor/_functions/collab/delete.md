# /collab delete

Archive or permanently remove a collab so terminal-only users can clean up registry noise without editing files directly.

## Trigger

**Slash:** `/collab delete`
**Signature:** `/collab delete`
**Phrases:** collab delete, archive collab, remove collaboration record

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If `--hard` is present in the remaining input: require explicit hard-removal intent, remove the collab entry from the registry, clear `active_collab_id` when it points at that collab, and delete the transcript file.
4. Otherwise mark the collab as archived in the registry, set registry status to `archived`, and clear `active_collab_id` when it points at that collab.
5. Stop after registry cleanup and any hard-delete transcript removal. Do not edit prior transcripts during soft delete.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `delete`; when absent, resolved per **Registry targeting** in **Notes**. `--hard` — optional destructive flag that removes the transcript file in addition to the registry entry.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Soft delete default:** Default delete is archival only. Keep the transcript on disk for auditability and recovery.
- **Hard delete boundary:** Hard delete is destructive. Require the explicit `--hard` flag before removing any transcript file.
