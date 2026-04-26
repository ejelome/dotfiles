# Repository Contract

Contract between this repository (source plane) and the Cursor runtime at `~/.cursor/*`.

## 1) System Model

The contract has three planes:

- **Source plane**: version-controlled files in this repository.
- **Global runtime plane**: `~/.cursor/*` and Cursor User JSON linked from source.
- **Project overlay plane**: optional project-local `.cursor/` validated with `PROJECT_DOT_CURSOR`.

Only the source plane is authoritative. Runtime planes are derived execution contexts.

## 2) Authority Chain

Authority is strict and ordered:

1. Executable contract:
   - `tools/lib/link-targets.sh`
   - `tools/lib/cursor-layout.sh`
   - `tools/smoke-check.sh`
   - `tools/check-agent-adapters.sh`
   - `tools/check-cursor-content.sh`
2. Tracked source under `CURSOR_CONFIG_ROOT` (default `./cursor`) and repo-owned dotfiles.
3. Derived runtime mirrors:
   - `~/.cursor/*`
   - Cursor User `settings.json` and `keybindings.json`
   - optional project-local `.cursor/`

Conflict rule: higher authority wins. Lower authority must be updated or rejected by checks.

## 3) Runtime Composition Contract

Global runtime and project overlay compose with deterministic rules:

- Project overlays may add project-specific `rules/` and `commands/`.
- Project overlays must not author `_core/` and must not reference authoring-core paths.
- Project overlays must not override global router names in `commands/*.md` or `rules/*.mdc`.
- Override exceptions must be explicitly allowlisted in `tools/smoke-check.sh`.

This enforces consistent command/rule resolution across Cursor Composer, Codex, GPT, and Claude Code.

### Output Chain Contract

Every root output has a traceable source chain, a declared boundary, and runnable validation:

| Root output | Deepest dependency chain | Boundary contract | Validation |
|---|---|---|---|
| Runtime projection under `~`, `~/.cursor/*`, and Cursor User JSON | tracked source paths → `tools/lib/link-targets.sh` and `tools/lib/cursor-layout.sh` → `link.sh` → runtime symlinks | `REPOSITORY.md`, `AGENTS.md`, `tools/lib/link-targets.sh`, `tools/smoke-check.sh` | `tests/link.sh/*.test.sh`, `tests/tools/lib/*.test.sh`, `tests/tools/smoke-check.sh/*runtime*.test.sh`, runtime-mode smoke check |
| Command catalog generated block in `cursor/commands/commands.md` | `cursor/commands/*.md` and `cursor/_functions/**/*.md` → `tools/cursor/sync-commands-catalog.sh` → generated roster block | `cursor/_core/command.md`, `cursor/commands/commands.md` generated markers | `tests/tools/cursor/sync-commands-catalog.sh/*.test.sh`, `tests/cursor/commands/commands.md/*.test.sh`, `cursor/_tests/commands.md` |
| Repository README and golden file | verified repo files → `cursor/_functions/docs/readme.md` default template → `README.md` → `tests/README.md/README.md.golden` | `cursor/_core/document.md`, `cursor/_functions/docs/readme.md`, `tests/README.md/README.md__matches_docs_readme_contract.test.sh` | `tests/README.md/*.test.sh`, `tests/cursor/_functions/docs/readme.md/*.test.sh` |
| Manual link fallback guide | `tools/lib/link-targets.sh`, `tools/lib/cursor-layout.sh`, `link.sh`, `tools/manual/manual-link-fallback.sh`, and optional helper scripts → `MANUAL.md` → `tests/MANUAL.md/MANUAL.md.golden` | `cursor/_core/document.md`, `cursor/_functions/docs/manual.md`, this file | `tests/MANUAL.md/*.test.sh`, `tests/tools/manual/manual-link-fallback.sh/*.test.sh`, `tests/link.sh/*.test.sh` |
| QA notes append log | user-approved `/eval tune` learning run → `cursor/_functions/eval/tune.md` and `cursor/_mdc/shared/shared-cmd-eval.mdc` → `cursor/_functions/eval/notes.md` | `cursor/_functions/eval/tune.md`, `cursor/_mdc/shared/shared-cmd-eval.mdc`, this file | `tests/cursor/_functions/eval/notes.md/*.test.sh`, `tests/cursor/_functions/**/*.test.sh`, `tests/cursor/_mdc/**/*.test.sh` |
| Agent bootstrap adapters | `REPOSITORY.md` and `cursor/_CURSOR.md` → `AGENTS.md` → `CLAUDE.md` | `AGENTS.md`, `CLAUDE.md`, `cursor/_CURSOR.md` | `tools/check-agent-adapters.sh`, `tests/tools/check-agent-adapters.sh/*.test.sh` |

Files that cannot be traced to one of these outputs, or to a test/harness that validates them, are noise candidates and should be removed or given an explicit chain before they grow further.

## 4) Mutation Protocol and Ownership

- Must edit tracked source only. Do not edit runtime symlink destinations.
- Contract path/layout changes must update executable checks in the same change.
- Adapter files must be routing-only; behavioral policy belongs in source and executable checks.
- New contract surfaces must have automated validation coverage.

Ownership is enforced by executable checks.

## 5) Validation Modes

### Source Mode (required)

Validates repository truth independent of runtime freshness. Must run before any change is merged:

- `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`
- `./tests/run.sh`

### Runtime Mode (required)

Projection check after linking. Must run after any change that affects the projected runtime:

1. `./link.sh`
2. `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`

### Overlay Mode (optional)

Project overlay validation runs only when `PROJECT_DOT_CURSOR` is set to an absolute path.
It enforces no authoring-core usage and no global-router collisions unless allowlisted.

## 6) Compatibility

Contract version: `1.0.0`.

- **Patch**: wording/check tightening with no behavioral change.
- **Minor**: additive contract surface; backward compatible.
- **Major**: precedence/path/namespace changes requiring migration.

## 7) Reporting Contract

Validation produces a pass/fail result for:

- source-mode validity
- runtime-mode projection validity
- overlay-mode composition validity (when run)
- adapter consistency
- residual risks or environment blockers
