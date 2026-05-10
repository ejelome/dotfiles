# QA — cursor _roles

Deterministic QA for shared role JSON sources projected to `~/.cursor/_roles/`.

## Procedure

1. Load every `*.json` under the tracked source directory `cursor/_roles/`.
2. Validate the source roster is exact.
3. Validate each source file is valid JSON and uses the role schema in `cursor/_core/agent-role.md`.
4. Validate each filename stem equals its `key`.
5. Validate keys are globally unique.
6. Validate runtime mode copies `cursor/_roles/` to `~/.cursor/_roles/`.

## Required roster

Tracked role source files under `cursor/_roles/`:

- `mod.json`
- `pa.json`
- `pe.json`
- `tw.json`

## Output

Return pass/fail per check and list exact failing file paths.
