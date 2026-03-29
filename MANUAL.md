# Recovery Guide

Recovery and fallback procedures for symlinks, config links, and launcher app rebuilds.
Use this guide when you maintain this dotfiles setup and need manual recovery steps.

---

**Table of Contents**

- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
  - [Relink](#relink)
  - [Config link](#config-link)
  - [Cursor rules link](#cursor-rules-link)
  - [Launcher build](#launcher-build)
  - [Rollback](#rollback)
- [Status](#status)

---

## Repository layout

Commands in this guide operate on tracked files in this repository and write symlinks into your home directory.
Launcher source files are stored in `launcher/`, and Cursor rules are stored in `cursor/rules/`.

## Prerequisites

- macOS with Xcode Command Line Tools (`swiftc`, `osascript`, `open`, `defaults`, `killall`, `mktemp`)
- Bash for running `link.sh`
- Git for cloning and updating tracked config files

## Install

Use this only when you are not using the happy-path `./link.sh` flow from `README.md`.

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

## Usage

Use this guide for manual recovery when `./link.sh` is unavailable or when you need one specific fallback step.
Run only the sections you need, in order: initialize paths in **Install**, then run **Relink** and any targeted follow-up sections.

### Relink

Back up existing non-symlink destinations before linking:

```bash
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$HOME/.zshrc.bak"; fi
if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"; fi
if [ -e "$HOME/.cursor/rules" ] && [ ! -L "$HOME/.cursor/rules" ]; then mv "$HOME/.cursor/rules" "$HOME/.cursor/rules.bak"; fi
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

### Launcher build

Build the user-level macOS launcher app:

```bash
zsh "$DOTFILES_ROOT/launcher/setup-cursor-workspace-launcher.sh"
```

On first use, copy `launcher/workspace-launcher.local.sh.example` to `launcher/workspace-launcher.local.sh` (gitignored) and set `WORKSPACE_ENTRIES`.

The setup script compiles the launcher app bundle, builds the picker binary, sets the icon (when icon tools are available), and adds the app to the Dock.

If macOS blocks first launch, right-click the app and choose **Open** once.

### Rollback

Restore backup files if you need to remove symlinks:

```bash
[ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
[ -L "$HOME/.gitconfig" ] && rm "$HOME/.gitconfig"
[ -L "$HOME/.cursor/rules" ] && rm "$HOME/.cursor/rules"

[ -e "$HOME/.zshrc.bak" ] && mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
[ -e "$HOME/.gitconfig.bak" ] && mv "$HOME/.gitconfig.bak" "$HOME/.gitconfig"
[ -e "$HOME/.cursor/rules.bak" ] && mv "$HOME/.cursor/rules.bak" "$HOME/.cursor/rules"
```

## Status

> Last updated: 2026-03-24

Recovery procedures and fallback commands match current repository layout.
Current documentation work focuses on separating fallback guidance from the happy path.

See [CHANGELOG.md](CHANGELOG.md) for full history.
