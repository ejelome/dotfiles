# /commands

List every slash command under `cursor/commands/` by basename and purpose; use when you need the canonical name or invocation syntax for any installed command.

## Trigger

**Slash:** `/commands` **Phrases:** `cursor commands list`, `slash commands`, `what commands in cursor/commands`, `commands-index`

## Steps

1. Read this table when the user needs the canonical name for a playbook or the list of installed slashes.
2. Open the linked `*.md` source under `CURSOR_CONFIG_ROOT/commands/` for full behavior.

## Notes

Playbooks follow `{group}-{name}.md` per [style-guide](../core/style-guide.md). The catalog is **`commands.md`** with slash **`/commands`** by convention. Cursor exposes **`/<basename>`** without `.md`. Install targets live under **`~/.cursor/commands/`** via **`CURSOR_CONFIG_ROOT`**.

**Invocation notes by command:**

- **`/git-issue`** — requires subcommand **`create`** or **`implement`**; bare `/git-issue` is incomplete.
- **`/git-commit`** — atomic splits or squash `FROM..TO`; infers mode and asks once if stuck.
- **`/docs-assess`**, **`/docs-compare`**, **`/docs-compact`** — ask target or format once (Markdown only).
- **`/eval-tune`** — rubric-driven meta QA with approval-gated adaptation; may route to specialist commands.
- **`/eval-uid`** — `<image>` primary; optional `<project>` for vocabulary only. With attachment, trailing token is `<project>`; without attachment, first token is `<image>`, second optional is `<project>`; no image and no path → prompt to provide one.
- **`/eval-wse`** — `<project>` (defaults to workspace); non-game web default; Phaser repos use the non-game slice.
- **`/eval-igd`** — `<project>` (defaults to workspace); game engineering; Phaser when present, else game subtree.
- **`/eval-ops`** — `<project>` (defaults to workspace); build and operations scripts, Vite output and path checks, CI and deploy mechanics.

**Related principal workflows (`/eval-uid`, `/eval-wse`, `/eval-igd`, `/eval-ops`):**

| Slash | Source of truth | Cross-stack |
| --- | --- | --- |
| `/eval-uid` | `<image>` (+ optional `<project>` for vocabulary only) | — |
| `/eval-wse` | `<project>` — checked-in **web** tree | On **Phaser** repos: **non-game** aspects (host, build, shell, BFF, DOM outside canvas). |
| `/eval-igd` | `<project>` — **game** tree | On **non-Phaser** repos: **game** slice (loop, canvas, assets) only. |
| `/eval-ops` | `<project>` — checked-in **build/ops** tree | Owns `tools/`, Vite output/path correctness, and CI/deploy mechanics outside WSE/IGD/UID-owned surfaces. |

**Commands catalog:**

| Slash | Source | Purpose |
| --- | --- | --- |
| `/commands` | [commands](commands.md) | This catalog (all slash playbooks in `cursor/commands/`). |
| `/docs-readme` | [docs-readme](docs-readme.md) | Create or update repo `README*` or `readme*` files (no matching rule under `cursor/rules/`). |
| `/docs-manual` | [docs-manual](docs-manual.md) | Create or update repo-root `MANUAL.md` (script-traced fallback; no other paths). |
| `/docs-changelog` | [docs-changelog](docs-changelog.md) | Create or update changelog or release-note style files (paths in that playbook); supports mode shorthands like `/docs-changelog squash` and `/docs-changelog atomic`. |
| `/docs-assess` | [docs-assess](docs-assess.md) | Ask target (Markdown document), then classify and rewrite per **Markdown document route**. |
| `/docs-compare` | [docs-compare](docs-compare.md) | Ask format (Markdown), then provide a preservation/diff report for two markdown versions (no compact final). |
| `/docs-compact` | [docs-compact](docs-compact.md) | Ask format (Markdown), then compare-and-compact per **Markdown route**. |
| `/git-issue` | [git-issue](git-issue.md) | `/git-issue create` (prefill, four phases) or `/git-issue implement` (execution); bare `/git-issue` is incomplete—see playbook. |
| `/git-commit` | [git-commit](git-commit.md) | Atomic multi-commit or squash `FROM..TO`; infer when possible; ask once if stuck. |
| `/eval-tune` | [eval-tune](eval-tune.md) | Rubric-driven QA meta-orchestrator; can route to specialist workflows and uses approval-gated learning. |
| `/eval-uid` | [eval-uid](eval-uid.md) | Principal User Interface Designer (**UID**) — `<image>` primary; optional `<project>`; if an image is attached, first arg is `<project>` only. |
| `/eval-wse` | [eval-wse](eval-wse.md) | Principal Web Software Engineer (**WSE**) — `<project>` (defaults to workspace); web stack; **non-game** default; **Phaser** repos → host/build/shell slice. |
| `/eval-igd` | [eval-igd](eval-igd.md) | Principal Game Developer (**IGD**) — `<project>` (defaults to workspace); **game** engineering; **Phaser** when present; **non-Phaser** → game subtree; ship path. |
| `/eval-ops` | [eval-ops](eval-ops.md) | Principal Build and Operations Engineer (**OPS**) — `<project>` (defaults to workspace); `tools/` scripts, Vite build-output/asset-path correctness, and CI/deploy pipeline mechanics. |

Project onboarding files (for example **`AGENTS.md`** at the **application** repository root) are separate from this catalog; they describe the repo you are editing, not global **`~/.cursor`** config.
