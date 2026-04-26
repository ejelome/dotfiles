# /docs readme

Create or update `README*` and `readme*` files using verified workspace facts, `shared-docs-toc.mdc`, `shared-docs-precedence.mdc`, and `auto-docs-markdown.mdc` (README tone and repository layout tree defer to this command on those paths).

## Trigger

**Slash:** `/docs readme`
**Signature:** `/docs readme`
**Phrases:** `update readme`, `create readme`, `readme-write`

## Steps

1. Confirm target path(s) match **`**/README*`** and **`**/readme*`**. If multiple match and the user did not name one, **ask once**. Treat each README as independent unless the user scopes a monorepo package.
2. If **`shared-docs-toc.mdc`**, **`shared-docs-precedence.mdc`**, or **`auto-docs-markdown.mdc`** is missing from context when needed, **ABORT** per **`auto-context-gate.mdc`**.
3. Choose **Create** (no file or new package readme) or **Update** (file exists). Default **Update** when unsure; preserve structure unless the user wants a rewrite.

   On **Create**, if the user did not request a custom outline and the working tree matches this workspace’s **symlink + Cursor** profile (root **`link.sh`**, tracked **`cursor/`**, usually **`tools/smoke-check.sh`**, **`.github/workflows/`**), use the canonical default template in [Notes — Default README (this shape)](#default-readme-this-shape). Substitute only workspace-verified names, paths, URLs, and commands — never invent install steps or CI URLs. Do not change headings or section order.
4. Discover in order for orientation (not precedence when facts conflict):
   - **`package.json`** or equivalent if present
   - runnable entry files and obvious **`src/`** roots
   - configs the app loads
   - **`.github/workflows/*`** or equivalent CI
   - **`Makefile`**, **`justfile`**, **`link.sh`**, or similar ops entrypoints
   - the target README last

   When install behavior lives in ops scripts, prioritize those after or instead of manifest-only hints. Cap first-pass reads at six files or two directory levels unless the user names a subsystem; **ask once** when monorepo boundaries stay unclear.
5. When sources disagree on how to run the product, trust runnable code and scripts people use, then CI for the same artifact, then manifest metadata if it matches, then prior README prose last for behavior claims.
6. Include only sections the workspace verifies. Baseline sections:

   - name
   - description
   - optional badges and visuals
   - installation or setup
   - usage
   - support
   - roadmap
   - contributing
   - status

   Do not add empty headings.
7. **Always include:** **Title (H1)**; **Brief description** (≤80 characters if one line; two short sentences allowed; no “this repo” / “here” except the narrow symlink-first config exception below; move mechanics to **Install** / **Setup** / **Usage**); **Install** or **Setup** (prefer **Install**; use **Setup** when there is no install step); **Usage**; **Status** (see **Notes**).

   **Include when verified:** **Badges** when CI/CD config exists; **Screenshot or Demo** when a reader-visible UI exists and an asset or URL is verified; **Structure** or **Repository layout** when a short map helps; **Prerequisites** when non-obvious; **Configuration**, **Scripts or Commands**, **Deployment**, **Known issues**, **Roadmap**, **Contributing**, **Support**, **Asset credits**, **Architecture/Conventions** only with evidence.
8. **Repository layout tree:** At each level list subdirectories first (A–Z), then files (A–Z); ASCII order so dotfiles sort before letters; recurse the same rule; keep optional trailing `#` comments concrete.
9. **Manual TOC:** Required for the repository root **`README.md`** in this workspace. Wrap the TOC block with `---` immediately before the `**Table of contents**` label and immediately after the final TOC entry. For other README paths, the TOC is optional unless requested or already present. When a TOC is present, follow **`shared-docs-toc.mdc`**: list every `##`, `###`, and deeper subsection in order (or label-only when no such headings).
10. **Changelog:** Do not create or edit **`CHANGELOG.md`** (or other changelog paths) unless the user or same task explicitly includes them—then use **`/docs changelog`**.
11. **MANUAL:** Do not create or edit repo-root **`MANUAL.md`** unless the repo has **Automated setup** (root **`link.sh`**, **`install.sh`**, **`bootstrap.sh`**, **`setup.sh`**, or **`Makefile`/`justfile`** targets clearly used for install/bootstrap) **and** the user or task explicitly includes **`MANUAL.md`**. Otherwise treat **`MANUAL.md`** as out of scope here; use **`/docs manual`** in a separate invocation when needed.
12. **Symlink-first config repos:** When the main deliverable is config installed into **`~`** or editor dirs via a named installer, the opening line may name platforms, what is managed, and the installer plus symlink targets in one short sentence within the ≤80-character cap even if **Install** repeats the script; **“here”** is allowed only in that narrow case.
13. **Tone:** Present tense; second person or neutral for body; sentence-case headings; short sentences; lists for steps; language-tagged fences; placeholders explicit; plain Markdown without extra decorative rules; emoji only if the project already uses them.
14. **Environment variables and paths** in README body use single backticks, not bold-wrapped code.
15. Before finishing, verify each of the following. Required sections are present and the brief-description limit is met. **Install**/**Setup** and **Usage** are concrete or honestly delegated. **Status** matches the chosen shape and date rule in **Notes**. No commands are invented. Badges appear only when CI config exists. The screenshot rule is satisfied or honestly omitted. The repository root **`README.md`** has a synced TOC wrapped with `---`; TOCs in other README files are synced when present. **Description standards**, **`shared-docs-toc.mdc`**, and **`shared-docs-precedence.mdc`** are respected.

## Notes

### Description standards

- **Package registry summary:** Prefer 50-100 characters when package metadata is in scope.
- **README opening paragraph:** Prefer one sentence; use two short sentences only when needed.
- **GitHub repository description:** GitHub allows 350 characters, but prefer fewer than 120.
- **Avoid:** long mission statements, implementation details, setup instructions, and marketing fluff.

### Default README (this shape)

When [step 3](#steps) matches, produce `README.md` verbatim in shape—swap only workspace-verified values (`OWNER/REPO/WORKFLOW`, `git clone` URL, `cd` name, local `.example` copy lines, **Structure** bullets, **Links** list, CI sentences, `YYYY-MM-DD`). Do not change headings or section order. Omit the screenshot line only when no asset exists and the user confirms.

````
# dotfiles

![Smoke check](https://github.com/OWNER/REPO/actions/workflows/WORKFLOW.yml/badge.svg)

Dotfiles for shell, Git, Cursor, and local development workflows.

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

This repository is the source of truth for shell, Git, and Cursor settings. Clone it, then run `./link.sh` to create local symlinks. Re-run `./link.sh` after pulling or editing tracked files to keep symlinks current. The Cursor tree (`AGENTS.md`, `cursor/_core/`, slash commands) guides editors and tools. [REPOSITORY.md](REPOSITORY.md) defines the authoritative repo-runtime contract.

## Setup

1. `git clone https://github.com/OWNER/REPO.git`
2. `cd REPO`
3. `brew bundle`
4. `cp gitconfig.local.example ~/.gitconfig.local && cp zshrc.local.example ~/.zshrc.local && chmod 600 ~/.gitconfig.local ~/.zshrc.local`
5. `./link.sh`
6. `./link.sh --install-zsh-plugins` (optional Zsh plugin bootstrap)

## Usage

Re-run `./link.sh` after pulling, switching branches, or editing tracked config so `~` and Cursor user paths reflect the repository.

If the Cursor config is outside `./cursor`, set `CURSOR_CONFIG_ROOT` or pass `--cursor-config-root` / `--cursor-config-root=<path>` to `./link.sh`. See `./link.sh --help` for the full option list.

Before pushing or after changing paths that the checks enforce, run:

```bash
SKIP_TESTS_RUN=1 ./tools/smoke-check.sh
./tests/run.sh
```

## Structure

- `.github/` — CI workflows for smoke checks and shell tests on Ubuntu and macOS
- `config/` — Starship shared configuration
- `cursor/` — Cursor rules, commands, and config tree; default `CURSOR_CONFIG_ROOT` for `link.sh`
- `launcher/` — Cursor workspace launcher setup scripts
- `tests/` — shell regression suite
- `tools/` — smoke check, link helpers, agent checks, and `cursor-cli` scripts
- `link.sh` — entry point for projecting this tree into `~` and Cursor user paths

## Links

- [REPOSITORY.md](REPOSITORY.md)
- [AGENTS.md](AGENTS.md)
- [MANUAL.md](MANUAL.md)
- [cursor/_CURSOR.md](cursor/_CURSOR.md)
- [cursor/commands/commands.md](cursor/commands/commands.md)
- [CHANGELOG.md](CHANGELOG.md)

## Status

> Last updated: YYYY-MM-DD

CI runs smoke checks and shell tests on Ubuntu and macOS. `link.sh` is the supported way to project this repository’s shell and Cursor configuration.

See [CHANGELOG.md](CHANGELOG.md) for full history.
````

- **Merging with `document.md` (Readme):** The [document standard](../../_core/document.md) Readme skeleton maps to this route as: *What the project does* → **Overview**; *Further reading* → **Links**. Add badge, screenshot, and `**Table of contents**` lead-in before the first `##` when verified. In the repository root **`README.md`**, the TOC is required and must be wrapped with `---` before and after the TOC block. Full section order (omit any block you do not need, do not reorder blocks you keep): brief and optional badge; **optional** verified screenshot or other image right after the opening line and before the first `##` or *Table of contents*; required root README `**Table of contents**` listing every `##` in order; then **Overview** → **Setup** → **Usage** → **Structure** → **Links** → **Status** (always last).
- **Status — default shape:**

```markdown
## Status

> Last updated: YYYY-MM-DD

What works now and what is in progress (two sentences max).

See CHANGELOG.md for full history.
```

- **Status — alternate shape:** No rolling date line; single pointer to CHANGELOG.md; no duplicate changelog sentences.

```markdown
## Status

No rolling "last updated" line here (manual upkeep only); chronological history: CHANGELOG.md.

What works now and what is in progress (two sentences max).
```

- **Date sourcing (default shape only):** Never guess **`YYYY-MM-DD`**. Prefer `date +%F` in the workspace; otherwise use a user-stated calendar date for the edit; if neither, ask once. Update the date when **Status** meaning changes; keep it for mechanical typo-only edits unless status text changes.
- **README ↔ MANUAL:** When **Automated setup** exists and the user names both README and **`MANUAL.md`**, finish README first if it gives context, then run **`/docs manual`** separately for **`MANUAL.md`**.
- **Compliance:** No changelog edits out of scope; claims map to files read; TOC anchors match slugs per **`shared-docs-toc.mdc`** when a TOC is used.
