# Helper output

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab helper output, advisory line ordering, helper exit codes

## Steps

1. Read this document when auditing or changing collab helper output contracts.
2. Do not mutate registry or transcript state from this documentation-only reference.

## Notes

Defines the required output lines per collab helper command, advisory line ordering, and exit-code semantics. Authoritative for pe audits under item #5.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success or eligible; output is valid and the caller may proceed |
| 1 | Blocked, invalid input, or precondition failed; output names the reason |

Any command that exits non-zero must print a human-readable error message. Silent non-zero exits are a defect.

## Advisory line ordering

Advisory lines follow every successful mutating action. Order is fixed; consumers parse by prefix label, not line index.

| Position | Prefix | Required by |
|---|---|---|
| 1 | `NEXT:` | All mutating commands |
| 2 | `EFFORT:` | All mutating commands |
| 3 | `EFFICIENCY:` | Commands that cross a lifecycle boundary |
| 4 | `IDENTITY:` | `join` only |

`EFFICIENCY:` is suppressed when no lifecycle boundary is crossed in the action. `IDENTITY:` records the `agentId` captured at join time.

Advisory lines are suppressed on failed eligibility checks, duplicate contributions, or any gate failure. The output on failure shows only the blocker.

## Pre-write advisory lines (`speak-render`)

`speak-render` emits two pre-write advisory lines before appending content:

```
BOUNDARY: transcript write only; no shell commands or file edits outside .collabs/
SUCCINCTLY: stay within role concerns; do not pad or summarize other roles
```

These are not part of the post-write advisory sequence. They appear before any write and before any post-write advisory line.

## Required lines per command

### `join-participants`

Successful exit emits in order:

1. `NEXT: Run /collab show policy before first speak.`
2. `EFFORT: <phase> · <role> · <level> · <scale phrase>`
3. `IDENTITY: <agentId>`

### `speak-render`

Pre-write (before appending):

1. `BOUNDARY: transcript write only; no shell commands or file edits outside .collabs/`
2. `SUCCINCTLY: stay within role concerns; do not pad or summarize other roles`
3. `RETRACT: use /collab retract speak to tombstone the latest active-phase contribution`

Post-write (after successful append):

1. `NEXT: <imperative routing guidance>`
2. `EFFORT: <phase> · <role> · <level> · <scale phrase>`
3. `EFFICIENCY:` (only when action crosses a lifecycle boundary)
4. `appended`
5. `PHASE: <state>` by default, or `{"phaseState": "<state>"}` when `--json` is supplied

### `speak-lifecycle-live`

Emits lifecycle JSON: `{"phaseState": "<value>"}` where `<value>` is a phase name or `unchanged`.

### `speak-state`

Emits JSON object with fields: `activePhase`, `allowedRoles`, `expectedRole`, `contributors`, `lastContributor`, `readyToWrite`, `uncheckedAssignedItemsByRole`.

Exit 0 when the queried role is in `allowedRoles`. Exit 1 otherwise.

### `effort-state`

Emits: `EFFORT: <phase> · <role> · <level> · <scale phrase>`

Exit 0 always.

### `execute-spawn`

Exit 0 when the declared scope does not conflict with sibling scopes. Exit 1 with conflict message naming the overlapping paths.

## Defect definition

A command has a helper-output defect when any of the following is true:

- A required line is absent from successful output
- Advisory lines appear out of the fixed order
- Exit code does not match the semantic table above
- A pre-write advisory line appears after a post-write advisory line
- A suppressed line appears on a failed-gate output
