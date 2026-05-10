# QA — cursor _generated

Deterministic QA for generated Cursor artifacts projected to `~/.cursor/_generated/`.

## Procedure

1. Load every `*.md` under the tracked source directory `cursor/_generated/`.
2. Validate the source roster is exact.
3. Validate each generated file has one H1 and is <= 250 lines.
4. Validate each generated file names its generator and source-of-truth pattern.
5. Validate `tools/collab/lifecycle-doc.py --check` passes for `collab-lifecycle.md`.

## Required roster

Tracked generated files under `cursor/_generated/`:

- `collab-lifecycle.md`

## Output

Return pass/fail per check and list exact failing file paths.
