# QA — cursor _settings

Deterministic QA for Cursor User settings sources and their linked runtime JSON files.

## Procedure

1. Load every `*.json` under the tracked source directory `cursor/_settings/`.
2. Validate the source roster is exact.
3. Validate each source file is valid JSON and <= 250 lines.
4. Validate runtime mode links each source file to the Cursor User directory, not to `~/.cursor/_settings/`.
5. Validate no path-like values reference parent-repo authoring-only folders (`../`, `cursor/_core`, `~/.cursor/_core`).

## Required roster

Tracked Cursor User settings source files under `cursor/_settings/`:

- `settings.json`
- `keybindings.json`

Runtime Cursor User settings targets mirror the same filenames in the Cursor User directory.

## Output

Return pass/fail per check and list exact failing file paths.
