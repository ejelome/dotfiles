# QA — cursor _core canon

Deterministic QA for `~/.cursor/_core/*.md` canon documents.

## Procedure

1. Load every `*.md` under `~/.cursor/_core/`.
2. Validate the roster is exact.
3. Validate each file has one H1 and is <= 250 lines.
4. Validate links in `_core/` stay self-contained (sibling `_core/*.md` links only).
5. Validate no `_core` file depends on `commands/`, `_functions/`, `rules/`, `_mdc/`, `_tests/`, or host runtime paths.
6. Validate owner consistency: style, document templates, command contract, context model, and voice guide do not conflict.

## Required roster

- `agents.md`
- `command.md`
- `context.md`
- `document.md`
- `role.md`
- `style.md`
- `voice.md`

## Output

Return pass/fail per check and list exact failing file paths.
