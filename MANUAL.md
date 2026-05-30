# Manual link fallback

Manual steps to reproduce `link.sh` when automation is unavailable.

---

**Table of contents**

- [Prerequisites](#prerequisites)
- [Link home files](#link-home-files)
- [Link Starship configs](#link-starship-configs)
- [Verification](#verification)

---

## Prerequisites

```sh
cp gitconfig.local.example ~/.gitconfig.local
cp zshrc.local.example ~/.zshrc.local
chmod 600 ~/.gitconfig.local ~/.zshrc.local
```

## Link home files

Set `<repo>` to the absolute path of this checkout. Back up any existing non-symlink destination to `<destination>.bak`, then:

| Source | Destination |
| --- | --- |
| `<repo>/zshrc` | `~/.zshrc` |
| `<repo>/gitconfig` | `~/.gitconfig` |

```sh
ln -sf <repo>/zshrc ~/.zshrc
ln -sf <repo>/gitconfig ~/.gitconfig
```

## Link Starship configs

```sh
mkdir -p ~/.config
ln -sf <repo>/config/starship.toml ~/.config/starship.toml
ln -sf <repo>/config/starship.dark.toml ~/.config/starship.dark.toml
ln -sf <repo>/config/starship.light.toml ~/.config/starship.light.toml
```

Back up any existing non-symlink `~/.config/<name>` to `~/.config/<name>.bak` first.

## Verification

```sh
readlink ~/.zshrc
readlink ~/.gitconfig
readlink ~/.config/starship.toml
readlink ~/.config/starship.dark.toml
readlink ~/.config/starship.light.toml
source ~/.zshrc
```

---

> Last updated: 2026-05-30
