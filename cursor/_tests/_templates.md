# QA — cursor _templates

Deterministic QA for scaffold template sources projected to `~/.cursor/_templates/`.

## Procedure

1. Load every `*.md` under the tracked source directory `cursor/_templates/`.
2. Validate the source roster is exact.
3. Validate each template file has one H1 and is <= 250 lines.
4. Validate `CLAUDE.md` is routing-only and points to `AGENTS.md`.
5. Validate `AGENTS.md` references `~/.cursor/_CURSOR.md` and `REPOSITORY.md`.
6. Validate `REPOSITORY.md` contains `<!-- TODO(agent): ... -->` placeholders for repo-specific authoring.

## Required roster

Tracked scaffold template files under `cursor/_templates/`:

- `CLAUDE.md`
- `AGENTS.md`
- `REPOSITORY.md`

## Output

Return pass/fail per check and list exact failing file paths.
