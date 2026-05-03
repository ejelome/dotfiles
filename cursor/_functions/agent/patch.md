# /agent patch

Patch `REPOSITORY.md` in the current repository with repo-specific multi-agent mutation protocol and ownership rules.

## Trigger

**Slash:** `/agent patch`
**Signature:** `/agent patch`
**Phrases:** agent patch, patch repository, fill agent placeholders

## Steps

1. Resolve the repo root as the directory where the command runs.
2. Verify `REPOSITORY.md` exists in the repo root. If absent, **ABORT**: `REPOSITORY.md` not found; run `/agent install` first.
3. Read `REPOSITORY.md` in full.
4. Locate all `<!-- TODO(agent): <description> -->` placeholders. If none are found, **ABORT**: no `<!-- TODO(agent): ... -->` placeholders found; `REPOSITORY.md` may already be patched or was not installed via `/agent install`.
5. For each placeholder, infer repo-specific content from the current repository context (project name, source layout, validation commands), using the `<description>` as the inference prompt. Display all inferred values. Ask the user to confirm before writing any section. For placeholders that cannot be inferred, ask the user explicitly before proceeding.
6. Replace each `<!-- TODO(agent): <description> -->` marker with the supplied repo-specific content. Do not edit any text outside placeholder blocks.
7. Write the updated `REPOSITORY.md`.
8. Validate scaffold-local patch state: confirm `REPOSITORY.md` still exists and no `<!-- TODO(agent): ... -->` markers remain.
9. Report each placeholder resolved and confirm no `<!-- TODO(agent): ... -->` markers remain.

## Notes

- **Placeholder standard:** Sections requiring repo-specific content are marked `<!-- TODO(agent): <description> -->`. Only these markers are replaced; all surrounding text is preserved exactly.
- **Idempotency:** Re-running patch on a `REPOSITORY.md` with no remaining placeholders aborts at step 4 rather than producing duplicate sections or overwriting custom content.
- **Parameters:** none. Default target is `REPOSITORY.md` in the repo root.
- **Examples:** `/agent patch`.
- **Boundary:** Edits `REPOSITORY.md` only. Does not touch `CLAUDE.md`, `AGENTS.md`, `~/.cursor/`, or agent settings JSON.
- **Validation:** The patch workflow validates scaffold-local state only: `REPOSITORY.md` remains present and every `<!-- TODO(agent): ... -->` marker is resolved after the write.
- **Confirm-before-write:** `patch.md` is a confirm-before-write route; the confirmation step is mandatory and not optional for any placeholder.
