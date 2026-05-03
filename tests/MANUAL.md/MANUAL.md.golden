# Manual link fallback

Use these steps to reproduce `link.sh`'s repo-to-runtime projection when `link.sh` cannot run.

---

**Table of contents**

- [Prerequisites](#prerequisites)
- [Reproduce the automated link pass by hand](#reproduce-the-automated-link-pass-by-hand)
  - [1. Clean nested mirrors under the Cursor config root, then assert](#1-clean-nested-mirrors-under-the-cursor-config-root-then-assert)
  - [2. Link required top-level home files](#2-link-required-top-level-home-files)
  - [3. Remove legacy `~/.cursor/core` if present as a symlink](#3-remove-legacy-cursorcore-if-present-as-a-symlink)
  - [4. Mirror `config/` into `~/.config/`](#4-mirror-config-into-config)
  - [5. Copy the Cursor runtime tree](#5-copy-the-cursor-runtime-tree)
  - [6. Link Cursor user settings (platform-specific User folder)](#6-link-cursor-user-settings-platform-specific-user-folder)
  - [7. Optional: install Cursor and expose the `cursor` CLI (macOS-oriented)](#7-optional-install-cursor-and-expose-the-cursor-cli-macos-oriented)
  - [8. Optional: build the workspace launcher app (macOS)](#8-optional-build-the-workspace-launcher-app-macos)
  - [9. Optional: zsh plugin directories](#9-optional-zsh-plugin-directories)
  - [10. Final mirror strip and assert](#10-final-mirror-strip-and-assert)
- [Verification](#verification)
- [Status](#status)

---

## Prerequisites

- A repository checkout with `cursor/` as the default `CURSOR_CONFIG_ROOT` (override with `CURSOR_CONFIG_ROOT=/absolute/path` to use another source tree).
- `bash` to run scripts; `zsh` for the linked `zshrc`.
- `git` for the optional zsh plugin install; `ZSH_PLUGINS_DIR` defaults to `~/.zsh/plugins`.
- **macOS:** Homebrew in `PATH` for the optional Cursor cask installation and workspace launcher build.
- **Linux and others:** the installer skips the Cursor cask; install the editor manually and place `cursor` on `PATH` if CLI integration is needed.
- Run `brew bundle` from the repo root, then run `cp gitconfig.local.example ~/.gitconfig.local && cp zshrc.local.example ~/.zshrc.local && chmod 600 ~/.gitconfig.local ~/.zshrc.local`; the linker does not manage those files.
- Read [REPOSITORY.md](REPOSITORY.md) before proceeding; it defines the ownership and mutation rules for every path these steps touch.

## Reproduce the automated link pass by hand

These steps reproduce the installer sequence: clear forbidden Cursor mirror paths; link home files; mirror optional application config; copy Cursor runtime files; link editor settings; run optional post steps; repeat the final mirror cleanup and assertion.

### 1. Clean nested mirrors under the Cursor config root, then assert

**All platforms:** `CURSOR_CONFIG_ROOT` defaults to `<repo>/cursor` relative to the checkout root.

1. For each path below under `CURSOR_CONFIG_ROOT`, remove only the symlink when the path targets its own parent directory (a `foo/foo`-style self-mirror):

   - `commands/commands`
   - `rules/rules`
   - `_functions/_functions`
   - `_core/_core`
   - `_mdc/_mdc`
   - `_roles/_roles`
   - `_tests/_tests`
   - `_templates/_templates`

2. Confirm that none of these paths exists under `CURSOR_CONFIG_ROOT` as a file, directory, or symlink:

   - the six paths above, and
   - `core` and `user` (non–underscore-prefixed names are rejected there).

3. Remove or relocate any path listed above that still exists; the automated installer aborts at this point.

### 2. Link required top-level home files

For each entry below, move `~/<dest>` to `~/<dest>.bak` when it exists and is not a symlink; create the parent directory with `mkdir -p`; link with `ln -sf <abs-src> ~/<dest>`. Use the same procedure in steps 4 and 6.

| Source (from repo root) | Destination under `$HOME` |
| --- | --- |
| `zshrc` | `.zshrc` |
| `gitconfig` | `.gitconfig` |

### 3. Remove legacy `~/.cursor/core` if present as a symlink

Remove `~/.cursor/core` if it is a symlink; skip if absent or not a symlink.

### 4. Mirror `config/` into `~/.config/`

For each entry in `<repo>/config/`, link it to `~/.config/<entry-name>` when it exists. Use the same procedure as step 2.

### 5. Copy the Cursor runtime tree

Under `CURSOR_CONFIG_ROOT` (e.g. `<repo>/cursor`):

| Source (relative) | Under `$HOME` | Kind |
| --- | --- | --- |
| `rules` | `.cursor/rules` | directory |
| `commands` | `.cursor/commands` | directory |
| `_functions` | `.cursor/_functions` | directory |
| `_mdc` | `.cursor/_mdc` | directory |
| `_core` | `.cursor/_core` | directory |
| `_roles` | `.cursor/_roles` | directory |
| `_tests` | `.cursor/_tests` | directory |
| `_templates` | `.cursor/_templates` | directory |
| `_CURSOR.md` | `.cursor/_CURSOR.md` | file |

Copy each source only when it exists and matches the listed kind. Remove the destination path before copying so deleted source files do not remain in `~/.cursor/`. Skip absent sources without exiting.

`_CURSOR.md` is the Cursor runtime guide for editor and agent behavior in the linked tree. [AGENTS.md](AGENTS.md) at the repository root orients agents and editors working in the repo; do not link it into `~/.cursor/`.

### 6. Link Cursor user settings (platform-specific User folder)

**macOS:** `~/Library/Application Support/Cursor/User/`.

**Linux / others (when `XDG_CONFIG_HOME` is set):** `$XDG_CONFIG_HOME/Cursor/User/`.

**Linux / others (when `XDG_CONFIG_HOME` is unset):** `~/.config/Cursor/User/`.

Link these files from `CURSOR_CONFIG_ROOT` when they exist:

- `_settings/settings.json` → `settings.json` in that `User` directory
- `_settings/keybindings.json` → `keybindings.json` in that `User` directory

Use the backup-and-link procedure from step 2.

### 7. Optional: install Cursor and expose the `cursor` CLI (macOS-oriented)

1. Skip this step when `cursor` is already in `PATH`.
2. **macOS:** if `cursor` is missing, prepend `PATH` with `/Applications/Cursor.app/Contents/Resources/app/bin` or `~/Applications/Cursor.app/Contents/Resources/app/bin` when either directory exists, so that `cursor` resolves.
3. **macOS:** if `cursor` is still missing and Homebrew is available, run `brew install --cask cursor` when the cask is not already installed. If the cask is installed but `cursor` is still not on `PATH`, use Cursor's "Install `cursor` command in PATH" action.
4. **Linux and others:** skip the cask path; install the editor manually and place `cursor` on `PATH` if CLI integration is needed.

### 8. Optional: build the workspace launcher app (macOS)

This step applies only on **macOS**. Create `launcher/workspace-launcher.local.sh` from `launcher/workspace-launcher.local.sh.example` if it does not exist. Skip the build when `~/Applications/CursorWorkspaceLauncher.app` already exists and no rebuild is needed. From the repository root:

```bash
cd /path/to/your/clone
zsh ./launcher/setup-cursor-workspace-launcher.sh
```

Invoke the setup script directly without `zsh` when it is executable.

### 9. Optional: zsh plugin directories

The helper creates `ZSH_PLUGINS_DIR` (default `~/.zsh/plugins`) if absent, then clones or updates `zsh-autosuggestions` and `zsh-syntax-highlighting` there. Run:

```bash
cd /path/to/your/clone
bash ./tools/zsh/install-plugins.sh
```

### 10. Final mirror strip and assert

Repeat the nested-mirror removal and forbidden-path check from step 1. If the assertion fails, remove or relocate the blocking paths before continuing.

When a shell is available, `./link.sh` at the repository root runs the same sequence in one step; use `--install-zsh-plugins`, `--skip-cursor-install`, `--skip-cursor-launcher`, `--force-cursor-launcher`, and `--cursor-config-root <path>` (or the matching environment variables) to control optional branches.

## Verification

Restart the shell or run `source ~/.zshrc` before running these checks; the linked `zshrc` must be active.

Run the same checks used in continuous integration and [README](README.md):

```bash
cd /path/to/your/clone
SKIP_TESTS_RUN=1 ./tools/smoke-check.sh
./tests/run.sh
```

## Status

> Last updated: 2026-04-26

All steps are traced to the current linker scripts. The optional macOS launcher and zsh plugin branches are the most likely to drift as those paths evolve independently.
