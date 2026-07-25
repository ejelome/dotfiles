# dotfiles

Personal macOS configuration for Zsh, Git, and Starship. `link.sh` keeps the
tracked files in this checkout and symlinks them into the locations used by
the shell and related tools.

Current release: [v2026.07.25](CHANGELOG.md#2026-07-25---2026-07-25).

## Features

- Dark and light Starship configurations selected from the macOS appearance.
- Lazy nvm loading for Node.js commands.
- Optional fzf, zoxide, eza, autosuggestion, and syntax-highlighting support.
- Shared Git defaults with identity and machine settings kept in a local file.
- Recoverable linking that backs up existing non-symlink destinations.
- Calendar records validated before local and hosted sharing.

## Requirements

- macOS with Zsh and Bash.
- Git, Git LFS, and the GitHub CLI for the tracked Git configuration.
- Starship for the prompt.
- ShellCheck and Markdownlint for the complete validation suite.
- Optional shell tools are detected before use and may be omitted.

## Installation

Clone the repository and prepare the machine-local overrides:

```sh
git clone https://github.com/ejelome/dotfiles.git
cd dotfiles
cp gitconfig.local.example ~/.gitconfig.local
cp zshrc.local.example ~/.zshrc.local
chmod 600 ~/.gitconfig.local ~/.zshrc.local
```

Edit the two local files for this machine, then project the tracked
configuration:

```sh
./link.sh
```

## Usage

```sh
./link.sh
source ~/.zshrc
```

Run `./link.sh` again after pulling or changing tracked files. The script moves
an existing non-symlink destination to `<destination>.bak` before linking it.
It also installs the tracked pre-push gate through `core.hooksPath`.
Secrets, identity, and machine-specific exports belong in
`~/.gitconfig.local` and `~/.zshrc.local`, never in this repository.

## Structure

```text
.
├── .github/
│   └── workflows/
│       └── validate.yml       # Hosted calendar-record gate
├── .githooks/
│   └── pre-push              # Tracked local sharing gate
├── config/
│   ├── starship.dark.toml     # Dark appearance prompt
│   ├── starship.light.toml    # Light appearance prompt
│   └── starship.toml          # Default prompt
├── tools/
│   └── validate-history.sh    # Calendar-record validator
├── .gitignore
├── .markdownlint.json         # Markdown style rules
├── CHANGELOG.md               # Calendar-dated project changes
├── MANUAL.md                  # Manual fallback for link.sh
├── README.md
├── gitconfig                  # Shared Git configuration
├── gitconfig.local.example    # Machine-local identity template
├── link.sh                    # Configuration projector
├── zshrc                      # Zsh configuration
└── zshrc.local.example        # Machine-local shell template
```

## Documentation

- Use the [manual link fallback](MANUAL.md) when `link.sh` is unavailable.
- Review notable changes in the [changelog](CHANGELOG.md).

## Validation

Run the maintained checks before sharing changes:

```sh
bash -n link.sh
zsh -n zshrc
git config --file gitconfig --list
shellcheck link.sh tools/validate-history.sh .githooks/pre-push
markdownlint README.md MANUAL.md CHANGELOG.md
bash tools/validate-history.sh
```

`link.sh` installs `.githooks/pre-push`, and hosted validation runs the same
calendar-record check. Each calendar tag has a one-sentence subject followed
by a three-to-five-sentence summary ending with its exact project footprint.

## Support

This is a personal configuration repository with no support SLA. Report a
reproducible problem through
[GitHub Issues](https://github.com/ejelome/dotfiles/issues).

## Maintainer

Maintained by [ejelome](https://github.com/ejelome).

## Project status

Actively maintained for the maintainer's macOS environment. Other platforms
are not a compatibility target.
