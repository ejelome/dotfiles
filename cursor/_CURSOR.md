# Cursor AI Entry Point

This file is a routing-only adapter for Codex, GPT, and Claude. The file has no executable authority and is not a Cursor runtime `.mdc` rule.

Tracked source: `cursor/_CURSOR.md` — Runtime path after `./link.sh`: `~/.cursor/_CURSOR.md`

Do not treat `~/.cursor/*` machine-local config as repository truth.

Bootstrap chain and mutation protocol: [AGENTS.md](../AGENTS.md) and [REPOSITORY.md §4](../REPOSITORY.md#4-mutation-protocol-and-ownership). Do not re-read files already read in the bootstrap chain.

If any file in the bootstrap chain has not been read, stop and list the missing files before continuing.

## Cursor entry points

- [~/.cursor/rules/auto.mdc](rules/auto.mdc)
- [~/.cursor/rules/shared.mdc](rules/shared.mdc)
- [~/.cursor/commands/commands.md](commands/commands.md)
- [~/.cursor/_tests/_core.md](_tests/_core.md)
- [~/.cursor/_tests/_settings.md](_tests/_settings.md)
- [~/.cursor/_tests/rules.md](_tests/rules.md)
- [~/.cursor/_tests/commands.md](_tests/commands.md)
- [~/.cursor/_tests/_functions.md](_tests/_functions.md)
- [~/.cursor/_tests/_mdc.md](_tests/_mdc.md)
- [~/.cursor/_tests/_tests.md](_tests/_tests.md)
