# Cursor AI Entry Point

This file is a routing-only adapter for Codex, GPT, and Claude. The file has no executable authority and is not a Cursor runtime `.mdc` rule.

Tracked source: `cursor/_CURSOR.md` — Runtime path after `./link.sh`: `~/.cursor/_CURSOR.md`

Do not treat `~/.cursor/*` machine-local config as repository truth.

Bootstrap chain and mutation protocol: [AGENTS.md](../AGENTS.md) and [REPOSITORY.md §4](../REPOSITORY.md#4-mutation-protocol-and-ownership). Do not re-read files already read in the bootstrap chain.

Next: read `~/.cursor/commands/commands.md` to look up and invoke a slash command.

If any file in the bootstrap chain has not been read, stop and list the missing files before continuing.

## Resume contract

After `/compact`, `/clear`, an agent swap, or a subagent return, re-establish collab context before writing by running the machine-verifiable resume signal:

```
tools/collab/registry.py speak-state --resume <target> <role>
```

The helper reports active phase, turn order, reviewer state, contributors, last contributor, expected role, allowed roles, and ready-to-write status. Re-run it after every context-changing event — never trust prior helper output carried across that boundary.

Human-facing checklist (for inspecting state manually): read the bootstrap entry, the active registry entry, the transcript header, and the active route file; then re-run the route helper before writing.

## Context management

Each agent runs in an isolated instance with its own context window; the transcript file is the only shared state. `/compact` is local instance maintenance and does not affect other agents' context.

Safe lifecycle patterns for managing context across collab sessions:

- **After each Discussion contribution:** run `/compact` before issuing your next collab command. Audit and Discussion are captured in the transcript; per-turn compaction keeps the instance lean for the next command without losing any discovery record.
- **After each Handoff contribution:** run `/compact` before preparing the subagent. The Handoff deliverable shape (write scope, validation commands, subagent constraints) is not yet specified as structured state; it will be defined in a follow-on collab.
- **After close:** run `/clear` only at the `close → init` boundary, before starting a new collab. `/clear` is a full session reset — it is not appropriate inside an open collab.
- **On Completion:** spawn and use the subagent if prepared during Handoff; run `/compact` if not.
- **Subagents:** preparation occurs at Handoff (write scope, validation commands, spawn constraints); spawning occurs at Completion under `/collab run plan`. The parent agent declares write scope, reviews returned paths, runs validation, and records the result. Subagents are never turn authors and must not write to the registry or transcript independently.

**Authoritative collab lifecycle:**

> Audit (speak) → Discussion (speak) → `/compact` → Conclusion (speak) → Action Plan (speak) → Handoff (speak) → `/compact` → prepare subagent → Completion (execute) → use subagent → `/clear`
>
> `mod` exits after Discussion, then `/clear`. `pa` exits after Conclusion, then `/clear`. Their absence from subsequent phases is by design, not omission.

## Cursor entry points

- [~/.cursor/rules/auto.mdc](rules/auto.mdc)
- [~/.cursor/rules/shared.mdc](rules/shared.mdc)
- [~/.cursor/commands/commands.md](commands/commands.md)
- [~/.cursor/_core/agent-role.md](_core/agent-role.md)
- [~/.cursor/_generated/collab-lifecycle.md](_generated/collab-lifecycle.md)
- [~/.cursor/_generated/command-reference.md](_generated/command-reference.md)
- [~/.cursor/_tests/_core.md](_tests/_core.md)
- [~/.cursor/_tests/_roles.md](_tests/_roles.md)
- [~/.cursor/_tests/_generated.md](_tests/_generated.md)
- [~/.cursor/_tests/_settings.md](_tests/_settings.md)
- [~/.cursor/_tests/rules.md](_tests/rules.md)
- [~/.cursor/_tests/commands.md](_tests/commands.md)
- [~/.cursor/_tests/_functions.md](_tests/_functions.md)
- [~/.cursor/_tests/_mdc.md](_tests/_mdc.md)
- [~/.cursor/_tests/_templates.md](_tests/_templates.md)
- [~/.cursor/_tests/_tests.md](_tests/_tests.md)
