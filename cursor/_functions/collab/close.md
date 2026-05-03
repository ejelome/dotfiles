# /collab close

Mark a collaboration record closed so contribution and phase-advance routes stop writing to it.

## Trigger

**Slash:** `/collab close`
**Signature:** `/collab close [--no-summary]`
**Phrases:** collab close, close collaboration, end collab record

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed`, report that the record is already closed and stop.
4. Update the registry status to `closed`.
5. Update the Status cell in the transcript state table from `open` to `closed`.
6. If the closing collab id matches `activeCollabId`, clear `activeCollabId`. Do not change the active pointer when it selects a different collab.
7. Unless `--no-summary` is passed, generate a summary under `## Completion` following the `/collab summarize` spec.
8. Stop after changing the registry status, transcript status, active-pointer cleanup, and any summary.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `close`; when absent, resolved per **Registry targeting** in **Notes**. `--no-summary` — skip the automatic summary (optional).
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric `#N` position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Active cleanup:** Clearing `activeCollabId` means leaving the registry pointer empty. Subsequent routes must refuse target inference until the moderator runs `/collab use <record>` or names a target explicitly.
- **Summary default:** `/collab close` generates a summary by default. Pass `--no-summary` to close without one. `/collab summarize` remains available on closed records for an explicit standalone summary.
- **Closed-record behavior:** `/collab speak` and `/collab next` must refuse closed records.
