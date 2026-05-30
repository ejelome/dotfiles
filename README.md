# dotfiles

My shell, Git, and Starship configs symlinked into place by `link.sh`.

---

**Table of contents**

- [Setup](#setup)
- [Usage](#usage)
- [Structure](#structure)
- [Links](#links)

---

## Setup

```sh
git clone https://github.com/ejelome/dotfiles.git
cd dotfiles
cp gitconfig.local.example ~/.gitconfig.local
cp zshrc.local.example ~/.zshrc.local
chmod 600 ~/.gitconfig.local ~/.zshrc.local
./link.sh
```

## Usage

```sh
./link.sh        # re-run after pulling or editing tracked files
source ~/.zshrc  # reload after changing zshrc
```

## Structure

```
dotfiles/
├── config/                    # Starship prompt configs (dark + light variants)
├── gitconfig                  # Git configuration
├── gitconfig.local.example    # Template: name, email, signing key
├── link.sh                    # Symlinks configs into ~ and ~/.config/
├── zshrc                      # Zsh configuration
├── zshrc.local.example        # Template: local Zsh overrides
├── MANUAL.md                  # Manual linking steps (no link.sh)
├── REPOSITORY.md              # Repository contract
└── CHANGELOG.md
```

## Links

- [Manual fallback](MANUAL.md)
- [Repository contract](REPOSITORY.md)
- [Changelog](CHANGELOG.md)

---

> Last updated: 2026-05-30
