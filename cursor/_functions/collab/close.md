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
5. Replace transcript `**Status:** open` with `**Status:** closed`.
6. If the closing collab id matches `active_collab_id`, clear `active_collab_id`. Do not change the active pointer when it selects a different collab.
7. Unless `--no-summary` is passed, generate a summary under `## Completion` following the `/collab summarize` spec.
8. Stop after changing the registry status, transcript status, active-pointer cleanup, and any summary.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `close`; when absent, resolved per **Registry targeting** in **Notes**. `--no-summary` — skip the automatic summary (optional).
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Active cleanup:** Clearing `active_collab_id` means leaving the registry pointer empty. Subsequent routes must refuse target inference until the moderator runs `/collab use <record>` or names a target explicitly.
- **Summary default:** `/collab close` generates a summary by default. Pass `--no-summary` to close without one. `/collab summarize` remains available on closed records for an explicit standalone summary.
- **Closed-record behavior:** `/collab speak` and `/collab next` must refuse closed records.
