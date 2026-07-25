# Manual link fallback

Use these steps to reproduce `link.sh` when the script cannot be run. Prefer
the script during normal setup because it applies the same source inventory
and backup behavior consistently.

## Requirements

- A local checkout of this repository.
- Permission to create symlinks in the home and `~/.config` directories.
- Zsh, Git, and Starship installed as described in
  [README.md](README.md#requirements).

## Prepare local overrides

```sh
cp gitconfig.local.example ~/.gitconfig.local
cp zshrc.local.example ~/.zshrc.local
chmod 600 ~/.gitconfig.local ~/.zshrc.local
```

Edit both local files before continuing. Keep identity, secrets, and
machine-specific exports outside the tracked checkout.

## Link home files

Set `<repo>` to the absolute path of this checkout. Before linking, move any
existing non-symlink destination to `<destination>.bak`.

| Source | Destination |
| --- | --- |
| `<repo>/zshrc` | `~/.zshrc` |
| `<repo>/gitconfig` | `~/.gitconfig` |

```sh
ln -sf <repo>/zshrc ~/.zshrc
ln -sf <repo>/gitconfig ~/.gitconfig
```

## Link Starship configuration

Create the configuration directory, then link the default and appearance
variants:

```sh
mkdir -p ~/.config
ln -sf <repo>/config/starship.toml ~/.config/starship.toml
ln -sf <repo>/config/starship.dark.toml ~/.config/starship.dark.toml
ln -sf <repo>/config/starship.light.toml ~/.config/starship.light.toml
```

Back up any existing non-symlink `~/.config/<name>` to
`~/.config/<name>.bak` first.

## Configure project hooks

Point this checkout at the tracked hook directory:

```sh
git -C <repo> config core.hooksPath .githooks
```

The pre-push hook validates the calendar-dated project record before sharing
changes.

## Verify the links

```sh
readlink ~/.zshrc
readlink ~/.gitconfig
readlink ~/.config/starship.toml
readlink ~/.config/starship.dark.toml
readlink ~/.config/starship.light.toml
source ~/.zshrc
```

Each `readlink` result should resolve to the matching source in `<repo>`.
Confirm the local overrides remain regular files with owner-only permissions:

```sh
ls -l ~/.gitconfig.local ~/.zshrc.local
```

Both local files should use mode `600`.
