# Agent context

On-ramp for coding agents in this repository.

## Where to start

1. **Install and symlinks:** [README](README.md) and [link.sh](link.sh)
2. **Recovery and manual steps:** [MANUAL](MANUAL.md)
3. **Cursor rules:** `cursor/rules/*.mdc` → `~/.cursor/rules` via [link.sh](link.sh).
4. **Cursor skills:** `cursor/skills-cursor/`; linked to `~/.cursor/skills-cursor` by `link.sh`
5. **Slash commands:** `cursor/commands/*.md` linked to `~/.cursor/commands` by `link.sh`
6. **Cursor extensions:** [extensions.txt](cursor/extensions.txt); install with [ext.sh](scripts/ext.sh) (not symlinked)
7. **Short slashes:** `/readme`, `/changelog`, `/issue` (create and implement in one playbook)
8. **Git:** `/commit` — [commit](cursor/commands/commit.md) (atomic splits, squash `FROM`/`TO`, infer, ask once if stuck)
9. **Routers:** `/assess` and `/compare-compact` ask for target or format once (Markdown-only for now)
10. **README handler:** [readme](cursor/commands/readme.md)
11. **Changelog handler:** [changelog](cursor/commands/changelog.md)
12. **Rule overlap:** No matching README or changelog rules under `cursor/rules/`
13. **Catalog:** [commands](cursor/commands/commands.md) lists all slash playbooks here (`/commands`)
14. **Issues:** `/issue` is the only issue slash (prefill or implementation; route when ambiguous)
15. **Rules file:** No `.cursorrules`. Use `cursor/rules/*.mdc`; [link.sh](link.sh) symlinks that tree to `~/.cursor/rules`.

## Edit in the repo

- Change tracked files here, not symlink targets under `$HOME` (see README **Conventions**)
- Keep **flat Cursor trees:** `cursor/rules/` should contain only `*.mdc` files
- Keep `cursor/skills-cursor/` and `cursor/commands/` one level deep (skill dirs and playbook `*.md` only)
- Never nest `cursor/rules/rules/`, `cursor/skills-cursor/skills-cursor/`, or `cursor/commands/commands`
- Nested mirror paths are a recursive symlink hazard
- [link.sh](link.sh) exits if those paths exist
- See [MANUAL](MANUAL.md) (**Cursor rules link**, **Cursor skills link**, **Cursor commands link**) for recovery
- **Cursor plan mode:** direct patches to `cursor/rules/*.mdc` are often blocked (only Markdown is writable)
- Use **Agent** mode for `.mdc` edits, or apply changes via the shell and commit when plan mode blocks edits

## Cursor Settings (avoid duplicate context)

- Do not repeat long always-on policy from `~/.cursor/rules` inside Cursor Settings (**Rules for AI**)
- Call out `auto-cursor.mdc` and `shared-precedence.mdc` as examples not to duplicate
- Prefer application-repo on-ramps (for example root [AGENTS](AGENTS.md))
- Prefer optional rule mentions instead of copying the same guidance into User Rules

## History

[CHANGELOG](CHANGELOG.md)
