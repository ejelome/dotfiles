# /agent install

Install the multi-agent scaffold into the current repository from `~/.cursor/_templates/`.

## Trigger

**Slash:** `/agent install`
**Signature:** `/agent install`
**Phrases:** agent install, bootstrap multi-agent setup, install agent scaffold

## Steps

1. Resolve the repo root as the directory where the command runs. If not inside a git repository, **ABORT**: must be run from a git repository root.
2. Verify `~/.cursor/_templates/CLAUDE.md`, `~/.cursor/_templates/AGENTS.md`, and `~/.cursor/_templates/REPOSITORY.md` all exist. If any is missing, **ABORT** naming the missing path.
3. For each of `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md`, check whether the file already exists in the repo root. If any exists, **ABORT**: file already exists; name every conflicting path. Do not overwrite.
4. Copy `~/.cursor/_templates/CLAUDE.md` to `<repo-root>/CLAUDE.md`.
5. Copy `~/.cursor/_templates/AGENTS.md` to `<repo-root>/AGENTS.md`.
6. Copy `~/.cursor/_templates/REPOSITORY.md` to `<repo-root>/REPOSITORY.md`.
7. Validate scaffold-local install state: confirm `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md` exist in the repo root, confirm `CLAUDE.md` routes to `AGENTS.md`, confirm `AGENTS.md` references `~/.cursor/_CURSOR.md`, confirm `AGENTS.md` contains the canonical prose dispatch sentence (the line beginning `To invoke a global Cursor command, use the prose dispatch form`), confirm `AGENTS.md` contains the `<!-- scaffold-version: <ISO-date> -->` marker line, and confirm `REPOSITORY.md` still contains unresolved `<!-- TODO(agent): ... -->` placeholders.
8. Report the three files written and list any unresolved `<!-- TODO(agent): ... -->` placeholders remaining in `REPOSITORY.md`.

## Notes

- **Placeholder standard:** Template files use `<!-- TODO(agent): <description> -->` to mark sections requiring repo-specific authoring. Run `/agent patch` after install to fill these sections.
- **Parameters:** none. Default target is the repo root where the command runs.
- **Examples:** `/agent install`.
- **Boundary:** Writes only `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md` to the repo root. Does not write to `~/.cursor/`, does not modify agent settings JSON, and does not depend on `./link.sh` or the dotfiles runtime smoke-check.
- **Validation:** The install workflow uses scaffold-local checks only: file presence, `CLAUDE.md` → `AGENTS.md` routing, the `AGENTS.md` reference to `~/.cursor/_CURSOR.md`, the `AGENTS.md` prose dispatch sentence, and unresolved `REPOSITORY.md` placeholders.
- **Scaffold version marker:** The `<!-- scaffold-version: ... -->` marker line is present in `~/.cursor/_templates/AGENTS.md` and copied verbatim to the installed `AGENTS.md`. This marker is the version identity used by `/agent upgrade` to detect when an upgrade is needed.
- **Next step:** Run `/agent patch` to fill `<!-- TODO(agent): ... -->` placeholders in `REPOSITORY.md` with repo-specific mutation protocol and ownership rules.
