# Agent guide — dotfiles

Agents edit tracked sources in this repository to maintain shell, Git, and Cursor config; users apply them with [link.sh](link.sh) into `$HOME` and `~/.cursor`.

## Behavior

1. Read [README](README.md) and [link.sh](link.sh) for install layout and symlink behavior.
2. Read [MANUAL](MANUAL.md) for recovery when automation fails.
3. Treat Cursor runtime paths as **`~/.cursor/rules`**, **`~/.cursor/commands`**, **`~/.cursor/core`**, **`~/.cursor/extensions.txt`**; [link.sh](link.sh) symlinks each from **`CURSOR_CONFIG_ROOT`** when the matching source exists (default **`./cursor`** in this clone supplies all four). `~/.cursor/skills-cursor` is managed by Cursor itself and is not tracked in this repo.
4. Set **`CURSOR_CONFIG_ROOT`** to an absolute path when Cursor config must not move with the dotfiles clone path.
5. Change files under **`cursor/`** in this repository, not files under **`$HOME/.cursor`** that resolve as symlinks.
6. Omit manual **Table of contents** blocks under **`cursor/commands/`**; follow [cursor/README](cursor/README.md).
7. Use [install-extensions.sh](tools/cursor-cli/install-extensions.sh) and [clear-chat.sh](tools/cursor-cli/clear-chat.sh) from **`tools/cursor-cli/`** for CLI helpers; tracked **`zshrc`** prepends that directory to **`PATH`** when **`~/.zshrc`** resolves into this checkout.
8. Use [commands](cursor/commands/commands.md) as the slash index; principal entries include **`/git-commit`**, **`/git-issue`**, **`/docs-readme`**, **`/docs-manual`**, **`/docs-changelog`**, **`/docs-assess`**, **`/docs-compare`**, **`/docs-compact`**, **`/eval-tune`**, **`/eval-uid`**, **`/eval-wse`**, **`/eval-igd`**, **`/eval-ops`**.
9. When documentation or Markdown-router workflows apply, open the matching playbook: [docs-readme](cursor/commands/docs-readme.md), [docs-manual](cursor/commands/docs-manual.md), [docs-changelog](cursor/commands/docs-changelog.md), [docs-assess](cursor/commands/docs-assess.md), [docs-compare](cursor/commands/docs-compare.md), [docs-compact](cursor/commands/docs-compact.md).
10. When git workflows apply, open [git-issue](cursor/commands/git-issue.md) or [git-commit](cursor/commands/git-commit.md).
11. When eval QA workflows apply, open [eval-tune](cursor/commands/eval-tune.md), [eval-uid](cursor/commands/eval-uid.md), [eval-wse](cursor/commands/eval-wse.md), [eval-igd](cursor/commands/eval-igd.md), or [eval-ops](cursor/commands/eval-ops.md).
12. Remember there is no `.cursorrules` file; rule sources live under **`cursor/rules/*.mdc`** (→ **`~/.cursor/rules`** after link).

## Boundaries

- Do not edit real files under **`$HOME`** that are symlink destinations from this repo; edit the tracked source and re-run [link.sh](link.sh) when needed.
- Do not create **`rules/rules`**, **`commands/commands`**, or **`core/core`** under **`CURSOR_CONFIG_ROOT`**; nested mirror directories break [link.sh](link.sh) and tooling.
- Expect **Cursor plan mode** to block direct edits to **`cursor/rules/*.mdc`** sometimes; use **Agent** mode or apply patches from the shell when plan mode blocks.
- Do not duplicate long always-on rule text inside Cursor **Settings → Rules for AI**; reference installed rules instead.

## Available tools

| Tool | Type | Purpose |
| --- | --- | --- |
| [link.sh](link.sh) | script | Symlink dotfiles and Cursor config into `$HOME` / `~/.cursor` |
| [tools/smoke-check.sh](tools/smoke-check.sh) | script | Validate shell syntax, Cursor tree layout, commands catalog, nested-mirror guards (`skills-cursor/` is not checked) |
| [install-extensions.sh](tools/cursor-cli/install-extensions.sh) | script | Install Cursor extensions from `~/.cursor/extensions.txt` |
| [clear-chat.sh](tools/cursor-cli/clear-chat.sh) | script | Clear Cursor chat history (local helper) |
| [README](README.md) | doc | Install, structure, conventions |
| [MANUAL](MANUAL.md) | doc | Recovery and manual relink steps |
| [commands](cursor/commands/commands.md) | doc | Slash playbook catalog |

## Further reading

- [CHANGELOG](CHANGELOG.md)
- [cursor/README](cursor/README.md)
- [style-guide](cursor/core/style-guide.md)
- [document-standard](cursor/core/document-standard.md)
