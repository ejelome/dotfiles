# QA — cursor _functions

Deterministic QA for private route playbooks in `~/.cursor/_functions/**/*.md`.

## Procedure

1. Load every `*.md` under `~/.cursor/_functions/`.
2. Validate three-section order: each file has exactly one `#` title, and exactly one `## Trigger`, `## Steps`, and `## Notes` in that order.
3. Validate each file contains `**Slash:**`.
4. Validate the 250-line budget: each file is <= 250 lines.
5. Validate links stay inside `_functions/`, `commands/`, `rules/`, `_mdc/`, and `_tests/`.
6. Validate referenced command routers and rule routers resolve to existing files.
7. Validate multi-stage functions declare `**Stage signatures:**` and per-stage required arguments or no-argument stages.

## Required roster

Private function files under `~/.cursor/_functions/`:

- `collab/close.md`
- `collab/delete.md`
- `collab/execute.md`
- `collab/init.md`
- `collab/join.md`
- `collab/kick.md`
- `collab/list.md`
- `collab/next.md`
- `collab/open.md`
- `collab/prev.md`
- `collab/set.md`
- `collab/speak.md`
- `collab/summarize.md`
- `collab/use.md`
- `content/revamp.md`
- `docs/assess.md`
- `docs/changelog.md`
- `docs/compact.md`
- `docs/compare.md`
- `docs/manual.md`
- `docs/readme.md`
- `eval/igd.md`
- `eval/notes.md`
- `eval/ops.md`
- `eval/tune.md`
- `eval/uid.md`
- `eval/wse.md`
- `git/commit.md`
- `git/issue.md`
- `test/run.md`

## Output

Return pass/fail per check and list exact failing file paths.
