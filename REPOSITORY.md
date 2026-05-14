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
   - `link.sh`
   - `tools/smoke-check.sh`
   - `tools/check-agent-adapters.sh`
   - `tools/check-cursor-content.sh`
   - `tools/check-cursor-flags.sh`
   - `tools/check-cursor-gates.sh`
   - `tools/check-cursor-naming.py`
   - `tools/check-cursor-roles.sh`
   - `tools/check-collab-floor-rules.py`
   - `tools/lib/link-targets.sh`
   - `tools/lib/cursor-layout.sh`
   - `tests/run.sh`
2. Repo-owned source files and policy documents:
   - dotfiles and config: `zshrc`, `gitconfig`, `config/`, `Brewfile`, `.gitignore`, `.cursorignore`, `.markdownlint.json`
   - Cursor source tree: `cursor/`
   - launcher source: `launcher/`
   - CI workflows: `.github/`
   - docs and adapters: `README.md`, `MANUAL.md`, `CHANGELOG.md`, `AGENTS.md`, `CLAUDE.md`, `REPOSITORY.md`
3. Derived runtime or generated outputs:
   - home symlinks: `~/.zshrc`, `~/.gitconfig`, `~/.config/starship*.toml`
   - `~/.cursor/` runtime mirror (copies, not symlinks)
   - Cursor User settings symlinks: `~/Library/Application Support/Cursor/User/{settings,keybindings}.json`
   - launcher app: `~/Applications/CursorWorkspaceLauncher.app`

## 3) Output Chain Contract

Every root output has a traceable source chain, a declared boundary, and runnable validation:

| Root output | Deepest dependency chain | Boundary contract | Validation |
|---|---|---|---|
| Shell, Git, and config symlinks under `~` | `zshrc`, `gitconfig`, `config/` → `tools/lib/link-targets.sh` → `link.sh` → `~/.zshrc`, `~/.gitconfig`, `~/.config/starship*.toml` | `REPOSITORY.md`, `AGENTS.md`, `tools/lib/link-targets.sh` | `tests/link.sh/*.test.sh`, `tests/tools/lib/*.test.sh`, `tools/smoke-check.sh` |
| `~/.cursor/` runtime mirror | `cursor/**` → `tools/lib/cursor-layout.sh` → `tools/lib/link-targets.sh` → `link.sh` → `~/.cursor/**` | `REPOSITORY.md`, `tools/lib/cursor-layout.sh`, `tools/check-cursor-*` | `tests/cursor/**/*.test.sh`, `tools/smoke-check.sh` |
| Cursor User settings symlinks | `cursor/_settings/{settings,keybindings}.json` → `tools/lib/cursor-layout.sh` → `link.sh` → Cursor `User/` | `REPOSITORY.md`, `tools/lib/cursor-layout.sh` | `tools/smoke-check.sh` |
| `CursorWorkspaceLauncher.app` | `launcher/setup-cursor-workspace-launcher.sh`, `launcher/workspace-launcher.local.sh` → `link.sh` → `~/Applications/CursorWorkspaceLauncher.app` | `REPOSITORY.md`, `launcher/` | `tests/launcher/*.test.sh` |

Files that cannot be traced to one of these outputs, or to a test/harness that validates them, are noise candidates and should be removed or given an explicit chain before they grow further.

## 4) Mutation Protocol and Ownership

- Must edit tracked source only.
- Do not edit runtime copies or symlink destinations under `~`; re-run `./link.sh` to refresh them.
- Do not hand-edit `cursor/_generated/`; regenerate via `tools/cursor/sync-*` scripts.
- Contract path/layout changes must update the executable checks under `tools/` in the same change.
- Adapter files (`CLAUDE.md`, `AGENTS.md`) stay routing-only; behavioral policy belongs in repo-owned source and executable checks.
- New contract surfaces must have automated validation coverage under `tests/` or `tools/`.

## 5) Validation Modes

### Source Mode (required)

- `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`
- `./tests/run.sh`

### Runtime Mode (required if the repo projects runtime state)

- `./link.sh` — refresh runtime symlinks and `~/.cursor/` mirrors from tracked source.
- `./tools/smoke-check.sh` — full smoke check (includes adapter-sync and Cursor markdown semantics checks against the live tree).

### Overlay Mode (optional)

- CI: `.github/workflows/smoke-check.yml` runs smoke checks and shell tests on Ubuntu and macOS.
- Local optional: `./link.sh --install-zsh-plugins` for zsh plugin bootstrap.
- macOS-only: Cursor cask auto-install and `CursorWorkspaceLauncher.app` build (requires `launcher/workspace-launcher.local.sh`).

## 6) Contract Versioning

Contract version: `0.1.0`.

- **Patch:** wording or validation tightening with no behavioral change.
- **Minor:** additive contract surface; backward compatible.
- **Major:** precedence, path, or ownership changes requiring migration.

## 7) Reporting Contract

When work completes, report:

- pass/fail summary from `./tests/run.sh` and `./tools/smoke-check.sh`
- any `~`-side files backed up by `link.sh` (`*.bak`) and any required source paths that were missing
- any uncommitted source changes
- any unresolved agent placeholder markers in adapter files (must be zero after `/agent patch`)
