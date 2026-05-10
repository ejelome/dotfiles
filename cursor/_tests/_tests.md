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
- `_roles.md`
- `_generated.md`
- `_settings.md`
- `_templates.md`
- `_tests.md`

## Layer ownership

`tests/*.test.sh` owns shell-executable CI contract validation; `cursor/_tests/*.md` owns agent-facing policy for the `/test` command surface.

Neither layer may be reduced without updating this statement to name the resulting ownership per layer.

**Test removal criteria:** Before any test file under `tests/` is removed, its inventory row must satisfy all of:

- `CONTRACT` names a specific surface (not a category label)
- `OWNER: central-checker` and the central checker test exercises that same surface
- `TYPE` ∈ {`structure`, `prose-duplicate`}
- For golden-file rows additionally: replacement checks land in the same batch, including a stable generate-and-compare check confirming the committed artifact does not drift from generator output

**tw sign-off gate:** `CONTRACT` must name a specific surface for every deletion row before tw approves. Category labels such as "golden file" or "doc contract" are not acceptable `CONTRACT` values.

## Output

Return pass/fail per check and list exact failing file paths.
