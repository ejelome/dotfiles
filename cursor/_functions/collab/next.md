# /collab next

Open the next moderator-selected phase in a collaboration record and update the active phase metadata.

## Trigger

**Slash:** `/collab next`
**Signature:** `/collab next`
**Phrases:** collab next, next collaboration phase, advance collab record

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
4. Resolve the current phase from registry `active_phase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. Resolve the next phase from **Phase sequence** in **Notes**. If no next phase exists, **ABORT**: no next phase; sequence exhausted.
6. Update registry `active_phase` to the next phase.
7. Mirror the new phase in the transcript `**Active phase:**` metadata line.
8. Ensure the next phase heading exists. If missing, append it at the end of the transcript.
9. Stop after updating registry and transcript. Do not write a participant contribution.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `next`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Phase sequence:** `Audit` -> `Discussion` -> `Conclusion` -> `Action Plan` -> `Handoff` -> `Completion`.
- **Moderator gate:** The moderator decides when this route runs. The route never checks whether participants have said enough.
