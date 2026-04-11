# Recovery Guide

Recovery and fallback procedures for symlinks, config links, and launcher app rebuilds. Use when maintaining this dotfiles setup needs manual recovery.

---

**Table of contents**

- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
- [Relink](#relink)
- [Config link](#config-link)
- [Cursor rules link](#cursor-rules-link)
- [Cursor commands link](#cursor-commands-link)
- [Cursor core link](#cursor-core-link)
- [Cursor CLI helpers (PATH)](#cursor-cli-helpers-path)
- [Cursor extensions manifest](#cursor-extensions-manifest)
- [Clear Cursor chat history](#clear-cursor-chat-history)
- [Validation](#validation)
- [Launcher build](#launcher-build)
- [Rollback](#rollback)
- [Status](#status)

---

## Repository layout

Commands here operate on tracked files and write symlinks into `$HOME`. Launcher sources live in `launcher/`.

**Cursor:** Cursor always reads **`~/.cursor/`** (rules, commands, `skills-cursor/`, optional `core/`, `extensions.txt`). Root install automation symlinks each target from **`CURSOR_CONFIG_ROOT`** only when that source exists (default **`cursor/`** supplies all of these). **`CURSOR_CONFIG_ROOT`** defaults to **`<dotfiles-clone>/cursor`**; use any absolute path to decouple Cursor config from the dotfiles clone path. A minimal external tree may omit **`core/`**; slash playbooks still resolve **`../core/…`** via the real path under **`commands/`**.

If install automation errors on nested **`rules/rules`**, **`skills-cursor/skills-cursor`**, **`commands/commands`**, or **`core/core`** under **`CURSOR_CONFIG_ROOT`**, remove that nested path so each tree stays one flat directory (no recursive mirror).

## Prerequisites

- Bash (root install automation)
- Git (clone/update tracked config)

**Launcher build only:** macOS; setup checks `swiftc`, `osascript`, `defaults`, `killall`, `mktemp`, and `python3`. The app may call **`open`** when launching workspaces; that is not part of the setup checklist.

## Install

Use when the happy-path install in [README](README.md) does not apply.

```bash
DOTFILES_ROOT="$HOME/dotfiles"
```

```bash
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.cursor"
mkdir -p "$HOME/Applications"
```

Put Git identity in `~/.gitconfig.local` so the symlinked `gitconfig` stays free of name/email. Tracked `gitconfig` enables Git LFS with `required = true`; install [Git LFS](https://git-lfs.com) (`brew install git-lfs` then `git lfs install`) or drop the LFS stanza in a fork if unused.

```bash
cp "$DOTFILES_ROOT/gitconfig.local.example" "$HOME/.gitconfig.local"
# Edit ~/.gitconfig.local with your name and email.

cp "$DOTFILES_ROOT/zshrc.local.example" "$HOME/.zshrc.local"
# Edit ~/.zshrc.local: set GITHUB_TOKEN and any other machine-only exports.

chmod 600 "$HOME/.gitconfig.local" "$HOME/.zshrc.local"
```

## Usage

Manual recovery when root automation is unavailable or a single fallback step is needed. Run only applicable sections in order: set paths in **Install**, then **Relink** and follow-ups.

### Relink

Back up non-symlink destinations before linking:

```bash
if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$HOME/.zshrc.bak"; fi
if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"; fi
if [ -e "$HOME/.cursor/rules" ] && [ ! -L "$HOME/.cursor/rules" ]; then mv "$HOME/.cursor/rules" "$HOME/.cursor/rules.bak"; fi
if [ -e "$HOME/.cursor/commands" ] && [ ! -L "$HOME/.cursor/commands" ]; then mv "$HOME/.cursor/commands" "$HOME/.cursor/commands.bak"; fi
if [ -e "$HOME/.cursor/extensions.txt" ] && [ ! -L "$HOME/.cursor/extensions.txt" ]; then mv "$HOME/.cursor/extensions.txt" "$HOME/.cursor/extensions.txt.bak"; fi
if [ -e "$HOME/.cursor/core" ] && [ ! -L "$HOME/.cursor/core" ]; then mv "$HOME/.cursor/core" "$HOME/.cursor/core.bak"; fi
```

```bash
ln -sf "$DOTFILES_ROOT/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_ROOT/gitconfig" "$HOME/.gitconfig"
```

### Config link

Link each `config/` file into `~/.config/` by basename. Before replacing with a symlink, back up any existing file or directory at the destination (same idea as root automation):

```bash
for f in "$DOTFILES_ROOT/config"/*; do
  [ -e "$f" ] || continue
  dest="$HOME/.config/$(basename "$f")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then mv "$dest" "${dest}.bak"; fi
  mkdir -p "$(dirname "$dest")"
  ln -sf "$f" "$dest"
done
```

### Cursor rules link

If the rules source directory is missing, skip (install automation does not create this link).

```bash
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
[ -d "$CURSOR_CONFIG_ROOT/rules" ] && ln -sf "$CURSOR_CONFIG_ROOT/rules" "$HOME/.cursor/rules"
```

Keep **`$CURSOR_CONFIG_ROOT/rules/`** flat (`*.mdc` only). Do **not** create `rules/rules/` or symlink `rules` inside that tree toward `$HOME` or the repo—tools can follow loops and duplicate trees.

### Cursor commands link

If the commands source directory is missing, skip (install automation does not create this link).

```bash
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
[ -d "$CURSOR_CONFIG_ROOT/commands" ] && ln -sf "$CURSOR_CONFIG_ROOT/commands" "$HOME/.cursor/commands"
```

Keep **`$CURSOR_CONFIG_ROOT/commands/`** flat (`*.md` playbooks only). No nested `commands/commands/` directory (same symlink-loop hazard as `rules/rules/`).

README and changelog playbooks ship as `docs-readme.md` and `docs-changelog.md` under **`~/.cursor/commands/`** (from **`$CURSOR_CONFIG_ROOT/commands/`**), not under `rules/`. Other slashes include `/commands`, `/docs-manual`, `/git-issue create`, `/git-issue implement`, `/git-commit`, `/docs-assess`, `/docs-compare`, `/docs-compact`, `/eval-tune`, `/eval-uid`, `/eval-wse`, `/eval-igd`, `/eval-ops`. Full list: [commands](cursor/commands/commands.md) (`/commands`).

### Cursor core link

If the **`core/`** source directory is missing, skip (install automation does not create this link).

```bash
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
[ -d "$CURSOR_CONFIG_ROOT/core" ] && ln -sf "$CURSOR_CONFIG_ROOT/core" "$HOME/.cursor/core"
```

**`core/`** holds authoring canon ([style-guide](cursor/core/style-guide.md), [document-standard](cursor/core/document-standard.md), and related files). Linking it to **`~/.cursor/core`** is optional for path resolution but matches **`link.sh`** when the directory exists.

### Cursor CLI helpers (PATH)

When **`~/.zshrc`** resolves into this repo, tracked shell startup sets **`DOTFILES_ROOT`** to that file’s directory and prepends **`$DOTFILES_ROOT/tools/cursor-cli`** to **`PATH`** (after **`source ~/.zshrc`** or a new login shell).

Root install automation does not add **`tools/cursor-cli`**; only that shell startup does, after prepending **`$HOME/.local/bin`**.

### Cursor extensions manifest

Extension binaries live under Cursor installs; the **source** manifest is **`$CURSOR_CONFIG_ROOT/extensions.txt`** (default: [`cursor/extensions.txt`](cursor/extensions.txt)). After linking **`~/.cursor/extensions.txt`**, it mirrors that file (symlink). IDs are **unpinned** (`publisher.name` per line) unless you export with versions (see **Export**).

After changing Cursor layout or manifests, run the checks in **Validation** from the repository root. Helpers under **`tools/cursor-cli/`** call the **`cursor`** CLI or modify **`~/.cursor`** (not the `CURSOR_CONFIG_ROOT` tree). Root automation does not symlink **`tools/`** wholesale; tracked shell startup prepends **`tools/cursor-cli`** to **`PATH`** when **`~/.zshrc`** resolves into this checkout.

**Export:**

```bash
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
# Unpinned (default): simpler, Cursor can auto-update
cursor --list-extensions > "$CURSOR_CONFIG_ROOT/extensions.txt"

# Pinned: reproducible installs, more churn in Git when versions bump
cursor --list-extensions --show-versions > "$CURSOR_CONFIG_ROOT/extensions.txt"
```

**Drift:** After UI extension changes, re-run the matching export and commit. Nothing auto-detects drift.

**Install:** After **`~/.cursor/extensions.txt`** exists (symlink or file), root automation runs the extension-list sync helper with **`bash`** when **`cursor`** is on `PATH`, that helper exists under **`DOTFILES_ROOT/tools/cursor-cli/`**, and **`SKIP_CURSOR_EXTENSIONS`** is not **`1`**. Set **`SKIP_CURSOR_EXTENSIONS=1`** to skip. Manual re-run (reads **`~/.cursor/extensions.txt`** unless **`CURSOR_EXTENSIONS_MANIFEST`** overrides):

```bash
"$DOTFILES_ROOT/tools/cursor-cli/install-extensions.sh"
# or, after shell startup loads PATH: install-extensions.sh
```

Skips ids already returned by `cursor --list-extensions` (`publisher.name`, ignoring `@version`).

**Uninstall:** Removing a manifest line does **not** remove the extension from a profile; uninstall via UI/CLI. Manifest = “ensure present,” not “exact set.”

**Symlink manifest only:**

If the manifest file is missing under **`CURSOR_CONFIG_ROOT`**, skip (install automation does not create this link).

```bash
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$DOTFILES_ROOT/cursor}"
[ -f "$CURSOR_CONFIG_ROOT/extensions.txt" ] && ln -sf "$CURSOR_CONFIG_ROOT/extensions.txt" "$HOME/.cursor/extensions.txt"
```

### Clear Cursor chat history

**Not** run by root automation (destructive). macOS; see the script header for paths.

Quit Cursor (**Cmd+Q**), then:

```bash
"$DOTFILES_ROOT/tools/cursor-cli/clear-chat.sh"
# or, after shell startup loads PATH: clear-chat.sh
```

Wipes chat, composer, and local agent transcripts; keeps `settings.json`, keybindings, snippets. Needs **`sqlite3`** (macOS ships it).

### Validation

After shell/launcher/`gitconfig`/Starship/Cursor layout changes, from repository root (same checks as [README](README.md) **Usage → Validate the repo layout**):

```bash
./tools/smoke-check.sh
```

If this repository is the open Cursor workspace and **`~/.cursor/*`** symlinks into **`./cursor/`**, the editor can recreate forbidden nested paths such as **`commands/commands`**; **`link.sh`** and **`tools/smoke-check.sh`** strip known self-symlink patterns automatically. Close Cursor or point **`CURSOR_CONFIG_ROOT`** outside the clone if problems persist.

Checks bash/zsh syntax on tracked entrypoints, launcher **`zsh -n`** targets, Python compile for Dock helper, `gitconfig` parse, optional Starship TOML when **`starship`** is on **`PATH`**, optional Swift template parse on macOS when **`swiftc`** exists, executable bits on root and launcher setup paths, and **`CURSOR_CONFIG_ROOT`** layout: directories **`commands/`** and **`rules/`**; file **`extensions.txt`**; at least one **`commands/*.md`**; nested-mirror guards (**`rules/rules`**, **`commands/commands`**, **`core/core`**); **`commands.md`** links each **`commands/*.md`**. Optional **`shellcheck`** / **`markdownlint`** when installed. Does not validate `*.mdc` bodies under rules. `skills-cursor/` is managed by Cursor itself and is not checked.

### Launcher build

User-level macOS launcher (same dispatch as root install on Darwin: executable first, else **`zsh`**):

```bash
LAUNCHER_SETUP="$DOTFILES_ROOT/launcher/setup-cursor-workspace-launcher.sh"
if [[ -x "$LAUNCHER_SETUP" ]]; then
  "$LAUNCHER_SETUP"
else
  zsh "$LAUNCHER_SETUP"
fi
```

First use: copy `launcher/workspace-launcher.local.sh.example` → `launcher/workspace-launcher.local.sh` (gitignored) and set `WORKSPACE_ENTRIES`.

Setup builds the app bundle, picker binary, icon (when tools exist), Dock entry. Picker lists workspaces with **checkboxes**; pick **Open** or **Append**, then **OK**. **Open** opens a new window then appends with `cursor -a`; **Append** adds to the frontmost window; **Cancel** exits. If Gatekeeper blocks first launch, right-click → **Open** once.

### Rollback

```bash
[ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
[ -L "$HOME/.gitconfig" ] && rm "$HOME/.gitconfig"
[ -L "$HOME/.cursor/rules" ] && rm "$HOME/.cursor/rules"
[ -L "$HOME/.cursor/commands" ] && rm "$HOME/.cursor/commands"
[ -L "$HOME/.cursor/extensions.txt" ] && rm "$HOME/.cursor/extensions.txt"
[ -L "$HOME/.cursor/core" ] && rm "$HOME/.cursor/core"

[ -e "$HOME/.zshrc.bak" ] && mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
[ -e "$HOME/.gitconfig.bak" ] && mv "$HOME/.gitconfig.bak" "$HOME/.gitconfig"
[ -e "$HOME/.cursor/rules.bak" ] && mv "$HOME/.cursor/rules.bak" "$HOME/.cursor/rules"
[ -e "$HOME/.cursor/commands.bak" ] && mv "$HOME/.cursor/commands.bak" "$HOME/.cursor/commands"
[ -e "$HOME/.cursor/extensions.txt.bak" ] && mv "$HOME/.cursor/extensions.txt.bak" "$HOME/.cursor/extensions.txt"
[ -e "$HOME/.cursor/core.bak" ] && mv "$HOME/.cursor/core.bak" "$HOME/.cursor/core"

for f in "$DOTFILES_ROOT/config"/*; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  dest="$HOME/.config/$b"
  [ -L "$dest" ] && rm "$dest"
  [ -e "$HOME/.config/${b}.bak" ] && mv "$HOME/.config/${b}.bak" "$dest"
done
```

## Status

> Last updated: 2026-04-11

Recovery steps match root install automation (nested `CURSOR_CONFIG_ROOT` guards, conditional Cursor targets, extension sync unless `SKIP_CURSOR_EXTENSIONS=1`, Darwin launcher dispatch) and tracked shell **`PATH`** for Cursor CLI helpers when home shell config resolves into this checkout.

Smoke checks align with [tools/smoke-check.sh](tools/smoke-check.sh): Cursor tree shape (`commands/`, `rules/`, `extensions.txt`), playbook catalog links, nested-path guards, and optional host tools; `skills-cursor/` is not checked (managed by Cursor). Config link and rollback mirror backup and **`mkdir -p`** behavior from the same automation.
