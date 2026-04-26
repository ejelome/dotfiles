# QA — cursor _tests

Deterministic QA for harness docs in `~/.cursor/_tests/*.md`.

## Procedure

1. Load every `*.md` under `~/.cursor/_tests/`.
2. Validate each symlinked top-level directory under `~/.cursor/` has one same-name harness file in `~/.cursor/_tests/`.
3. Validate every harness filename maps to either a symlinked top-level `~/.cursor/` directory or an explicit non-`~/.cursor` projection harness.
4. Validate each harness file has one H1 and is <= 250 lines.
5. Validate no harness file points outside `~/.cursor/` or repository-level authorities.

## Required roster

Harness files under `~/.cursor/_tests/`:

- `commands.md`
- `rules.md`
- `_functions.md`
- `_mdc.md`
- `_core.md`
- `_settings.md`
- `_tests.md`

## Output

Return pass/fail per check and list exact failing file paths.
