# QA — cursor _mdc

Deterministic QA for private rule bodies in `~/.cursor/_mdc/**/*.mdc`.

## Procedure

1. Load every `*.mdc` under `~/.cursor/_mdc/auto/` and `~/.cursor/_mdc/shared/`.
2. Validate each file has one H1 title and is <= 250 lines.
3. Validate each file has `**Triggers:**` and valid front matter (`description`, `alwaysApply`).
4. Validate `rules/auto.mdc` links every file under `_mdc/auto/`.
5. Validate `rules/shared.mdc` links every file under `_mdc/shared/`.
6. Validate references stay inside `_mdc/`, `rules/`, and `_core/`.
7. Validate no required dependency points to `commands/`, `_functions/`, or external paths.

## Required rosters

Private auto rules under `~/.cursor/_mdc/auto/`:

- `auto-code-typescript.mdc`
- `auto-collab-format.mdc`
- `auto-context-gate.mdc`
- `auto-docs-markdown.mdc`

Private shared rules under `~/.cursor/_mdc/shared/`:

- `shared-cmd-quality.mdc`
- `shared-cmd-values.mdc`
- `shared-docs-precedence.mdc`
- `shared-docs-rules.mdc`
- `shared-docs-toc.mdc`
- `shared-docs-voice.mdc`
- `shared-git-commits.mdc`

## Output

Return pass/fail per check and list exact failing file paths.
