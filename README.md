# dotfiles

macOS shell, Git, and Cursor configuration for people who want a repeatable local development environment.

[![QA](https://img.shields.io/github/actions/workflow/status/ejelome/dotfiles/qa.yml?label=QA&logo=github)](https://github.com/ejelome/dotfiles/actions/workflows/qa.yml)

---

**Table of Contents**

- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
  - [Cursor extensions](#cursor-extensions)
- [Documentation](#documentation)
- [Agent context](#agent-context)
- [Conventions](#conventions)
- [Status](#status)

---

## Structure

Core shell, Git, prompt, and Cursor rule files are tracked here and linked into your home directory.

At each directory level the tree lists **subdirectories first** (A-Z), then **files** (A-Z), using ASCII order (names starting with `.` sort before `A`).

```text
dotfiles/
├── config/            # symlinked to ~/.config by basename
├── cursor/
│   ├── commands/      # symlinked to ~/.cursor/commands (slash commands)
│   ├── rules/         # symlinked to ~/.cursor/rules
│   ├── skills-cursor/ # symlinked to ~/.cursor/skills-cursor
│   └── extensions.txt # Cursor extension IDs for repeatable installs (not symlinked)
├── launcher/          # Cursor workspace app: setup script, templates, icons
├── scripts/           # maintenance helpers (qa.sh, ext.sh)
├── .cursorignore      # trims Cursor index (e.g. .git)
├── .gitignore         # ignore rules for local and generated files
├── AGENTS.md          # on-ramp for coding agents (Cursor, rules, skills, commands)
├── Brewfile           # optional `brew bundle` mirror of CLI prerequisites
├── CHANGELOG.md       # release notes and change history
├── gitconfig          # global Git defaults (includes ~/.gitconfig.local for identity)
├── gitconfig.local.example  # copy to ~/.gitconfig.local for name/email (not symlinked)
├── link.sh            # idempotent symlink installer script
├── MANUAL.md          # detailed operational and troubleshooting guide
├── README.md          # quick-start and repository overview
├── zshrc              # shell aliases, functions, and environment settings
└── zshrc.local.example  # copy to ~/.zshrc.local for GITHUB_TOKEN and other secrets (not symlinked)
```

## Prerequisites

| Tool | Purpose | Install |
| --- | --- | --- |
| Homebrew | Package manager for dependencies | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| Zsh | Shell that loads `zshrc` | Included by default on macOS |
| Starship | Theme-aware prompt | `brew install starship` |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | `brew install fzf` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Directory jumping via `z` | `brew install zoxide` |
| [eza](https://github.com/eza-community/eza) (optional) | Enhanced `ls` aliases (`ll`, `la`) | `brew install eza` |
| [nvm](https://github.com/nvm-sh/nvm) (optional) | Lazy-loaded Node runtime in `zshrc` | `brew install nvm` |
| Git | Version control and `gitconfig` support | `brew install git` or `xcode-select --install` |
| [Git LFS](https://git-lfs.com) | Tracked [gitconfig](gitconfig) registers `filter.lfs` with `required = true` | `brew install git-lfs` then `git lfs install` |

The macOS workspace launcher also requires tools listed in [launcher/lib/config.sh](launcher/lib/config.sh) (`REQUIRED_TOOLS`, `OPTIONAL_ICON_TOOLS`), including `swiftc` and `python3`, separate from this table.

Declarative installs for the Homebrew CLI tools above: [Brewfile](Brewfile) (`brew bundle`).

## Install

Clone the repository and run the linker script:

```bash
git clone https://github.com/ejelome/dotfiles.git
cd dotfiles
cp gitconfig.local.example ~/.gitconfig.local
# Edit ~/.gitconfig.local with your name and email.
cp zshrc.local.example ~/.zshrc.local
# Edit ~/.zshrc.local: set GITHUB_TOKEN (needed for GitHub CLI/API tooling on many projects).
chmod 600 ~/.gitconfig.local ~/.zshrc.local
./link.sh
```

## Usage

Apply or refresh symlinks:

```bash
./link.sh
```

Git user identity lives in `~/.gitconfig.local` (included by the symlinked `gitconfig`). Prefer editing that file so `git config --global user.*` does not write into the repository's `gitconfig` by mistake.

`~/.zshrc.local` is sourced at the end of the symlinked `zshrc`. Put `GITHUB_TOKEN` and other secrets there (see [zshrc.local.example](zshrc.local.example)); do not commit real tokens.

Install shell plugin dependencies outside the repository:

```bash
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

### Cursor extensions

[`cursor/extensions.txt`](cursor/extensions.txt) lists extension IDs in **unpinned** form (`publisher.name` per line). That keeps the manifest small and lets Cursor update extensions normally; fresh machines get current versions from the marketplace. If you prefer **pinned** versions for reproducible installs, maintain the file with `cursor --list-extensions --show-versions` instead (see [MANUAL](MANUAL.md)).

After `./link.sh`, install everything in the manifest (skips already-installed ids):

```bash
./scripts/ext.sh
```

The manifest is **not** symlinked; it is only a checklist. Removing an id from `extensions.txt` does **not** uninstall that extension on a machine that already has it.

## Documentation

See [MANUAL](MANUAL.md) for detailed behavior, manual fallback steps, and launcher build commands.

Smoke-check tracked bash and zsh (including `zshrc`, `link.sh`, `scripts/ext.sh`, and launcher libs), Python `dock_update.py`, `gitconfig`, Starship `config/starship*.toml` when `starship` is on `PATH`, and Swift picker template parse on macOS when `swiftc` is available. Verifies `cursor/commands` and `cursor/skills-cursor` are populated and fails if nested `cursor/rules/rules`, `cursor/skills-cursor/skills-cursor`, or `cursor/commands/commands` exists (same guard as `link.sh`); it does not validate `cursor/rules/*.mdc` content. When `shellcheck` or `markdownlint` is installed, runs those on the matching paths (Markdown lint skips `cursor/rules/`).

```bash
./scripts/qa.sh
```

## Agent context

See [AGENTS](AGENTS.md) for where rules and skills live, how `link.sh` wires Cursor, and how to avoid duplicating always-on rules in `Cursor Settings → Rules for AI`. Tracked skills under `cursor/skills-cursor/` include hooks, CLI config, and status line helpers alongside rule and command authoring guides.

## Conventions

- Edit tracked files in this repository, not the symlink destinations
- `link.sh` links `zshrc` to `~/.zshrc` and `gitconfig` to `~/.gitconfig`
- Git identity files live in `~/.gitconfig.local` (see [gitconfig.local.example](gitconfig.local.example))
- Shell secrets live in `~/.zshrc.local` (see [zshrc.local.example](zshrc.local.example))
- `link.sh` links files in `config/` to `~/.config/` by basename
- `link.sh` links `cursor/rules/` to `~/.cursor/rules` and `cursor/skills-cursor/` to `~/.cursor/skills-cursor`
- `link.sh` links `cursor/commands/` to `~/.cursor/commands`
- `cursor/extensions.txt` is tracked for repeatable Cursor extension installs
- Run `./scripts/ext.sh` after `./link.sh` when installing extensions (not linked by `link.sh`)
- Do not nest `cursor/rules/rules/` or `cursor/skills-cursor/skills-cursor/` in the repo (recursive symlink hazard)
- Do not nest `cursor/commands/commands` in the repo (same hazard)
- `link.sh` and [MANUAL](MANUAL.md) document the flat layout
- On macOS, `link.sh` runs `launcher/setup-cursor-workspace-launcher.sh` to build or update `CursorWorkspaceLauncher.app`
- This repo does not use a root `.cursorrules` file; Cursor loads `cursor/rules/*.mdc` from this tree via `link.sh`

## Status

> Last updated: 2026-04-05

The setup is stable for daily use, and symlink workflows are verified by `link.sh`.
Cursor rules, bundled skills, slash commands, and launcher tooling stay the active surface.

See [CHANGELOG](CHANGELOG.md) for full history.
