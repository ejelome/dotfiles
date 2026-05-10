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
   - `tools/check-cursor-roles.sh`
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

Every root output has a traceable source chain, a declared boundary, and runnable validation:

| Root output | Deepest dependency chain | Boundary contract | Validation |
|---|---|---|---|
| Runtime projection under `~`, `~/.cursor/*`, and Cursor User JSON | tracked source paths -> `tools/lib/link-targets.sh` and `tools/lib/cursor-layout.sh` -> `link.sh` -> runtime copies and user-setting symlinks | `REPOSITORY.md`, `AGENTS.md`, `tools/lib/link-targets.sh`, `tools/smoke-check.sh` | `tests/link.sh/*.test.sh`, `tests/tools/lib/*.test.sh`, `tests/tools/smoke-check.sh/*runtime*.test.sh`, runtime-mode smoke check |
| Command catalog generated block in `cursor/commands/commands.md` | `cursor/commands/*.md` and `cursor/_functions/**/*.md` -> `tools/cursor/sync-commands-catalog.sh` -> generated roster block | `cursor/_core/command-standard.md`, `cursor/commands/commands.md` generated markers | `tests/tools/cursor/sync-commands-catalog.sh/*.test.sh`, `tests/cursor/commands/commands.md/*.test.sh`, `cursor/_tests/commands.md` |
| Command reference generated block in `cursor/_generated/command-reference.md` | `cursor/_functions/**/*.md` `cursor-arg` blocks and role catalog helper output -> `tools/cursor/command-reference.py` -> generated command-reference block | `cursor/_core/command-standard.md`, `cursor/_generated/command-reference.md` generated markers | `tools/cursor/command-reference.py --check`, `tests/tools/cursor/command-reference.py/*.test.sh` |
| Framework boundaries generated block in `cursor/_core/framework-boundaries.md` | `AGENTS.md`, `CLAUDE.md`, `cursor/_CURSOR.md`, `cursor/_core/`, `cursor/_roles/`, `cursor/commands/`, `cursor/_functions/`, `tools/`, `.collabs/registry.json` -> `tools/cursor/sync-framework-boundaries.sh` -> generated boundary table | `cursor/_core/framework-boundaries.md` generated markers | `tools/cursor/sync-framework-boundaries.sh --check`, `tests/tools/cursor/sync-framework-boundaries.sh/*.test.sh` |
| Repository README and targeted artifact checks | verified repo files -> `cursor/_functions/doc/write-readme.md` default template -> `README.md` -> required-section, TOC, link, and validation-command checks | `cursor/_core/document-standard.md`, `cursor/_functions/doc/write-readme.md`, `tests/README.md/README.md__matches_docs_readme_contract.test.sh` | `tests/README.md/*.test.sh`, `tests/cursor/_functions/doc/write-readme.md/*.test.sh` |
| Manual link fallback guide | `tools/lib/link-targets.sh`, `tools/lib/cursor-layout.sh`, `link.sh`, optional helper scripts -> `MANUAL.md` -> generated link-target, TOC, link, and traced-status checks | `cursor/_core/document-standard.md`, `cursor/_functions/doc/write-manual.md`, this file | `tests/MANUAL.md/*.test.sh`, `tests/tools/manual/manual-link-fallback.sh/*.test.sh`, `tests/link.sh/*.test.sh` |
| QA notes append log | user-approved `/quality tune` learning run -> `cursor/_functions/quality/tune.md` and `cursor/_mdc/shared/shared-cmd-quality.mdc` -> `cursor/_functions/quality/show-notes.md` | `cursor/_functions/quality/tune.md`, `cursor/_mdc/shared/shared-cmd-quality.mdc`, this file | `tests/cursor/_functions/quality/show-notes.md/*.test.sh`, `tests/cursor/_functions/**/*.test.sh`, `tests/cursor/_mdc/**/*.test.sh` |
| Agent bootstrap adapters | `REPOSITORY.md` and `cursor/_CURSOR.md` -> `AGENTS.md` -> `CLAUDE.md` | `AGENTS.md`, `CLAUDE.md`, `cursor/_CURSOR.md` | `tools/check-agent-adapters.sh`, `tests/tools/check-agent-adapters.sh/*.test.sh` |
| Role catalog and `dcc` shortcut launcher | `cursor/_roles/*.json` role metadata plus `tools/cursor-cli/dcc` shortcut table -> `exec -a "$role"` named process | `cursor/_roles/*.json`, `tools/cursor-cli/dcc`, `tools/check-cursor-roles.sh` | `tools/check-cursor-roles.sh`, `tests/tools/check-cursor-roles.sh/*.test.sh`, `tests/tools/cursor-cli/dcc/dcc__shows_help_and_rejects_unknown.test.sh`, `tests/tools/cursor-cli/dcc/dcc__routes_role_shortcuts.test.sh` |

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

## 6) Contract Versioning

Contract version: `0.1.0`.

- **Patch:** wording or validation tightening with no behavioral change.
- **Minor:** additive contract surface; backward compatible.
- **Major:** precedence, path, or ownership changes requiring migration.

## 7) Reporting Contract

Report each placeholder resolved and confirm no `<!-- TODO(agent): ... -->` markers remain.
