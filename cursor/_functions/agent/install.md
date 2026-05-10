# /agent install

Install the multi-agent scaffold into the current repository from `~/.cursor/_templates/`.

## Trigger

**Slash:** `/agent install`
**Signature:** `/agent install [--force]`
**Prose dispatch:** `(agent install [--force])` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** agent install, bootstrap multi-agent setup, install agent scaffold

## Steps

1. Resolve the repo root as the directory where the command runs. If not inside a git repository, **ABORT**: must be run from a git repository root.
2. Verify `~/.cursor/_templates/CLAUDE.md`, `~/.cursor/_templates/AGENTS.md`, and `~/.cursor/_templates/REPOSITORY.md` all exist. If any is missing, **ABORT** naming the missing path.
3. Parse flags immediately after the route selector and before any positional arguments per [cursor/_core/command-argument.md](../../_core/command-argument.md). `--force` is supported only in that pre-positional slot. Unsupported or misplaced flags **ABORT** before any route mutation.
4. For each of `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md`, check whether the file already exists in the repo root. If any exists and `--force` is absent, **ABORT**: file already exists; name every conflicting path. Do not overwrite.
5. When `--force` is supplied and any scaffold file exists, compute `the candidate patch` for all three scaffold writes, render the diff from `the candidate patch`, and gate the write per [cursor/_core/command-argument.md](../../_core/command-argument.md):

   ```cursor-gate
   gate-class: standard
   proceed: confirm
   abort: cancel
   operand-format: none
   invalid-input: re-prompt
   re-prompt-template: Type "confirm" to overwrite scaffold files, or "cancel" to abort.
   ```

   If the user does not type the exact proceed token, leave all files untouched. If confirmed, continue to the copy steps.
6. Copy `~/.cursor/_templates/CLAUDE.md` to `<repo-root>/CLAUDE.md`.
7. Copy `~/.cursor/_templates/AGENTS.md` to `<repo-root>/AGENTS.md`.
8. Copy `~/.cursor/_templates/REPOSITORY.md` to `<repo-root>/REPOSITORY.md`. When `--force` is supplied, these copy steps apply `the candidate patch` without recomputation or re-read of source.
9. Validate scaffold-local install state: confirm `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md` exist in the repo root, confirm `CLAUDE.md` routes to `AGENTS.md`, confirm `AGENTS.md` references `~/.cursor/_CURSOR.md`, confirm `AGENTS.md` contains the canonical routing-only prose dispatch sentence (the line beginning `To invoke a global Cursor command, resolve any routing-only prose dispatch hint`), confirm `AGENTS.md` contains the `<!-- scaffold-version: <ISO-date> -->` marker line, confirm `REPOSITORY.md` still contains unresolved `<!-- TODO(agent): ... -->` placeholders, and confirm every Markdown link in the installed `AGENTS.md` whose target does not begin with `~` or `http` resolves as a file path relative to the repo root; if any link does not resolve, **ABORT** naming the unresolvable path.
10. Report the three files written and list any unresolved `<!-- TODO(agent): ... -->` placeholders remaining in `REPOSITORY.md`.

## Notes

- **Precondition:** The global Cursor command surface (`~/.cursor/`) must be reachable before this route is invoked. In environments without it on the command path, invoke explicitly (e.g., `~/.cursor/...`) on first use. The requirement is reachability; the invocation form depends on the agent surface.
- **Placeholder standard:** Template files use `<!-- TODO(agent): <description> -->` to mark sections requiring repo-specific authoring. Run `/agent patch` after install to fill these sections.
- **Parameters:** `--force` — optional pre-positional flag. Default target is the repo root where the command runs.
- **Examples:** `/agent install`, `/agent install --force`.
- **Boundary:** Writes only `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md` to the repo root. Does not write to `~/.cursor/`, does not modify agent settings JSON, and does not depend on `./link.sh` or the dotfiles runtime smoke-check.
- **Validation:** The install workflow uses scaffold-local checks only: file presence, `CLAUDE.md` → `AGENTS.md` routing, the `AGENTS.md` reference to `~/.cursor/_CURSOR.md`, the `AGENTS.md` prose dispatch sentence, and unresolved `REPOSITORY.md` placeholders.
- **Force flag:** `--force` is eligible only for existing scaffold-file conflicts. It does not bypass missing-template, repository-root, validation, or permission failures.
- **Scaffold version marker:** The `<!-- scaffold-version: ... -->` marker line is present in `~/.cursor/_templates/AGENTS.md` and copied verbatim to the installed `AGENTS.md`. This marker is the version identity used by `/agent upgrade` to detect when an upgrade is needed.
- **Next step:** Run `/agent patch` to fill `<!-- TODO(agent): ... -->` placeholders in `REPOSITORY.md` with repo-specific mutation protocol and ownership rules.

```cursor-arg
dispatch: (agent install [--force])
param: name=--force; required=optional; placeholder=--force; class=literal; values=present
```

```cursor-flag
flag: force
eligibility: eligible
guard-class: hard-abort
```
