# Manual link fallback

Use these steps when you need to reproduce `link.sh` by hand.

---

**Table of contents**

- [Prerequisites](#prerequisites)
- [Project dotfiles into runtime paths](#project-dotfiles-into-runtime-paths)
  - [Link required home files](#link-required-home-files)
  - [Link Starship config files](#link-starship-config-files)
  - [Link Cursor User settings](#link-cursor-user-settings)
  - [Install or expose Cursor](#install-or-expose-cursor)
  - [Build the Cursor workspace launcher](#build-the-cursor-workspace-launcher)
  - [Install Zsh plugins](#install-zsh-plugins)
- [Manual helper fallback](#manual-helper-fallback)
- [Verification](#verification)
- [Status](#status)

---

## Prerequisites

- Use a checkout of this repository as the source tree.
- Use `bash` for shell helpers and `zsh` for `zshrc` and launcher scripts.
- Install Homebrew when you want `brew bundle`, optional Cursor cask installation, or the macOS launcher path.
- Install `git` before using the optional Zsh plugin helper.
- Create local overrides yourself when needed:

```bash
cp gitconfig.local.example ~/.gitconfig.local
cp zshrc.local.example ~/.zshrc.local
chmod 600 ~/.gitconfig.local ~/.zshrc.local
```

Read [REPOSITORY.md](REPOSITORY.md) before editing tracked source or runtime paths.

## Project dotfiles into runtime paths

These steps mirror the side effects of `./link.sh`.

### Link required home files

1. Set `<repo>` to the absolute path of this checkout.
2. For each target below, move an existing non-symlink destination to `<destination>.bak`.
3. Create the destination parent directory with `mkdir -p`.
4. Link the source to the destination with `ln -sf`.

| Source | Destination |
| --- | --- |
| `<repo>/zshrc` | `~/.zshrc` |
| `<repo>/gitconfig` | `~/.gitconfig` |

### Link Starship config files

1. For each file under `<repo>/config/`, create `~/.config` when needed.
2. Move an existing non-symlink `~/.config/<name>` to `~/.config/<name>.bak`.
3. Link the file to `~/.config/<name>` with `ln -sf`.

### Link Cursor User settings

1. Choose the Cursor User directory for the platform:

   | Platform | Cursor User directory |
   | --- | --- |
   | macOS | `~/Library/Application Support/Cursor/User` |
   | Linux or other with `XDG_CONFIG_HOME` | `$XDG_CONFIG_HOME/Cursor/User` |
   | Linux or other without `XDG_CONFIG_HOME` | `~/.config/Cursor/User` |

2. Create the Cursor User directory with `mkdir -p`.
3. Link these files when they exist:

   | Source | Destination name |
   | --- | --- |
   | `<repo>/cursor/settings.json` | `settings.json` |
   | `<repo>/cursor/keybindings.json` | `keybindings.json` |

4. Move an existing non-symlink destination to `<destination>.bak` before linking.

Do not copy or link Cursor runtime framework files into `~/.cursor`; this repository owns only Cursor User settings.

### Install or expose Cursor

1. Skip this step when the `cursor` command is already on `PATH`.
2. **macOS:** add `/Applications/Cursor.app/Contents/Resources/app/bin` or `~/Applications/Cursor.app/Contents/Resources/app/bin` to `PATH` when either contains `cursor`.
3. **macOS:** when Homebrew is available and the cask is not installed, run:

```bash
brew install --cask cursor
```

1. **Linux and others:** install Cursor manually when you need the editor or CLI.

### Build the Cursor workspace launcher

1. **macOS only:** copy the launcher config template when you want the app bundle:

```bash
cp launcher/workspace-launcher.local.sh.example launcher/workspace-launcher.local.sh
```

1. Edit `launcher/workspace-launcher.local.sh` and set `WORKSPACE_ENTRIES`.
1. Run the launcher setup from the repository root:

```bash
zsh ./launcher/setup-cursor-workspace-launcher.sh
```

The automation skips this branch on non-macOS systems and when the local launcher config is absent.

### Install Zsh plugins

1. Leave `ZSH_PLUGINS_DIR` unset to use `~/.zsh/plugins`, or set it to another plugin directory.
2. Run the helper from the repository root:

```bash
bash ./tools/zsh/install-plugins.sh
```

The helper clones or updates `zsh-autosuggestions` and `zsh-syntax-highlighting`.

## Manual helper fallback

When `link.sh` cannot run but shell helpers are available, use the manual fallback helper:

```bash
bash ./tools/manual/manual-link-fallback.sh
```

Pass `--dotfiles-root <path>` to use a different checkout path. The helper performs the same link steps for home files, `config/`, and Cursor User settings.

## Verification

Run the same checks used by CI:

```bash
SKIP_TESTS_RUN=1 ./tools/smoke-check.sh
./tests/run.sh
```

Restart the shell or run `source ~/.zshrc` before checking interactive shell behavior.

## Status

> Last updated: 2026-05-15

All steps are traced to `link.sh`, `tools/lib/link-targets.sh`, and the optional helpers. Cursor runtime files under `~/.cursor` are intentionally outside this manual's projection steps.
