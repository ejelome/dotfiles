# dotfiles

macOS shell, Git, and Cursor configuration for people who want a repeatable local development environment.

---

**Table of Contents**

- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Usage](#usage)
- [Documentation](#documentation)
- [Conventions](#conventions)
- [Status](#status)

---

## Structure

Core shell, Git, prompt, and Cursor rule files are tracked here and linked into your home directory.

```text
dotfiles/
├── config/            # symlinked to ~/.config by basename
├── cursor/            # symlinked to ~/.cursor/rules
├── macos/             # macOS helper scripts
├── .gitignore         # ignore rules for local and generated files
├── CHANGELOG.md       # release notes and change history
├── gitconfig          # global Git aliases and behavior defaults
├── link.sh            # idempotent symlink installer script
├── MANUAL.md          # detailed operational and troubleshooting guide
├── README.md          # quick-start and repository overview
└── zshrc              # shell aliases, functions, and environment settings
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

## Install

Clone the repository and run the linker script:

```bash
git clone https://github.com/ejelome/dotfiles.git
cd dotfiles
./link.sh
```

## Usage

Apply or refresh symlinks:

```bash
./link.sh
```

Set Git identity after first setup:

```bash
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_EMAIL@example.com"
```

Install shell plugin dependencies outside the repository:

```bash
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

## Documentation

See [MANUAL.md](MANUAL.md) for detailed behavior, manual fallback steps, and launcher build commands.

## Conventions

- Edit tracked files in this repository, not the symlink destinations.
- `link.sh` links `zshrc` to `~/.zshrc` and `gitconfig` to `~/.gitconfig`.
- `link.sh` links files in `config/` to `~/.config/` by basename.
- `link.sh` links `cursor/rules/` to `~/.cursor/rules`.
- On macOS, `link.sh` also runs `launcher/setup-cursor-workspace-launcher.sh` to build/update the `CursorWorkspaceLauncher.app` bundle.

## Status

> Last updated: 2026-03-24

The setup is stable for daily use, and symlink workflows are verified by `link.sh`.
Current work focuses on README and Cursor rule quality improvements.

See [CHANGELOG.md](CHANGELOG.md) for full history.
