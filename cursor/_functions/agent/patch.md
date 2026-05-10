# /agent patch

Patch `REPOSITORY.md` in the current repository with repo-specific multi-agent mutation protocol and ownership rules.

## Trigger

**Slash:** `/agent patch`
**Signature:** `/agent patch [--force]`
**Prose dispatch:** `(agent patch [--force])` — for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** agent patch, patch repository, fill agent placeholders

## Steps

1. Resolve the repo root as the directory where the command runs.
2. Parse flags immediately after the route selector and before any positional arguments per [cursor/_core/command-argument.md](../../_core/command-argument.md). `--force` is supported only in that pre-positional slot. Unsupported or misplaced flags **ABORT** before any route mutation.
3. Verify `REPOSITORY.md` exists in the repo root. If absent, **ABORT**: `REPOSITORY.md` not found; run `/agent install` first.
4. Read `REPOSITORY.md` in full.
5. Locate all `<!-- TODO(agent): <description> -->` placeholders. If none are found, **ABORT**: no `<!-- TODO(agent): ... -->` placeholders found; `REPOSITORY.md` may already be patched or was not installed via `/agent install`.
6. For each placeholder, infer repo-specific content from the current repository context. For validation commands, only include a command path when that exact path exists in the target repo; do not copy validation commands from any other repository. When no eligible command is found, leave a bounded `<!-- TODO(agent): list repo-specific validation commands -->` placeholder. Use the `<description>` as the inference prompt. Display all inferred values. For placeholders that cannot be inferred, collect the values from the user before presenting the gate. When `--force` is supplied, compute `the candidate patch`, render the diff from `the candidate patch`, then present the same gate. Gate the write per `cursor/_core/command-argument.md`:

   ```cursor-gate
   gate-class: destructive
   proceed: overwrite REPOSITORY.md
   abort: cancel
   operand-format: REPOSITORY.md
   invalid-input: re-prompt
   re-prompt-template: Type "overwrite REPOSITORY.md" to confirm writing all inferred sections, or "cancel" to abort.
   ```

   If the user does not type the exact proceed token, stop without any change.
7. Replace each `<!-- TODO(agent): <description> -->` marker with the supplied repo-specific content. Do not edit any text outside placeholder blocks. When `--force` is supplied, apply `the candidate patch` without recomputation or re-read of source.
8. Write the updated `REPOSITORY.md`.
9. Validate scaffold-local patch state: confirm `REPOSITORY.md` still exists and no `<!-- TODO(agent): ... -->` markers remain.
10. Report each placeholder resolved and confirm no `<!-- TODO(agent): ... -->` markers remain.

## Notes

- **Placeholder standard:** Sections requiring repo-specific content are marked `<!-- TODO(agent): <description> -->`. Only these markers are replaced; all surrounding text is preserved exactly.
- **Idempotency:** Re-running patch on a `REPOSITORY.md` with no remaining placeholders aborts at step 4 rather than producing duplicate sections or overwriting custom content.
- **Parameters:** `--force` — optional pre-positional flag. Default target is `REPOSITORY.md` in the repo root.
- **Examples:** `/agent patch`, `/agent patch --force`.
- **Boundary:** Edits `REPOSITORY.md` only. Does not touch `CLAUDE.md`, `AGENTS.md`, `~/.cursor/`, or agent settings JSON.
- **Validation:** The patch workflow validates scaffold-local state only: `REPOSITORY.md` remains present and every `<!-- TODO(agent): ... -->` marker is resolved after the write.
- **Confirm-before-write:** `patch.md` is a confirm-before-write route; the confirmation step is mandatory and not optional for any placeholder. Gate contract: `cursor/_core/command-argument.md`.
- **Force flag:** `--force` is eligible only for the route's gated overwrite path. It does not bypass missing-file, idempotency, inference, validation, or permission failures.

```cursor-arg
dispatch: (agent patch [--force])
param: name=--force; required=optional; placeholder=--force; class=literal; values=present
```

```cursor-flag
flag: force
eligibility: eligible
guard-class: gated-overwrite
```
