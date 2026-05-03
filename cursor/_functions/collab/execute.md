# /collab execute

Implement the action-plan items assigned to the executing agent's role in a collaboration record.

## Trigger

**Slash:** `/collab execute`
**Signature:** `/collab execute`
**Phrases:** collab execute, execute collaboration tasks, run collab action plan

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the resolved transcript. If either is unreadable, **ABORT**: record unreadable; name the path.
3. If the registry status is `closed` or `archived`, **ABORT**: closed collaboration records cannot be executed.
4. Resolve the active phase from registry `activePhase`. If missing or unknown, **ABORT**: active phase missing in metadata.
5. If the active phase is not `Completion`, **ABORT**: `/collab execute` is valid only when registry `activePhase` is `Completion`.
6. Resolve the executing role from the registry participants list. Match the current agent to a registered participant. If no match, **ABORT**: role not registered; run `/collab join --role <role>` first.
7. Read `## Action Plan`. Collect all unchecked checklist items whose label begins with `**<role>:**` matching the resolved role. If none found, report that no assigned items remain and stop.
8. If an execution-history item matching `**<role>:** completed` already exists, report that the role's execution is already complete and stop.
9. For each collected item, check `## Handoff` for a corresponding entry containing `_requires: #N_` or `_requires: #N #M_`. Parse every required item number listed in that field. If a required item number is found, verify its checkbox in `## Action Plan` is checked (`[x]`). If any required item is unchecked, **ABORT** before any file write with a structured message: executing role, blocked item number, required item number(s), and required item state (`unchecked`). This is the "perform or halt" contract: execution either runs or aborts with a concrete reason — never partial.
10. Ensure `## Completion` contains `**Execution history**`, then append the next numbered item as `<n>. **<role>:** in progress YYYY-MM-DD HH:MM — execution started.`.
11. Implement each collected action-plan item in source, in the order listed.
12. Run the validation sequence: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh` → `./tests/run.sh` → `./link.sh` → `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.
13. Check every completed role-scoped checklist item in `## Action Plan` as `[x]` before reporting success.
14. Mirror execution state in the registry `execution` object for the resolved collab, including validation result and touched paths when available.
15. After mirroring completed execution, evaluate the **Auto-close on completion** rule in **Notes**. If every non-moderator assigned role has a completed execution entry, update the registry status to `closed`, clear `activeCollabId` when it points at this collab, update the transcript Status cell to `closed`, and generate the default close summary under `## Completion`.
16. Append the next numbered item as `<n>. **<role>:** completed YYYY-MM-DD HH:MM — validation passed.` after validation passes. If validation fails, append `<n>. **<role>:** failed YYYY-MM-DD HH:MM — validation failed: <failed command>.` before reporting.
17. Report all changed files and validation results. Stop.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `execute`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Completion-only guard:** `/collab execute` must refuse `Audit`, `Discussion`, `Conclusion`, `Action Plan`, and `Handoff`.
- **Item scoping:** Execute selects only checklist items whose label begins with `**<role>:**` matching the executing role. Items labeled for other roles are skipped without modification.
- **Dependency parsing:** A handoff `requires` field may list one or more action-plan item numbers separated by spaces, such as `_requires: #1 #2 #3, next: ..._`. Treat every listed number as required.
- **Malformed items:** Treat unchecked checklist items without a `**<role>:**` label as out of scope unless a future route spec defines another assignment form.
- **Auto-close on completion:** `/collab execute` owns the completion close trigger because it owns `execution.<role>`. Close only when every non-moderator assigned role has a completed execution entry; failed or missing entries leave the record open.
- **Re-execute:** To rewrite the last execution record in-place, use `/collab re-execute`. See [_functions/collab/re-execute](re-execute.md).
- **Execution boundary:** This route implements only action-plan items assigned to the current role. Its only lifecycle side effect beyond implementation is the auto-close trigger when all assigned execution is complete. Use `tools/collab/registry.py write-guard <route> <path>...` as the shared helper boundary: non-`execute` collab routes may write only under `.collabs/`, while `execute` records role, status, validation result, and touched paths in execution history and registry execution metadata.
