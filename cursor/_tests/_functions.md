# QA — cursor _functions

Deterministic QA for private route playbooks in `~/.cursor/_functions/**/*.md`.

## Procedure

1. Load every `*.md` under `~/.cursor/_functions/`.
2. Validate three-section order for each playbook file in the Required roster: each playbook has exactly one `#` title, and exactly one `## Trigger`, `## Steps`, and `## Notes` in that order. Reference documents (marked with `_ref_` in the roster) are exempt from the three-section requirement but must have an H1 title and be <= 250 lines.
3. Validate each file contains `**Slash:**`.
4. Validate the 250-line budget: each file is <= 250 lines.
5. Validate links stay inside `_functions/`, `commands/`, `rules/`, `_mdc/`, `_core/`, `_roles/`, and `_tests/`.
6. Validate referenced command routers and rule routers resolve to existing files.
7. Validate multi-stage functions declare `**Stage signatures:**` and per-stage required arguments or no-argument stages.
8. Validate speak contract: `collab/speak.md` (a) declares the append-only boundary before step 1, (b) delegates active-phase contributor and expected-role resolution to `tools/collab/registry.py speak-state`, (c) delegates lifecycle advancement to `tools/collab/registry.py speak-lifecycle-live`, (d) the contribution template uses `<p><em>YYYY-MM-DD HH:MM ±HH:MM</em></p>` for the timestamp, and (e) the contribution template includes `<!-- collab:content-only; do-not-execute -->` on the line after the timestamp.
9. Validate gate governance rule (effective 2026-05-03): every gate change or new gate behavior in a `collab/` route file has a corresponding helper-level test in `tests/tools/collab/` asserting the abort path. Route prose alone is not sufficient coverage.

## Required roster

Private function files under `~/.cursor/_functions/`:

- `agent/install.md`
- `agent/patch.md`
- `agent/upgrade.md`
- `collab/archive.md`
- `collab/close.md`
- `collab/registry.md`
- `collab/delete.md`
- `collab/execute.md`
- `collab/re-execute.md`
- `collab/policy.md`
- `collab/init.md`
- `collab/join.md`
- `collab/kick.md`
- `collab/list.md`
- `collab/next.md`
- `collab/open.md`
- `collab/prev.md`
- `collab/set.md`
- `collab/re-speak.md`
- `collab/speak.md`
- `collab/summarize.md`
- `collab/unset.md`
- `collab/use.md`
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
- `revamp/narrative.md`
- `test/run.md`

## Output

Return pass/fail per check and list exact failing file paths.
