# QA — cursor commands

Deterministic QA for public slash routers in `~/.cursor/commands/*.md`.

## Procedure

1. Load every `*.md` under `~/.cursor/commands/`.
2. Validate each file has exactly one `#` title, and exactly one `## Trigger`, `## Steps`, and `## Notes` in that order.
3. Validate P9: every public command file except `commands.md` contains `**Slash:**`.
4. Validate each file is <= 250 lines.
5. Validate public routers (`revamp.md`, `docs.md`, `git.md`, `eval.md`, `test.md`) resolve routes to grouped function paths.
6. Validate catalog integrity: `commands.md` links every public command file.
7. Validate catalog integrity: the generated roster block in `commands.md` matches filesystem state (`tools/cursor/sync-commands-catalog.sh --check`).
8. Validate command links stay inside `commands/`, `_functions/`, `rules/`, `_mdc/`, and `_tests/`.
9. Validate dependencies align with rule routers (`rules/auto.mdc`, `rules/shared.mdc`) and private rule bodies (`_mdc/auto/*.mdc`, `_mdc/shared/*.mdc`).

## Required roster

Public command files under `~/.cursor/commands/`:

- `agent.md`
- `commands.md`
- `collab.md`
- `docs.md`
- `eval.md`
- `git.md`
- `revamp.md`
- `test.md`

## Output

Return a pass/fail report by check (`P1..Pn`) and list exact file paths for failures.

## Secondary validation

When environment allows, run:

- `./tests/run.sh`
- `./tools/smoke-check.sh`
