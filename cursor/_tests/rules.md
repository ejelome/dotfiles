# QA — cursor rules

Deterministic QA for public rule routers in `~/.cursor/rules/*.mdc`.

## Procedure

1. Load every `*.mdc` under `~/.cursor/rules/`.
2. Validate each file has one H1 title and is <= 250 lines.
3. Validate each file has `**Triggers:**` and valid front matter (`description`, `alwaysApply`).
4. Validate `rules/auto.mdc` links the private auto bundle under `../_mdc/auto/`.
5. Validate `rules/shared.mdc` links the private shared bundle under `../_mdc/shared/`.
6. Validate references stay inside `rules/`, `_mdc/`, and `_core/`.
7. Validate no required dependency points to `commands/`, `_functions/`, or external paths.

## Required roster

Public rule routers under `~/.cursor/rules/`:

- `auto.mdc`
- `shared.mdc`

## Output

Return pass/fail per check and list exact failing file paths.
