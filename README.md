# dotfiles

![Smoke check](https://github.com/ejelome/dotfiles/actions/workflows/smoke-check.yml/badge.svg)

Dotfiles for shell, Git, and local development workflows.

![Terminal session with this dotfiles setup](screenshot.png)

---

**Table of contents**

- [Overview](#overview)
- [Setup](#setup)
- [Usage](#usage)
- [Structure](#structure)
- [Links](#links)
- [Status](#status)

---

## Overview

This repository is the source of truth for shell, Git, and local dev settings. Clone it, then run `./link.sh` to create local symlinks. Re-run `./link.sh` after pulling or editing tracked files to keep symlinks current. [REPOSITORY.md](REPOSITORY.md) defines the authoritative repo-runtime contract.

## Setup

1. `git clone https://github.com/ejelome/dotfiles.git`
2. `cd dotfiles`
3. `brew bundle`
4. `cp gitconfig.local.example ~/.gitconfig.local && cp zshrc.local.example ~/.zshrc.local && chmod 600 ~/.gitconfig.local ~/.zshrc.local`
5. `./link.sh`
6. `./link.sh --install-zsh-plugins` (optional Zsh plugin bootstrap)

## Usage

Re-run `./link.sh` after pulling, switching branches, or editing tracked config so `~` reflects the repository.

Before pushing or after changing paths that the checks enforce, run:

```bash
SKIP_TESTS_RUN=1 ./tools/smoke-check.sh
./tests/run.sh
```

## Structure

- `.github/` — CI workflows for smoke checks and shell tests on Ubuntu and macOS
- `config/` — Starship shared configuration
- `launcher/` — Cursor workspace launcher setup scripts
- `tests/` — shell regression suite
- `tools/` — smoke check, link helpers, and agent checks
- `link.sh` — entry point for projecting this tree into `~`

## Links

- [REPOSITORY.md](REPOSITORY.md)
- [AGENTS.md](AGENTS.md)
- [MANUAL.md](MANUAL.md)
- [CHANGELOG.md](CHANGELOG.md)

## Status

> Last updated: 2026-04-26

CI runs smoke checks and shell tests on Ubuntu and macOS. `link.sh` is the supported way to project this repository’s shell configuration.

See [CHANGELOG.md](CHANGELOG.md) for full history.
