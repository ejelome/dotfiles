# Recovery Guide

Recovery and fallback procedures for symlinks, config links, and launcher app rebuilds.
Use this guide when maintaining this dotfiles setup requires manual recovery steps.

---

**Table of Contents**

- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
  - [Relink](#relink)
  - [Config link](#config-link)
  - [Cursor rules link](#cursor-rules-link)
  - [Cursor skills link](#cursor-skills-link)
  - [Cursor commands link](#cursor-commands-link)
  - [Cursor extensions manifest](#cursor-extensions-manifest)
  - [Validation](#validation)
  - [Launcher build](#launcher-build)
  - [Rollback](#rollback)
- [Status](#status)

---

## Repository layout

Commands in this guide operate on tracked files in this repository and write symlinks into the home directory.
Launcher source files live in `launcher/`.
Cursor rules live in `cursor/rules/`, skills in `cursor/skills-cursor/`, and user slash commands in `cursor/commands/`.

## Prerequisites

- macOS with Xcode Command Line Tools (`swiftc`, `osascript`, `open`, `defaults`, `killall`, `mktemp`)
- Bash for running `link.sh`
- Git for cloning and updating tracked config files

## Install

Use this only when the happy-path `./link.sh` flow from `README.md` does not apply.

Set the repository path:

```bash
DOTFILES_ROOT="$HOME/dotfiles"
```

Create required directories:

```bash
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.cursor"
mkdir -p "$HOME/Applications"
```

Put Git user identity in `~/.gitconfig.local` so the symlinked `gitconfig` stays free of name and email. The tracked `gitconfig` enables Git LFS filters with `required = true`; install [Git LFS](https://git-lfs.com) on any machine using that file (`brew install git-lfs` then `git lfs install`), or remove the LFS stanza in a fork when LFS is unused.

```bash
cp "$DOTFILES_ROOT/gitconfig.local.example" "$HOME/.gitconfig.local"
# Edit ~/.gitconfig.local with your name and email.

cp "$DOTFILES_ROOT/zshrc.local.example" "$HOME/.zshrc.local"
# Edit ~/.zshrc.local: set GITHUB_TOKEN and any other machine-only exports.

chmod 600 "$HOME/.gitconfig.local" "$HOME/.zshrc.local"
```

## Usage

Use this guide for manual recovery when `./link.sh` is unavailable or when one specific fallback step is needed.
Run only the sections that apply, in order.
Initialize paths in **Install**, then run **Relink** and any targeted follow-up sections.

### Relink

Back up existing non-symlink destinations before linking:

```bash
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$HOME/.zshrc.bak"; fi
if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"; fi
if [ -e "$HOME/.cursor/rules" ] && [ ! -L "$HOME/.cursor/rules" ]; then mv "$HOME/.cursor/rules" "$HOME/.cursor/rules.bak"; fi
if [ -e "$HOME/.cursor/skills-cursor" ] && [ ! -L "$HOME/.cursor/skills-cursor" ]; then mv "$HOME/.cursor/skills-cursor" "$HOME/.cursor/skills-cursor.bak"; fi
if [ -e "$HOME/.cursor/commands" ] && [ ! -L "$HOME/.cursor/commands" ]; then mv "$HOME/.cursor/commands" "$HOME/.cursor/commands.bak"; fi
```

Link top-level files:

```bash
ln -sf "$DOTFILES_ROOT/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_ROOT/gitconfig" "$HOME/.gitconfig"
```

### Config link

Link all files in `config/` into `~/.config/` by basename:

```bash
for f in "$DOTFILES_ROOT/config"/*; do
  [ -e "$f" ] || continue
  ln -sf "$f" "$HOME/.config/$(basename "$f")"
done
```

### Cursor rules link

Recreate the Cursor rules symlink explicitly:

```bash
ln -sf "$DOTFILES_ROOT/cursor/rules" "$HOME/.cursor/rules"
```

Keep `cursor/rules/` flat: only `*.mdc` files belong here.
Do **not** create `cursor/rules/rules/` or symlink `rules` inside that folder toward `$HOME` or back at this directory.
Tools and editors can follow that loop and yield duplicate rule trees.

### Cursor skills link

Recreate the Cursor skills symlink explicitly (same layout as `link.sh`):

```bash
ln -sf "$DOTFILES_ROOT/cursor/skills-cursor" "$HOME/.cursor/skills-cursor"
```

Keep `cursor/skills-cursor/` flat: each skill is a direct child directory (for example `create-skill/SKILL.md`).
Do **not** create `cursor/skills-cursor/skills-cursor/` or symlink `skills-cursor` inside that folder.
That mirrors the recursive hazard from nested `cursor/rules/rules/`.

### Cursor commands link

Recreate the Cursor user-commands symlink explicitly (same layout as `link.sh`):

```bash
ln -sf "$DOTFILES_ROOT/cursor/commands" "$HOME/.cursor/commands"
```

Keep `cursor/commands/` flat: only `*.md` playbook files belong here.
Do **not** create `cursor/commands/commands` or symlink `commands` inside that folder toward `$HOME` or back at this directory.
That mirrors the recursive hazard from nested `cursor/rules/rules/`.

README and changelog behavior lives only in `readme.md` (`/readme`) and `changelog.md` (`/changelog`) under `cursor/commands/`, not under `cursor/rules/`.
Other slashes include `/commands`, `/issue`, `/commit`, `/assess`, and `/compare-compact`.
See [commands](cursor/commands/commands.md) (`/commands`) for the full list.

### Cursor extensions manifest

Extension binaries stay under Cursor install directories; this repository only tracks a **manifest** at `cursor/extensions.txt` (one `publisher.name` per line, or `publisher.name@version` when pinning with `--show-versions`).

**Export** (from a machine with the desired extension set):

```bash
# Unpinned (default in this repo): simpler, Cursor can auto-update
cursor --list-extensions > "$DOTFILES_ROOT/cursor/extensions.txt"

# Pinned: reproducible installs, more churn in Git when versions bump
cursor --list-extensions --show-versions > "$DOTFILES_ROOT/cursor/extensions.txt"
```

**Drift:** After installing or removing extensions in the Cursor UI, re-run the matching export above and commit so the manifest matches reality. Nothing in the repo auto-detects divergence.

**Install** on a new clone (or after editing the manifest):

```bash
"$DOTFILES_ROOT/scripts/ext.sh"
```

The script skips ids already returned by `cursor --list-extensions` (it compares `publisher.name`, ignoring `@version`) so repeated runs stay faster than blind reinstalls.

**Uninstall:** Deleting a line from `extensions.txt` does **not** remove that extension from an existing profile; uninstall from the UI or CLI to drop it. The manifest means “ensure these are present,” not “exact installed set.”

### Validation

After changes to shell scripts, launcher code, `gitconfig`, Starship TOML, or Cursor layout, run the smoke script from the repository root (same scope as [README](README.md) **Documentation**):

```bash
./scripts/qa.sh
```

It checks bash and zsh syntax, Python used by the launcher, `gitconfig` parse, optional Starship and Swift picker steps on macOS, `cursor/` layout guards, and optional `shellcheck` / `markdownlint` when those tools are installed. It does not validate bodies of `cursor/rules/*.mdc`.

### Launcher build

Build the user-level macOS launcher app:

```bash
zsh "$DOTFILES_ROOT/launcher/setup-cursor-workspace-launcher.sh"
```

On first use, copy `launcher/workspace-launcher.local.sh.example` to `launcher/workspace-launcher.local.sh` (gitignored) and set `WORKSPACE_ENTRIES`.

The setup script compiles the launcher app bundle, builds the picker binary, sets the icon (when icon tools are available), and adds the app to the Dock.

The picker lists every configured workspace with **checkboxes**.
Select one or more entries, then choose **Open** or **Append**, then **OK**.

**Open** starts a new window with the first folder or `.code-workspace`, then appends more selections with `cursor -a`.
**Append** adds each selection to the frontmost window.
**Cancel** or closing the window exits without launching.

If macOS blocks first launch, right-click the app and choose **Open** once.

### Rollback

Restore backup files when removing symlinks:

```bash
[ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
[ -L "$HOME/.gitconfig" ] && rm "$HOME/.gitconfig"
[ -L "$HOME/.cursor/rules" ] && rm "$HOME/.cursor/rules"
[ -L "$HOME/.cursor/skills-cursor" ] && rm "$HOME/.cursor/skills-cursor"
[ -L "$HOME/.cursor/commands" ] && rm "$HOME/.cursor/commands"

[ -e "$HOME/.zshrc.bak" ] && mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
[ -e "$HOME/.gitconfig.bak" ] && mv "$HOME/.gitconfig.bak" "$HOME/.gitconfig"
[ -e "$HOME/.cursor/rules.bak" ] && mv "$HOME/.cursor/rules.bak" "$HOME/.cursor/rules"
[ -e "$HOME/.cursor/skills-cursor.bak" ] && mv "$HOME/.cursor/skills-cursor.bak" "$HOME/.cursor/skills-cursor"
[ -e "$HOME/.cursor/commands.bak" ] && mv "$HOME/.cursor/commands.bak" "$HOME/.cursor/commands"
```

## Status

> Last updated: 2026-04-03

Recovery procedures and fallback commands match current repository layout.
They cover Cursor rules, skills under `cursor/skills-cursor/`, slash commands under `cursor/commands/`, and the Cursor extensions manifest at `cursor/extensions.txt`.

See [CHANGELOG](CHANGELOG.md) for full history.
