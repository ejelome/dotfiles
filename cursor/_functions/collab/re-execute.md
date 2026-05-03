# /collab re-execute

Rewrite the calling role's last execution record in-place within the Completion section.

## Trigger

**Slash:** `/collab re-execute`
**Signature:** `/collab re-execute`
**Phrases:** collab re-execute, retry collaboration execution, redo last execute

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript path. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be re-executed.
4. Resolve the active phase from registry `activePhase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. If the active phase is not `Completion`, **ABORT**: `/collab re-execute` is valid only when registry `activePhase` is `Completion`.
6. Resolve the executing role from the registry participants list. Match the current agent to a registered participant. If no match, **ABORT**: role not registered; run `/collab join --role <role>` first.
7. Read `## Completion` and locate the role's last execution-history entry. If the last entry is already marked `completed`, **ABORT**: last execution already succeeded; nothing to retry.
8. If no execution-history entry exists for this role, **ABORT**: no prior execution record to rewrite; use `/collab execute` to begin execution.
9. Append the next numbered item to the execution history as `<n>. **<role>:** in progress YYYY-MM-DD HH:MM — re-execution started.`
10. Re-run the action-plan implementation: re-read `## Action Plan`, collect all unchecked role-scoped checklist items, and implement them.
11. Run the validation sequence: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.
12. On validation success: locate all execution-history lines belonging to the prior failed attempt — the `in progress` line and its subsequent `failed` line. Replace both with a single new success line: `<n>. **<role>:** completed YYYY-MM-DD HH:MM — validation passed.` Move the removed lines into a collapsed history block using the **Revision history shape** in **Notes**, placed immediately after the new success line. Remove the "in progress" line written in step 9 as well; it belongs in the history block. Do not leave any failure or stale in-progress line visible.
13. On validation failure: append `<n>. **<role>:** failed YYYY-MM-DD HH:MM — validation failed: <failed command>.` after the in-progress line written in step 9; leave all prior entries unchanged.
14. Check every completed role-scoped checklist item in `## Action Plan` as `[x]`.
15. Mirror execution state in the registry `execution` object, including validation result and touched paths.
16. After mirroring completed execution, evaluate the **Auto-close on completion** rule in `/collab execute` **Notes**. If every non-moderator assigned role has a completed execution entry, close the record.
17. Report all changed files and validation results. Stop.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `re-execute`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Rewrite semantics:** `/collab re-execute` rewrites the last execution record in-place rather than appending a parallel success alongside a visible failure. The Completion section shows only the final execution state; prior failure is preserved in a collapsed history block, not deleted.
- **Revision history shape:** Wrap the prior failed attempt (its `in progress` line and `failed` line, in original order) in `<details><summary>Revision history</summary>\n\nPrevious attempt, <in-progress-timestamp>:\n\n<in-progress-line>\n<failed-line>\n\n</details>` placed immediately after the new success line in the execution history. If a revision history block already exists at that position (from an earlier retry), prepend the new attempt block inside the existing wrapper rather than nesting a second wrapper.
- **Completion-only guard:** `/collab re-execute` must refuse all phases other than `Completion`.
- **Execution boundary:** This route implements only action-plan items assigned to the current role. Its only lifecycle side effect beyond implementation is the auto-close trigger when all assigned execution is complete.
