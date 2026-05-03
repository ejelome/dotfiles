# /collab use

Select the active collab in the registry so subsequent routes do not need an explicit target token.

## Trigger

**Slash:** `/collab use`
**Signature:** `/collab use <record>`
**Phrases:** collab use, select active collab, switch active collaboration

## Steps

1. Resolve `<record>` from the next positional token after `use`. If missing, **ABORT**: `<record>` is required.
2. Read `.collabs/registry.json`. If unreadable, **ABORT**: registry unreadable; name the path.
3. Resolve `<record>` against collab `slug`, `id`, or stable numeric position. If no entry matches, **ABORT**: registry target unavailable; name the token.
4. If the matched collab is archived, **ABORT**: registry target archived; name the token.
5. Write the matched collab id to `activeCollabId`.
6. Stop after selecting the active collab. Do not modify the transcript.

## Notes

- **Parameters:** `<record>` — required collab slug, id, or numeric `#N`.
- **Active selection model:** `.collabs/registry.json` stores one top-level `activeCollabId` pointer. `/collab use` is the only normal route that changes that pointer directly.
