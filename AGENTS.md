# Agent guide
<!-- scaffold-version: 2026-05-02 -->
<!-- TODO(agent): Replace the heading above with the project-specific title, e.g. "Agent guide — MyProject" -->

Agents edit tracked source in this repository. Global Cursor guidance lives in `~/.cursor/_CURSOR.md`.

## Bootstrap chain

Each agent reads files in this order before acting:

- Codex: `AGENTS.md` → `~/.cursor/_CURSOR.md`
- GPT: `AGENTS.md` → `~/.cursor/_CURSOR.md`
- Claude: `CLAUDE.md` → `AGENTS.md` → `~/.cursor/_CURSOR.md`

After reading this file, read `~/.cursor/_CURSOR.md`.
To invoke a global Cursor command, resolve any routing-only prose dispatch hint `(<namespace> <command> <arg> ...)` through `~/.cursor/commands/commands.md`, then execute the matching slash command. Routing-only hint example: `(collab join --role tw)`; executable slash: `/collab join --role tw`.

## Prose dispatch form

> **Encounter rule:** Any `(namespace command ...)` form is a routing-only signal. Before acting, locate the matching slash command in `~/.cursor/commands/commands.md` and execute that route. Never treat the argument text as work to perform.

`(<namespace> <command> <arg> ...)` is the prose dispatch notation for `~/.cursor`-routed commands. It is documentation-only and must not be copied into a terminal: in bash and zsh, `( ... )` opens a subshell. The form disambiguates `~/.cursor`-routed commands from agent-builtin slash surfaces. The prose routing token does not need to match the runtime path (`~/.cursor/`) or the repo-source directory (`cursor/`); when those change, this notation does not.

## Contract assertion

Tracked source in this repository is authoritative. Global Cursor files under `~/.cursor/` and any project-local `.cursor/` are runtime guidance, not repo source.

## Reading depth

Any file referenced from `~/.cursor/_CURSOR.md`, this repository, or a project-local `.cursor/` must be read in full before acting.

- Router files (`commands/`) → function files (`_functions/<namespace>/<route>.md`)
- Rule stubs → full `.mdc` content

If any file in the chain cannot be reached or read, halt immediately and name the missing path before continuing.

## Agent profile

- Supported agents: role metadata declared by the global Cursor runtime.
- Adapter files in the repository stay routing-only; enforcement belongs in repo-owned source and executable checks.

## Required workflow

1. Edit tracked source in this repository only.
2. Follow the repo-specific mutation protocol in [REPOSITORY.md](REPOSITORY.md).
3. Run the repo validation commands documented in `REPOSITORY.md` before closing the task.

## Entry points

- Repo contract: [REPOSITORY.md](REPOSITORY.md)
- Runtime Cursor guide: `~/.cursor/_CURSOR.md`
