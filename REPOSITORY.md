# Repository Contract

Contract between this repository (source plane) and the global Cursor runtime at `~/.cursor/*`.

## 1) System Model

The contract has three planes:

- **Source plane:** version-controlled files in this repository.
- **Global runtime plane:** `~/.cursor/*`.
- **Project overlay plane:** optional project-local `.cursor/`.

Only the source plane is authoritative. Runtime planes are derived execution contexts.

## 2) Authority Chain

Authority is strict and ordered:

1. Repo-owned executable checks and scripts:
   - `tools/lib/link-targets.sh`
   - `tools/lib/cursor-layout.sh`
   - `tools/smoke-check.sh`
   - `tools/check-agent-adapters.sh`
   - `tools/check-cursor-content.sh`
2. Repo-owned source files and policy documents:
   - `CURSOR_CONFIG_ROOT` source, defaulting to `./cursor`
   - repo-owned dotfiles and config: `zshrc`, `gitconfig`, `config/`
   - repo-owned scripts, tests, and docs
3. Derived runtime or generated outputs:
   - `~/.cursor/*`
   - Cursor User `settings.json` and `keybindings.json`
   - home/config symlinks under `~` and `~/.config`
   - optional project-local `.cursor/`

## 3) Output Chain Contract

### Output Chain Contract

Every root output has a traceable source chain, a declared boundary, and runnable validation:

| Root output | Deepest dependency chain | Boundary contract | Validation |
|---|---|---|---|
| Runtime projection under `~`, `~/.cursor/*`, and Cursor User JSON | tracked source paths → `tools/lib/link-targets.sh` and `tools/lib/cursor-layout.sh` → `link.sh` → runtime copies and user-setting symlinks | `REPOSITORY.md`, `AGENTS.md`, `tools/lib/link-targets.sh`, `tools/smoke-check.sh` | `tests/link.sh/*.test.sh`, `tests/tools/lib/*.test.sh`, `tests/tools/smoke-check.sh/*runtime*.test.sh`, runtime-mode smoke check |
| Command catalog generated block in `cursor/commands/commands.md` | `cursor/commands/*.md` and `cursor/_functions/**/*.md` → `tools/cursor/sync-commands-catalog.sh` → generated roster block | `cursor/_core/command.md`, `cursor/commands/commands.md` generated markers | `tests/tools/cursor/sync-commands-catalog.sh/*.test.sh`, `tests/cursor/commands/commands.md/*.test.sh`, `cursor/_tests/commands.md` |
| Repository README and golden file | verified repo files → `cursor/_functions/docs/readme.md` default template → `README.md` → `tests/README.md/README.md.golden` | `cursor/_core/document.md`, `cursor/_functions/docs/readme.md`, `tests/README.md/README.md__matches_docs_readme_contract.test.sh` | `tests/README.md/*.test.sh`, `tests/cursor/_functions/docs/readme.md/*.test.sh` |
| Manual link fallback guide | `tools/lib/link-targets.sh`, `tools/lib/cursor-layout.sh`, `link.sh`, `tools/manual/manual-link-fallback.sh`, and optional helper scripts → `MANUAL.md` → `tests/MANUAL.md/MANUAL.md.golden` | `cursor/_core/document.md`, `cursor/_functions/docs/manual.md`, this file | `tests/MANUAL.md/*.test.sh`, `tests/tools/manual/manual-link-fallback.sh/*.test.sh`, `tests/link.sh/*.test.sh` |
| QA notes append log | user-approved `/eval tune` learning run → `cursor/_functions/eval/tune.md` and `cursor/_mdc/shared/shared-cmd-eval.mdc` → `cursor/_functions/eval/notes.md` | `cursor/_functions/eval/tune.md`, `cursor/_mdc/shared/shared-cmd-eval.mdc`, this file | `tests/cursor/_functions/eval/notes.md/*.test.sh`, `tests/cursor/_functions/**/*.test.sh`, `tests/cursor/_mdc/**/*.test.sh` |
| Agent bootstrap adapters | `REPOSITORY.md` and `cursor/_CURSOR.md` → `AGENTS.md` → `CLAUDE.md` | `AGENTS.md`, `CLAUDE.md`, `cursor/_CURSOR.md` | `tools/check-agent-adapters.sh`, `tests/tools/check-agent-adapters.sh/*.test.sh` |

Files that cannot be traced to one of these outputs, or to a test/harness that validates them, are noise candidates and should be removed or given an explicit chain before they grow further.

## 4) Mutation Protocol and Ownership

- Must edit tracked source only.
- Do not edit runtime copies or symlink destinations.
- Contract path/layout changes must update executable checks in the same change.
- Adapter files must be routing-only; behavioral policy belongs in source and executable checks.
- New contract surfaces must have automated validation coverage.

## 5) Validation Modes

### Source Mode (required)

- `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`
- `./tests/run.sh`

### Runtime Mode (required if the repo projects runtime state)

1. `./link.sh`
2. `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`

### Overlay Mode (optional)

Project overlay validation runs only when `PROJECT_DOT_CURSOR` is set to an absolute path.
It enforces no authoring-core usage and no global-router collisions unless allowlisted.

## 6) Compatibility

Contract version: `0.1.0`.

- **Patch:** wording or validation tightening with no behavioral change.
- **Minor:** additive contract surface; backward compatible.
- **Major:** precedence, path, or ownership changes requiring migration.

## 7) Reporting Contract

Validation reports:

- source-mode validity
- runtime-mode projection validity
- overlay-mode composition validity when run
- adapter consistency
- residual risks or environment blockers
