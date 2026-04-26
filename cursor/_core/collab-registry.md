# Collab registry

`.collabs/registry.json` is the authoritative source of truth for all collab command state. Markdown transcripts under `.collabs/records/*.md` are append-only human context; they are never parsed for machine state. All routes resolve collab targets, phase, status, participants, and turn order from the registry only, using `tools/collab/registry.py` as the shared read/write helper.

## Top-level fields

| Field | Type | Description |
| --- | --- | --- |
| `schema_version` | integer | Schema revision; currently `1`. |
| `active_collab_id` | string | `id` of the currently selected collab. Empty string when no collab is active. Owned by `use`; cleared by `close` when the closed collab was active. |

## Per-collab entry fields

Each entry in the `collabs` array has the following fields.

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | Immutable internal key. Format: `<slug>-YYYY-MM-DD`. Set at `init`; never changed. |
| `slug` | string | User-facing handle. Format: lowercased, hyphen-separated words. Used in commands instead of file paths. |
| `title` | string | Human-readable name from `init`. |
| `description` | string | Brief description from `init`. |
| `status` | string | `open` \| `closed` \| `archived`. |
| `active_phase` | string | Current phase: `Audit` \| `Discussion` \| `Conclusion` \| `Action Plan` \| `Handoff` \| `Completion`. |
| `moderator_role` | string | Acronym of the moderator participant. |
| `participants` | string[] | Ordered list of registered role acronyms. |
| `turn_order` | string[] | Ordered cycle of speaking acronyms enforced by `speak`. When empty, `speak` falls back to `participants` order. |
| `transcript_path` | string | Relative path to the markdown transcript: `.collabs/records/<id>.md`. |
| `created_on` | string | ISO date `YYYY-MM-DD` set at `init`. |
| `archived` | boolean | `true` after a soft delete via `delete`. |
| `execution` | object | Keyed by role acronym. Each value: `{ "status": "in_progress" \| "completed" \| "failed", "date": "YYYY-MM-DD" }`. |

## Field ownership

Each mutable field has exactly one normal mutation path. Routes that own a field are the only ones that may write it unless an explicit recovery flag is used.

| Field | Owned by |
| --- | --- |
| `active_collab_id` | `use`; cleared by `close` |
| `status` | `close`, `open` |
| `active_phase` | `next`, `prev`; `set --force` for recovery only |
| `participants` | `join`, `kick` |
| `turn_order` | `set` |
| `title`, `description` | `set` |
| `archived` | `delete` |
| `execution.<role>` | `execute` |

## Shared helper

`tools/collab/registry.py` is the single implementation of registry read, write, and target resolution. All collab routes delegate registry access to this helper. Route specs reference it by name and do not restate the resolution algorithm.
