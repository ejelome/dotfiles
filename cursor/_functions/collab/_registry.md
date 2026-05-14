# /collab registry

Reference document for the `.collabs/registry.json` schema and field ownership used by all collab routes.

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab registry schema, registry fields, collab registry reference, activeCollabId, execution field

## Steps

1. Read this document when resolving registry field semantics, ownership rules, or the shared helper contract.
2. Do not mutate registry state from this documentation-only reference.

## Notes

- **Registry contract:** `.collabs/registry.json` is the authoritative source of truth for all collab command state. Markdown transcripts under `.collabs/records/*.md` are append-only human context; they are never parsed for machine state. All routes resolve collab targets, phase, status, participants, and turn order from the registry only, using `tools/collab/registry.py` as the shared read/write helper.

- **Top-level fields:**

  | Field | Type | Description |
  | --- | --- | --- |
  | `schemaVersion` | integer | Schema revision; currently `1`. |
  | `activeCollabId` | string or null | `id` of the currently selected collab. `null` when no collab is active. Owned by `activate`; cleared by `close`, `archive`, or completion auto-close when the selected collab is no longer active. |

- **Per-collab entry fields:**

  | Field | Type | Description |
  | --- | --- | --- |
  | `id` | string | Immutable internal key. Format: `YYYY-MM-DD-<slug>`. Set at `init`; never changed. |
  | `sequence` | integer | Stable numeric selector shown by `/collab list` as `#N`. Assigned at `init` from insertion order and never reused after hard delete. |
  | `slug` | string | User-facing handle. Format: lowercased, hyphen-separated words. Used in commands instead of file paths. |
  | `title` | string | Human-readable name from `init`. |
  | `description` | string | Brief description from `init`. |
  | `status` | string | `open` \| `closed` \| `archived`. |
  | `activePhase` | string | Current phase: `Audit` \| `Discussion` \| `Conclusion` \| `Action Plan` \| `Handoff` \| `Completion`. |
  | `moderatorRole` | string | Key of the moderator participant. |
  | `participants` | `{ role: string, agentId: string }[]` | Ordered list of registered participants. Each entry records the role key and the joining agent's at-join `agentId` per [_agent-id.md](_agent-id.md). |
  | `turnOrder` | string[] | Ordered cycle of speaking keys enforced by `speak`. When empty, `speak` falls back to `participants` order. |
  | `reviewerRole` | string | Optional reviewer key for collab-level judgment passes. May be written before the role is listed in `participants`; while pending, `speak-state` aborts before turn-order checks. |
  | `reviewerMode` | string | Optional reviewer behavior mode. Initial supported value: `last-in-convergent-phases`. |
  | `reviewerOptionalPhases` | string[] | Optional phase names where the reviewer may speak without blocking the ordinary expected speaker. Defaults to `Discussion` when a reviewer is set. Mutating this field affects only the current or later active phase; it does not retroactively admit the reviewer into a phase that has already advanced. |
  | `transcriptPath` | string | Relative path to the markdown transcript: `.collabs/records/<id>.md`. |
  | `archived` | boolean | `true` after a soft delete via `archive`. |
  | `execution` | object | Keyed by role key. Each value: `{ "status": "in_progress" \| "completed" \| "failed", "date": "YYYY-MM-DD", "validationResult"?: string, "validationScope"?: "scoped" \| "full" \| "deferred", "touchedPaths"?: string[] }`. `in_progress` is reserved for true pre-work async dispatch or necessary retry trace; default successful execution records are `completed` with validation scope and touched paths. |

- **Reviewer invariants:** When `reviewerRole` is set, it may be absent from `participants` while assignment is deferred, must not equal `moderatorRole`, and must not appear in ordinary `turnOrder` while `reviewerMode` is `last-in-convergent-phases`. `speak-state` aborts before turn-order checks while the reviewer is pending. After the reviewer role is listed in `participants`, `speak-state` computes reviewer-aware expected speakers: in `Audit` and `Conclusion`, ordinary turn-order roles speak first and the reviewer speaks last once; in phases listed by `reviewerOptionalPhases`, the reviewer is optional and admitted only at the tail of a completed ordinary round.

- **Transcript status rendering:** `tools/collab/registry.py render-status <target>` renders the transcript status table from registry state, including the `Reviewer` cell. Render `—` when no reviewer is set. Route playbooks should delegate status-table mirroring to this helper rather than manually owning reviewer cells.

- **Role catalog:** `tools/collab/registry.py roles --roles-dir <dir>` validates role JSON files and emits stable participant rows for public role-discovery surfaces.

- **Execution boundary helpers:** `tools/collab/registry.py write-guard <route> <path>...` centralizes the write boundary: routes other than `execute` may write only under `.collabs/`. `execution` records may include `validationResult`, `validationScope`, and `touchedPaths` so `/collab run plan` can preserve validation and blast-radius metadata.

- **Field ownership:**

  | Field | Owned by |
  | --- | --- |
  | `activeCollabId` | `activate`; cleared by `close` |
  | `status` | `close`, `open`, `archive`, `execute` auto-close |
  | `activePhase` | `next`, `prev`; `set --force` for recovery only |
  | `participants` | `join`, `kick` |
  | `turnOrder` | `set` |
  | `reviewerRole`, `reviewerMode`, `reviewerOptionalPhases` | `set`, `unset`, `init`; helper validation |
  | `title`, `description` | `set` |
  | `archived` | `archive` |
  | `execution.<role>` | `execute` |

- **Shared helper:** `tools/collab/registry.py` is the single implementation of registry read, write, and target resolution. All collab routes delegate registry access to this helper. Route specs reference it by name and do not restate the resolution algorithm.
