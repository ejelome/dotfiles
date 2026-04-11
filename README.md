# dotfiles

[![Smoke check](https://img.shields.io/github/actions/workflow/status/ejelome/dotfiles/smoke-check.yml?branch=main&label=smoke%20check)](https://github.com/ejelome/dotfiles/actions/workflows/smoke-check.yml)

macOS shell, Git, and Cursor configuration symlinked into `~` and `~/.cursor` via `link.sh`.

---

**Table of contents**

- [Structure](#structure)
- [What's included](#whats-included)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [What link.sh does](#what-linksh-does)
- [Usage](#usage)
- [Contributing](#contributing)
- [Status](#status)

---

## Structure

```text
dotfiles/
├── .github/                  # CI workflows (smoke-check on push/PR)
├── config/                   # symlinked to ~/.config/ by basename (Starship TOML, etc.)
├── cursor/                   # default CURSOR_CONFIG_ROOT → ~/.cursor (rules, commands, core, extensions.txt)
├── launcher/                 # macOS workspace launcher; builds CursorWorkspaceLauncher.app
├── scripts/                  # small helpers (e.g. ext.sh); not symlinked by link.sh
├── tools/                    # maintenance scripts; smoke-check.sh, cursor-cli/
├── .cursorignore
├── .gitignore
├── .markdownlint.json        # markdownlint rule overrides (used by smoke-check and CI)
├── AGENTS.md
├── Brewfile
├── CHANGELOG.md
├── MANUAL.md
├── OWNERS.md
├── README.md
├── gitconfig                 # global Git defaults; includes ~/.gitconfig.local for identity
├── gitconfig.local.example   # copy to ~/.gitconfig.local (not symlinked)
├── link.sh                   # idempotent symlink installer
├── zshrc
└── zshrc.local.example       # copy to ~/.zshrc.local for secrets (not symlinked)
```

## What's included

| Area | Files / tools |
| --- | --- |
| Shell | `zshrc` → `~/.zshrc`; Starship prompt (dark/light theme detection); zsh-autosuggestions; zsh-syntax-highlighting; fzf key bindings and completions; zoxide (`z`); eza aliases (`ls`, `ll`, `la`) |
| Git | `gitconfig` → `~/.gitconfig`; Git LFS filter; identity delegated to `~/.gitconfig.local` (not tracked) |
| Cursor rules | `cursor/rules/*.mdc` → `~/.cursor/rules`; always-on and requestable rules |
| Cursor commands | `cursor/commands/*.md` → `~/.cursor/commands`; slash playbooks (`/git-commit`, `/docs-readme`, `/eval-tune`, and others) |
| Cursor core | `cursor/core/` → `~/.cursor/core`; authoring canon (style guide, document standard) |
| Cursor extensions | `cursor/extensions.txt` → `~/.cursor/extensions.txt`; extension IDs installed by `install-extensions.sh` |
| Config files | `config/*` → `~/.config/` by basename; includes `starship.dark.toml` and `starship.light.toml` |
| macOS launcher | `launcher/` — builds `CursorWorkspaceLauncher.app` (workspace picker with checkboxes) |
| CI | `.github/workflows/smoke-check.yml` — runs `tools/smoke-check.sh` on Ubuntu and macOS |

## Prerequisites

| Tool | Purpose | Install |
| --- | --- | --- |
| Homebrew | Package manager | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| Zsh | Shell | Included on macOS |
| Git | Version control | `brew install git` or `xcode-select --install` |
| Git LFS | LFS filter (`required = true` in `gitconfig`) | `brew install git-lfs && git lfs install` |
| Starship | Prompt | `brew install starship` |
| fzf | Fuzzy finder | `brew install fzf` |
| zoxide | Directory jumping (`z`) | `brew install zoxide` |
| eza (optional) | Enhanced `ls` aliases | `brew install eza` |
| nvm (optional) | Lazy-loaded Node runtime | `brew install nvm` |

All of the above are in [Brewfile](Brewfile) (`brew bundle`), along with `shellcheck` and `markdownlint-cli` for local smoke checks.

The macOS workspace launcher additionally requires `swiftc`, `osascript`, `defaults`, `killall`, `mktemp`, and `python3`; see [launcher/lib/config.sh](launcher/lib/config.sh).

## Install

```bash
git clone https://github.com/ejelome/dotfiles.git
cd dotfiles
cp gitconfig.local.example ~/.gitconfig.local
# Edit ~/.gitconfig.local: set user.name and user.email.
cp zshrc.local.example ~/.zshrc.local
# Edit ~/.zshrc.local: set GITHUB_TOKEN and any machine-specific exports.
chmod 600 ~/.gitconfig.local ~/.zshrc.local
./link.sh
```

Then clone the shell plugins (no plugin manager):

```bash
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

Restart your shell or run:

```bash
source ~/.zshrc
```

## What link.sh does

`link.sh` is idempotent and non-destructive, and runs in this order:

1. **Strips self-referential nested symlinks** under `CURSOR_CONFIG_ROOT` (`rules/rules`, `commands/commands`, `core/core`) before and after linking. Cursor can recreate these when the open workspace is this repo; the script removes them automatically.

2. **Backs up any existing non-symlink** at each destination by renaming it to `<dest>.bak` before overwriting.

3. **Creates symlinks:**
   - `zshrc` → `~/.zshrc`
   - `gitconfig` → `~/.gitconfig`
   - Each file under `config/` → `~/.config/<basename>`
   - `cursor/rules/` → `~/.cursor/rules` (when the directory exists under `CURSOR_CONFIG_ROOT`)
   - `cursor/commands/` → `~/.cursor/commands` (when the directory exists)
   - `cursor/core/` → `~/.cursor/core` (when the directory exists)
   - `cursor/extensions.txt` → `~/.cursor/extensions.txt` (when the file exists)

4. **Builds `CursorWorkspaceLauncher.app`** on macOS by running `launcher/setup-cursor-workspace-launcher.sh`. Skipped on Linux or if the script is absent.

5. **Syncs Cursor extensions** by running `tools/cursor-cli/install-extensions.sh` when the `cursor` CLI is on `PATH` and `~/.cursor/extensions.txt` exists. Set `SKIP_CURSOR_EXTENSIONS=1` to skip this step.

**What link.sh does not do:** `link.sh` does not modify any file under `$HOME` that is not a symlink destination listed above. `link.sh` does not run destructive helpers (e.g. `clear-chat.sh`). `link.sh` does not touch `~/.cursor/skills-cursor/` (managed by Cursor itself).

To keep Cursor config outside this clone, set `CURSOR_CONFIG_ROOT` to an absolute path before running `link.sh`:

```bash
CURSOR_CONFIG_ROOT=/path/to/cursor-config ./link.sh
```

To roll back all symlinks:

```bash
[ -L ~/.zshrc ] && rm ~/.zshrc
[ -L ~/.gitconfig ] && rm ~/.gitconfig
[ -L ~/.cursor/rules ] && rm ~/.cursor/rules
[ -L ~/.cursor/commands ] && rm ~/.cursor/commands
[ -L ~/.cursor/core ] && rm ~/.cursor/core
[ -L ~/.cursor/extensions.txt ] && rm ~/.cursor/extensions.txt
```

Then restore any `.bak` files manually. Full recovery steps are in [MANUAL.md](MANUAL.md).

## Usage

**Re-run after pulling changes:**

```bash
./link.sh
```

**Validate the repo layout (same checks as CI):**

```bash
./tools/smoke-check.sh
```

**Git identity:** Edit `~/.gitconfig.local` (included by the symlinked `gitconfig`). Never put name or email in the tracked `gitconfig`.

**Secrets and machine-specific exports:** Edit `~/.zshrc.local` (sourced at the end of `zshrc`). Never commit tokens.

**Cursor extensions:** To export the current extension list:

```bash
cursor --list-extensions > cursor/extensions.txt
```

To install from the manifest manually:

```bash
./tools/cursor-cli/install-extensions.sh
```

**Clear Cursor chat history** (destructive — not run by `link.sh`): quit Cursor first, then:

```bash
./tools/cursor-cli/clear-chat.sh
```

**Cursor slash commands** install to `~/.cursor/commands` and are available as `/name` in the Cursor chat panel. The full catalog is [cursor/commands/commands.md](cursor/commands/commands.md).

## Contributing

Pull requests are welcome. For larger changes, open an issue first to align on direction before investing time.

Edit tracked files in this clone, not symlink targets under `$HOME`. Run `./tools/smoke-check.sh` before submitting. See [AGENTS.md](AGENTS.md) for the agent on-ramp and [OWNERS.md](OWNERS.md) for path ownership.

Do not nest `rules/rules/`, `commands/commands/`, or `core/core/` under `CURSOR_CONFIG_ROOT` — this creates a symlink loop that `link.sh` and `smoke-check.sh` guard against.

## Status

No rolling "last updated" line here (manual upkeep only); chronological history: [CHANGELOG.md](CHANGELOG.md).

Stable for daily macOS shell, Git, and Cursor workflows via `link.sh` and `CURSOR_CONFIG_ROOT`; docs-first rules, slash commands, and Agent Skills ship under `cursor/`.

Ongoing refinement covers [core canon](cursor/core/), the slash catalog (`/eval-tune` plus `/eval-uid`, `/eval-wse`, `/eval-igd`, and `/eval-ops` in [cursor/commands/commands.md](cursor/commands/commands.md)), smoke-check CI, the macOS workspace launcher, and path roles in [OWNERS.md](OWNERS.md).
