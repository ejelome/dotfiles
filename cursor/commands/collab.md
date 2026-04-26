# /collab

Route moderated collaboration-record workflows through one public slash command.

## Trigger

**Slash:** `/collab`
**Signature:** `/collab <init | join | speak | next | prev | set | list | use | open | close | kick | delete | summarize | execute>`
**Phrases:** collab workflow, collaboration record, moderated agent discussion

## Steps

1. Resolve `<init | join | speak | next | prev | set | list | use | open | close | kick | delete | summarize | execute>` from the first token after `/collab`. If missing or invalid, **ABORT** naming the token received.
2. Load `../_functions/collab/<route>.md` from the Cursor config root.
3. Execute that route with the remaining user input and attachments.

## Notes

- **Route:** `init` -> [_functions/collab/init](../_functions/collab/init.md); `join` -> [_functions/collab/join](../_functions/collab/join.md); `speak` -> [_functions/collab/speak](../_functions/collab/speak.md); `next` -> [_functions/collab/next](../_functions/collab/next.md); `prev` -> [_functions/collab/prev](../_functions/collab/prev.md); `set` -> [_functions/collab/set](../_functions/collab/set.md); `list` -> [_functions/collab/list](../_functions/collab/list.md); `use` -> [_functions/collab/use](../_functions/collab/use.md); `open` -> [_functions/collab/open](../_functions/collab/open.md); `close` -> [_functions/collab/close](../_functions/collab/close.md); `kick` -> [_functions/collab/kick](../_functions/collab/kick.md); `delete` -> [_functions/collab/delete](../_functions/collab/delete.md); `summarize` -> [_functions/collab/summarize](../_functions/collab/summarize.md); `execute` -> [_functions/collab/execute](../_functions/collab/execute.md).
- **Parameters:** `<init | join | speak | next | prev | set | list | use | open | close | kick | delete | summarize | execute>` — required route selector.
- **Examples:** `/collab init collab slash command optimized`, `/collab join --role tw`, `/collab use collab-slash-command-optimized`, `/collab set turn-order tw pe`, `/collab speak`, `/collab prev`, `/collab list`, `/collab delete collab-slash-command-optimized --hard`, `/collab execute`.
- **Registry model:** `.collabs/registry.json` is the command-owned source of truth. It stores one top-level `active_collab_id` pointer plus a `collabs[]` roster keyed by stable `id` and user-facing `slug`. Transcript files under `.collabs/records/*.md` mirror selected metadata for human context only.
- **Lifecycle:** `init` → `join × N` → `speak × N` → `next` / `prev` / `set` → `close` (or `execute` then `close` for action-plan collabs). Use `list` and `use` for active-collab management instead of filesystem navigation.
- **Boundary:** `/collab` maintains a registry-backed collab transcript. `/collab execute` is the exception: it implements the action-plan items assigned to the executing agent's role, runs repository validation, and records the result. All other routes mutate registry state and sync the transcript only.
