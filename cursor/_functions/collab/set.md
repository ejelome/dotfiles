# /collab set

Update collab metadata fields that do not already belong to a dedicated mutation route.

## Trigger

**Slash:** `/collab set`
**Signature:** `/collab set <field> <value>`; or `/collab set reviewer <role>` / `/collab set reviewer --clear`
**Phrases:** collab set, set collaboration metadata, update collab metadata

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Resolve `<field>` from the next positional token after `set`. If missing, **ABORT**: `<field>` is required.
3. Resolve `<value>` from all remaining input after `<field>`, excluding an optional leading `--force` flag. If missing after trimming whitespace, **ABORT**: `<value>` is required.
4. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
5. Validate field ownership against **Field ownership** in **Notes**. If `<field>` is not settable in the current mode, **ABORT**: field not settable; name the field and owning route.
6. Apply the field update in the registry:
   - `title` updates the registry title and transcript H1.
   - `description` updates the registry description and the transcript opening description.
   - `turn-order` parses space-separated role keys, validates uniqueness and membership in registry `participants`, validates that no key equals `reviewerRole`, then updates registry `turnOrder` and the Turn order cell in the transcript state table.
   - `reviewer <role>` validates that `<role>` is in registry `participants`, that `<role>` does not equal `moderatorRole`, and that `<role>` is not in registry `turnOrder`; then sets registry `reviewerRole` to `<role>` with default `reviewerMode` (`last-in-convergent-phases`) and default `reviewerOptionalPhases` (`["Discussion"]`), and mirrors the value in the Reviewer cell of the transcript status table via `tools/collab/registry.py render-status`.
   - `reviewer --clear` removes `reviewerRole`, `reviewerMode`, and `reviewerOptionalPhases` from the registry entry and updates the transcript status table.
   - `active-phase` is recovery-only: require `--force`, validate against the phase sequence, then update registry `activePhase` and the Active phase cell in the transcript state table.
7. Stop after updating registry and transcript. Do not append a contribution.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `set`; when absent, resolved per **Registry targeting** in **Notes**. `<field>` — required metadata field name. `<value>` — required replacement value (omit for `reviewer --clear`). `--force` — optional recovery-only override for fields that are normally owned elsewhere.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Field ownership:** `title` -> `set`; `description` -> `set`; `turn-order` -> `set`; `reviewer` -> `set`; `status` -> `open` / `close`; `participants` -> `join` / `kick`; `active-phase` -> `next` / `prev` (or `set --force` for recovery only).
- **Ownership boundary:** Every mutable field has exactly one normal mutation path. `/collab set` must refuse fields owned by another route unless `--force` is used for recovery-only metadata repair.
