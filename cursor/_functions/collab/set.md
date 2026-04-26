# /collab set

Update collab metadata fields that do not already belong to a dedicated mutation route.

## Trigger

**Slash:** `/collab set`
**Signature:** `/collab set <field> <value>`
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
   - `turn-order` parses space-separated role acronyms, validates uniqueness and membership in registry `participants`, then updates registry `turn_order` and transcript `**Turn order:**`.
   - `active-phase` is recovery-only: require `--force`, validate against the phase sequence, then update registry `active_phase` and transcript `**Active phase:**`.
7. Stop after updating registry and transcript. Do not append a contribution.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `set`; when absent, resolved per **Registry targeting** in **Notes**. `<field>` — required metadata field name. `<value>` — required replacement value. `--force` — optional recovery-only override for fields that are normally owned elsewhere.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Field ownership:** `title` -> `set`; `description` -> `set`; `turn-order` -> `set`; `status` -> `open` / `close`; `participants` -> `join` / `kick`; `active-phase` -> `next` / `prev` (or `set --force` for recovery only).
- **Ownership boundary:** Every mutable field has exactly one normal mutation path. `/collab set` must refuse fields owned by another route unless `--force` is used for recovery-only metadata repair.
