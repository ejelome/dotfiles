# /collab prev

Move the active phase back by one step in a collaboration record when the moderator needs more work in an earlier phase.

## Trigger

**Slash:** `/collab prev`
**Signature:** `/collab prev`
**Phrases:** collab prev, previous collaboration phase, rollback collab phase

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
4. Resolve the current phase from registry `activePhase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. Resolve the previous phase from **Phase sequence** in **Notes**. If no previous phase exists, **ABORT**: no previous phase; sequence exhausted.
6. Update registry `activePhase` to the previous phase.
7. Update the Active phase cell in the transcript state table to the previous phase.
8. Stop after updating registry and transcript. Never delete or rewrite existing contributions.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `prev`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Phase sequence:** `Audit` <- `Discussion` <- `Conclusion` <- `Action Plan` <- `Handoff` <- `Completion`.
- **Append-only rollback:** `/collab prev` moves only the active-phase pointer. It never removes headings, contributions, checklist items, or completion markers.
