# dotfiles

My personal dotfiles for `zsh`, Starship, Git, Cursor rules, and dev tooling.

## Table of contents

- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Install and setup](#install-and-setup)
- [Configuration](#configuration)

## Structure

```
dotfiles/
├── config/          # XDG config; symlinked to ~/.config
│   ├── starship.dark.toml # Starship prompt, dark theme
│   ├── starship.light.toml# Starship prompt, light theme
│   └── starship.toml      # Starship prompt (base/alternate config)
├── cursor/          # Cursor IDE; rules symlinked to ~/.cursor/rules
│   └── rules/       # .mdc rules applied by Cursor (snapshot varies by week)
│       ├── auto-code-style-ts.mdc            # TypeScript: ESLint, Prettier; globs *.ts, *.tsx
│       ├── compare-compact.mdc               # Compare original vs refined markdown; preserve and compact
│       ├── create-issue.mdc                  # Copy-paste issue, branch, commit, PR fields; no code
│       ├── handle-changelog.mdc              # Create/update CHANGELOG structure and format
│       ├── handle-readme.mdc                 # Create/update README structure, tone, maintenance
│       └── implement-issue.mdc               # Run implement-issue: placeholders, infer, or execute
├── .gitignore       # Ignore OS cruft (.DS_Store), swap files, local overrides (*.local, .env*)
├── gitconfig        # Git user name, email, LFS filter (clean/smudge)
├── link.sh          # Symlink dotfiles into $HOME; back up existing to *.bak
├── README.md        # This repo: structure, prerequisites, install, configuration
└── zshrc            # zsh: PATH, theme, completions, nvm, plugins, zoxide, Starship, eza
```

Plugins (`autosuggestions`, `syntax-highlighting`) live outside the repo; see [Configuration](#configuration).

## Prerequisites

Everything is installed via Homebrew:

 ```bash
# Install Homebrew if missing:
 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
 ```

| Tool | Role | Install |
|------|------|---------|
| **zsh** | Default shell.<br />Runs `zshrc`. | Included by default. |
| **Starship** | Theme-aware prompt. | `brew install starship` |
| **fzf** | Fuzzy finder.<br />(key bindings + completion). | `brew install fzf`,<br />then `$(brew --prefix)/opt/fzf/install` |
| **zoxide** | Smarter `cd`.<br />`z` jumps to frequent dirs. | `brew install zoxide` |
| **eza** (optional) | `ls` / `ll` / `la` aliases.<br />Icons and git status. | `brew install eza`.<br />If missing, normal `ls` is used. |
| **nvm** (optional) | Lazy-loaded Node.<br />`node` / `npm` / `npx` trigger load. | `brew install nvm`,<br />then add the export Homebrew prints.<br />`zshrc` expects `/opt/homebrew/opt/nvm/nvm.sh`. |
| **Git** | Version control and `gitconfig`. | `brew install git`<br />or `xcode-select --install` |

## Install and setup

1. **Clone and symlink into `$HOME`:**

   ```bash
   git clone git@github.com:ejelome/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./link.sh
   ```

   `link.sh`:
   - Backs up existing `~/.zshrc`, `~/.gitconfig`, and `~/.cursor/rules` (if present) to `*.bak`.
   - Creates `~/.config` and `~/.cursor` if missing.

2. **Set Git name and email** (or edit `~/.gitconfig`):

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```

3. **Reload shell config:**

   ```bash
   source ~/.zshrc
   ```

Tested on macOS. 

Theme and plugins: [Configuration](#configuration).

## Configuration

- **Theme**
  - `zshrc` reads dark/light from `defaults read -g AppleInterfaceStyle`.
  - Sets `STARSHIP_CONFIG` and `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`.
  - Starship configs live in `config/`; `link.sh` symlinks them to `~/.config/`.
  - See [Starship's docs](https://starship.rs/config/) to customize.

- **Cursor rules**
  - `cursor/rules/` is symlinked to `~/.cursor/rules` so Cursor uses the same rules across machines.
  - Edit in the repo; they apply after Cursor reloads.
  - Only `rules/` is versioned; skills, MCP config, and project state stay local.

- **Zsh plugins**
  - Clone into `~/.zsh/plugins/` so `zshrc` can source them:

  ```bash
  mkdir -p ~/.zsh/plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
  ```
# dotfiles

My personal dotfiles for `zsh`, Starship, Git, Cursor rules, and dev tooling.

## Table of contents

- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Install and setup](#install-and-setup)
- [Configuration](#configuration)

## Structure

```
dotfiles/
├── config/          # XDG config; symlinked to ~/.config
│   ├── starship.dark.toml # Starship prompt, dark theme
│   ├── starship.light.toml# Starship prompt, light theme
│   └── starship.toml      # Starship prompt (base/alternate config)
├── cursor/          # Cursor IDE; rules symlinked to ~/.cursor/rules
│   └── rules/       # .mdc rules applied by Cursor (snapshot varies by week)
│       └── auto-code-style-ts.mdc            # TypeScript: ESLint, Prettier; globs *.ts, *.tsx
├── .gitignore       # Ignore OS cruft (.DS_Store), swap files, local overrides (*.local, .env*)
├── gitconfig        # Git user name, email, LFS filter (clean/smudge)
├── link.sh          # Symlink dotfiles into $HOME; back up existing to *.bak
├── README.md        # This repo: structure, prerequisites, install, configuration
└── zshrc            # zsh: PATH, theme, completions, nvm, plugins, zoxide, Starship, eza
```

Plugins (`autosuggestions`, `syntax-highlighting`) live outside the repo; see [Configuration](#configuration).

## Prerequisites

Everything is installed via Homebrew:

 ```bash
# Install Homebrew if missing:
 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
 ```

| Tool | Role | Install |
|------|------|---------|
| **zsh** | Default shell.<br />Runs `zshrc`. | Included by default. |
| **Starship** | Theme-aware prompt. | `brew install starship` |
| **fzf** | Fuzzy finder.<br />(key bindings + completion). | `brew install fzf`,<br />then `$(brew --prefix)/opt/fzf/install` |
| **zoxide** | Smarter `cd`.<br />`z` jumps to frequent dirs. | `brew install zoxide` |
| **eza** (optional) | `ls` / `ll` / `la` aliases.<br />Icons and git status. | `brew install eza`.<br />If missing, normal `ls` is used. |
| **nvm** (optional) | Lazy-loaded Node.<br />`node` / `npm` / `npx` trigger load. | `brew install nvm`,<br />then add the export Homebrew prints.<br />`zshrc` expects `/opt/homebrew/opt/nvm/nvm.sh`. |
| **Git** | Version control and `gitconfig`. | `brew install git`<br />or `xcode-select --install` |

## Install and setup

1. **Clone and symlink into `$HOME`:**

   ```bash
   git clone git@github.com:ejelome/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./link.sh
   ```

   `link.sh`:
   - Backs up existing `~/.zshrc`, `~/.gitconfig`, and `~/.cursor/rules` (if present) to `*.bak`.
   - Creates `~/.config` and `~/.cursor` if missing.

2. **Set Git name and email** (or edit `~/.gitconfig`):

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```

3. **Reload shell config:**

   ```bash
   source ~/.zshrc
   ```

Tested on macOS. 

Theme and plugins: [Configuration](#configuration).

## Configuration

- **Theme**
  - `zshrc` reads dark/light from `defaults read -g AppleInterfaceStyle`.
  - Sets `STARSHIP_CONFIG` and `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`.
  - Starship configs live in `config/`; `link.sh` symlinks them to `~/.config/`.
  - See [Starship's docs](https://starship.rs/config/) to customize.

- **Cursor rules**
  - `cursor/rules/` is symlinked to `~/.cursor/rules` so Cursor uses the same rules across machines.
  - Edit in the repo; they apply after Cursor reloads.
  - Only `rules/` is versioned; skills, MCP config, and project state stay local.

- **Zsh plugins**
  - Clone into `~/.zsh/plugins/` so `zshrc` can source them:

  ```bash
  mkdir -p ~/.zsh/plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
  ```
