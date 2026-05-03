# /collab join

Register one participant in the active collaboration record from command-owned role JSON.

## Trigger

**Slash:** `/collab join`
**Signature:** `/collab join --role <role>`
**Phrases:** collab join, join collaboration record, register collab role

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Resolve `<role>` from `--role <role>`. If missing, **ABORT**: `--role <role>` is required.
3. Read `../../_roles/<role>.json`. If unreadable, **ABORT**: role file unreadable; name the expected path.
4. Validate the role JSON against **Role schema** in **Notes**. If invalid, **ABORT**: invalid role JSON; name the failed field.
5. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
6. If the registry status is `closed` or `archived`, **ABORT**: record is closed.
7. Append `<role>` to the registry `participants` list when missing. If the role already exists, leave the registry roster unchanged.
8. If the registry `turnOrder` is empty, seed it from `participants`, excluding `reviewerRole` when `reviewerMode` is `last-in-convergent-phases`. If the role is new, `turnOrder` exists, and the role is not that reviewer, append the role at the end.
9. Call `tools/collab/registry.py join-participants <target>`. The helper validates all role files, computes the next registry participants and turn order in memory, renders the full participants table from that state, then writes registry and transcript together. Abort if any role file is missing or unreadable before either file is written. The helper also persists the joining agent's self-declared `agentId` to the participant entry in the registry.
10. Sync the Turn order cell in the transcript state table from registry `turnOrder` after any registry or transcript participant update.
11. Stop after updating registry and transcript participants. Do not write a phase contribution.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first positional token after `join`; when absent, resolved per **Registry targeting** in **Notes**. `--role <role>` — required role key.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Role schema:** Defined in [cursor/_core/role.md](../../_core/role.md). Required fields: `key` (must match `<role>`), `displayName`, `concerns` (non-empty array).
- **Participant row format:** `| <#> | <key> | <displayName> | <agentId> | <concern>; <concern> |`. The table header is `| # | Key | Role | Agent | Responsibilities |`. `<agentId>` is the model identifier the joining agent self-declares at join time — not a value read from the role JSON.
- **Pending reviewer display:** When `reviewerRole` is set in the registry but that role is not yet in `participants`, the transcript **Reviewer** section marks the role as `(pending)`. The `(pending)` state is registry-owned — derived from `reviewerRole` not being in `participants` — not from transcript prose. Once the reviewer joins via `/collab join`, the `(pending)` label is replaced with the active reviewer notice.
- **Pending-reviewer speak gate:** A pending `reviewerRole` blocks all participant speaks. `speak-state` aborts before turn-order checks when `reviewerRole` is set and absent from `participants`. The reviewer must join via `/collab join --role <reviewer>` or be cleared via `/collab set reviewer --clear` before any participant may contribute.
- **Role data boundary:** Role JSON files live under `cursor/_roles/` as shared command-owned data, not route playbooks.
- **Section-targeting convention:** A `render-*` helper owns exactly one transcript section identified by its visible heading, takes registry state and role JSON as its only inputs, and fails before any write when input validation fails.
- **`render-participants` boundary:** `render-participants` is a repair and diagnostics subcommand. Do not call it in route prose; the normal join path uses `join-participants`.
- **`participant` disposition:** The `participant` subcommand is deprecated. Its job is subsumed by `join-participants`. Do not use it in new routes.
- **Recovery path:** If `join-participants` aborts due to a missing or unreadable role file, remove the orphaned key from registry `participants` or restore the role file, then re-run `/collab join`.
- **One-time normalization:** On the first `/collab join` after `join-participants` is deployed, the full participants table is regenerated from registry state; any hand-edits that diverged from the registry are replaced. This is expected behavior.
- **After joining:** Run `/collab policy` before your first `/collab speak` to read the gate rules and reviewer contract for this collab.
