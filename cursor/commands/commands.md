# Catalog: Cursor slash commands from this repository

This file is the **single checklist** of user slash commands defined in [cursor/commands/](.).
Each `*.md` here is symlinked to `~/.cursor/commands/` by [link.sh](../../link.sh).
Cursor exposes the command as `/<name>` where `<name>` is the filename without `.md`.

**When to use this playbook:** Use it for a quick map from `/slash-name` to source file and one-line purpose, or when deciding which command to run next.

**Naming:** Short names `/readme`, `/changelog`, `/issue`.
Git: `/commit` (atomic splits vs squash range; infer when possible, ask once if stuck).
Routers (format or target asked once; Markdown only for now): `/compare-compact`, `/assess`.
Meta: `/commands` (this catalog).

## Commands

| Slash | Source | Purpose |
| --- | --- | --- |
| **`/commands`** | [`commands.md`](commands.md) | This catalog (all slash playbooks in `cursor/commands/`). |
| **`/readme`** | [`readme.md`](readme.md) | Create or update repo `README*` / `readme*` files (no matching rule under `cursor/rules/`). |
| **`/changelog`** | [`changelog.md`](changelog.md) | Create or update changelog / release-note style files (paths in that playbook). |
| **`/assess`** | [`assess.md`](assess.md) | Ask target (Markdown document only for now), then classify and rewrite per **Markdown document route**. |
| **`/compare-compact`** | [`compare-compact.md`](compare-compact.md) | Ask format (Markdown only for now), then compare-and-compact per **Markdown route**. |
| **`/issue`** | [`issue.md`](issue.md) | Issue prefill (four phases) or implementation; route once if create vs implement is unclear. |
| **`/commit`** | [`commit.md`](commit.md) | Atomic multi-commit or squash `FROM..TO`; infer when possible; see [commit.md](commit.md). |

Repository agent on-ramp: [AGENTS.md](../../AGENTS.md).

## Trigger phrases

**Slash:** `/commands` **Phrases:** `cursor commands list`, `slash commands`, `what commands in cursor/commands`, `atomic commits`, `squash commits`, `commands-index` (old name)
