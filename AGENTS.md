# Agent guide — dotfiles

Agents edit tracked source in this repository. Users apply the cursor tree to `~/.cursor` with [link.sh](link.sh).

Document contract: [cursor/_core/document.md](cursor/_core/document.md#agent-guide-agentsmd)

## Bootstrap chain

Each agent reads files in this order before acting:

- Codex: `AGENTS.md` → `cursor/_CURSOR.md`
- GPT: `AGENTS.md` → `cursor/_CURSOR.md`
- Claude: `CLAUDE.md` → `AGENTS.md` → `cursor/_CURSOR.md`

After reading this file, read [cursor/_CURSOR.md](cursor/_CURSOR.md).

## Contract assertion

Tracked source under `./cursor/` is authoritative. Files deployed to `~/.cursor/` and any project-local `.cursor/` are derived outputs (runtime mirrors). Agents must not treat runtime mirrors as source.

## Reading depth

Any file referenced under `~/.cursor/` or its repo source under `cursor/` must be read in full before answering. Follow every link in the chain to its deepest level:

- Router files (`commands/`) → function files (`_functions/<namespace>/<route>.md`)
- Rule stubs → full `.mdc` content

If any file in the chain cannot be reached or read, halt immediately and tell the user which file is missing before continuing.

## Agent profile

- Supported agents: Cursor Composer, GPT, Claude.
- Agent adapter files must be thin and routing-only; enforcement is handled by executable scripts, not adapter prose.

## Required workflow

1. Edit canonical files under `./cursor/` and repository scripts/docs only.
2. Validate source: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` and `./tests/run.sh`.
3. Validate runtime: `./link.sh` then `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.

## Entry points

- Repo↔runtime contract: [REPOSITORY.md](REPOSITORY.md)
- Cursor-tree: [cursor/_CURSOR.md](cursor/_CURSOR.md)
- Slash catalog: [cursor/commands/commands.md](cursor/commands/commands.md)
