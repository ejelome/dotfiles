# /collab

Route moderated collaboration-record workflows through one public slash command.

## Trigger

**Slash:** `/collab`
**Signature:** `/collab <init | join | speak | re-speak | next | prev | set | unset | list | use | open | close | kick | archive | delete | summarize | execute | re-execute | policy>`
**Phrases:** collab workflow, collaboration record, moderated agent discussion

## Steps

1. Resolve `<init | join | speak | re-speak | next | prev | set | unset | list | use | open | close | kick | archive | delete | summarize | execute | re-execute | policy>` from the first token after `/collab`. If missing or invalid, **ABORT** naming the token received.
2. Load `../_functions/collab/<route>.md` from the Cursor config root.
3. Execute that route with the remaining user input and attachments.

## Notes

- **Route:** `init` -> [_functions/collab/init](../_functions/collab/init.md); `join` -> [_functions/collab/join](../_functions/collab/join.md); `speak` -> [_functions/collab/speak](../_functions/collab/speak.md); `re-speak` -> [_functions/collab/re-speak](../_functions/collab/re-speak.md); `next` -> [_functions/collab/next](../_functions/collab/next.md); `prev` -> [_functions/collab/prev](../_functions/collab/prev.md); `set` -> [_functions/collab/set](../_functions/collab/set.md); `unset` -> [_functions/collab/unset](../_functions/collab/unset.md); `list` -> [_functions/collab/list](../_functions/collab/list.md); `use` -> [_functions/collab/use](../_functions/collab/use.md); `open` -> [_functions/collab/open](../_functions/collab/open.md); `close` -> [_functions/collab/close](../_functions/collab/close.md); `kick` -> [_functions/collab/kick](../_functions/collab/kick.md); `archive` -> [_functions/collab/archive](../_functions/collab/archive.md); `delete` -> [_functions/collab/delete](../_functions/collab/delete.md); `summarize` -> [_functions/collab/summarize](../_functions/collab/summarize.md); `execute` -> [_functions/collab/execute](../_functions/collab/execute.md); `re-execute` -> [_functions/collab/re-execute](../_functions/collab/re-execute.md); `policy` -> [_functions/collab/policy](../_functions/collab/policy.md).
- **Parameters:** `<init | join | speak | re-speak | next | prev | set | unset | list | use | open | close | kick | archive | delete | summarize | execute | re-execute | policy>` — required route selector.
- **Examples:** `/collab init "Slash Command UX and DX Polish"`, `/collab join --role tw`, `/collab use slash-command-ux-and-dx-polish`, `/collab set turn-order tw pe`, `/collab unset reviewer`, `/collab speak`, `/collab re-speak`, `/collab prev`, `/collab list`, `/collab archive 1`, `/collab delete slash-command-ux-and-dx-polish`, `/collab execute`, `/collab re-execute`.
- **Registry model:** `.collabs/registry.json` is the command-owned source of truth. It stores one top-level `activeCollabId` pointer plus a `collabs[]` roster keyed by stable `id` and user-facing `slug`. Transcript files under `.collabs/records/*.md` mirror selected metadata for human context only.
- **Lifecycle:** `init` → `join × N` → `speak × N` → `next` / `prev` / `set` → `close` (or `execute` then `close` for action-plan collabs). Use `list` and `use` for active-collab management instead of filesystem navigation.
- **Boundary:** `/collab` maintains a registry-backed collab transcript. `/collab execute` and `/collab re-execute` are the exceptions: they implement action-plan items assigned to the executing agent's role, run repository validation, and record the result. All other routes mutate registry state and sync the transcript only.
