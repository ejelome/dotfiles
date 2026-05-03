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
4. Resolve the current phase from registry `activePhase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. Resolve the next phase from **Phase sequence** in **Notes**. If no next phase exists, **ABORT**: no next phase; sequence exhausted.
6. Update registry `activePhase` to the next phase.
7. If the next phase is `Conclusion`, remove the moderator role from registry `turnOrder` and sync the Turn order cell before accepting Conclusion contributions.
8. Update the Active phase cell in the transcript state table to the new phase.
9. Ensure the next phase heading exists. If missing, append it at the end of the transcript.
10. Stop after updating registry and transcript. Do not write a participant contribution.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `next`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Phase sequence:** `Audit` -> `Discussion` -> `Conclusion` -> `Action Plan` -> `Handoff` -> `Completion`.
- **Moderator gate:** The moderator decides when this route runs. The route never checks whether participants have said enough.
