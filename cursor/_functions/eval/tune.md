# /eval tune

Run a named specialist evaluation command on a target, then audit cross-cutting **Criteria** and apply rubric learning via [shared-cmd-eval.mdc](../../_mdc/shared/shared-cmd-eval.mdc).

## Trigger

**Slash:** `/eval tune`
**Signature:** `/eval tune <uid | wse | igd | ops>`
**Phrases:** tune, rubric tune, eval with learning (slash preferred).

## Steps

1. Resolve `<eval-command>` from the first argument after the slash; must be one of `wse`, `igd`, `uid`, or `ops`. If missing or invalid, **ABORT** with the token received.
2. **Route — non-UID:** When `<eval-command>` is one of `wse`, `igd`, or `ops`, resolve `<project>` from the next positional argument or attachment per that specialist playbook. If missing, **ABORT**: `<project>` is required.
3. **Route — UID:** When `<eval-command>` is `uid`, resolve `<image>` and `<project>` from remaining tokens and attachments using the same order as **`/eval uid`** **Parameters** in [uid](uid.md). If either is missing after resolution, **ABORT** naming the missing argument.
4. Read this file and [shared-cmd-eval.mdc](../../_mdc/shared/shared-cmd-eval.mdc). If either is not directly readable, **ABORT** per **`auto-context-gate.mdc`**.
5. Run the resolved specialist playbook (`_functions/eval/<eval-command>.md`) through its **Steps** in full, passing the resolved arguments.
6. After the specialist review, audit against **Criteria** in **Notes**. For each finding record path (and line when applicable), severity `critical` | `major` | `minor` | `info`, description, and fix. Group by severity then category.
7. List gaps that are universal (actionable across projects, not already in the specialist rubric) versus project-only notes.
8. If the user used a no-learn phrase (`no-learn`, `static`, `one-off`, `do not adapt`), stop here.
9. Ask once whether to append findings to [notes.md](notes.md). On confirmation: append under `## QA audit — YYYY-MM-DD`; counter-suffix if the same date heading exists. Never replace; append only.
10. For universal gaps, present proposed criteria and run [shared-cmd-eval.mdc](../../_mdc/shared/shared-cmd-eval.mdc) **Protocol** steps 2–6. Do not edit any playbook until the gate completes and the user confirms.
11. On explicit confirmation, append accepted criteria bullets to the **Criteria** block in **Notes** below. Change no other section.

## Notes

- **Route (uid vs non-uid).** Non-UID (`wse`, `igd`, `ops`): next positional arg is `<project>` (specialist root path). UID (`uid`): next args are `<image>` then `<project>` per **`/eval uid`** **Parameters**.
- **Parameters:** `<eval-command>` — one of `wse`, `igd`, `ops`, or `uid` (required). **Non-UID route:** `<project>` — specialist root path (required); same meaning as in **`/eval wse`**, **`/eval igd`**, or **`/eval ops`**. **UID route:** `<image>` and `<project>` — screenshot or image path and vocabulary project root (both required); resolution matches **`/eval uid`**.
- **No-learn mode:** `no-learn`, `static`, `one-off`, or `do not adapt` ends the run after step **8**; skips steps **9–11** (no `notes.md` prompt, no **Protocol** proposal pass, no rubric append).
- **Response order:** Specialist findings first; cross-cutting Criteria audit next; adaptation candidates last.
- **Learning:** At most 2 accepted adaptation candidates applied per run; remaining deferred to next run per [shared-cmd-eval.mdc](../../_mdc/shared/shared-cmd-eval.mdc) batch cap.
- **QA notes:** [notes.md](notes.md) is the durable append-only log for user-approved QA learning notes. Do not create a second notes file. If the file is missing when notes are approved, **ABORT** and restore the repository contract before appending.
- **Criteria (audit every item after specialist pass).** Default severities: critical for security or data-loss risks, major for correctness or maintainability breaks, minor or info otherwise.
- **Code quality.** Remove or flag dead exported symbols. Flag cyclomatic complexity roughly above ten, functions longer than roughly eighty lines, or nesting roughly five levels deep. Replace unexplained magic literals with named constants or config. Keep naming conventions consistent within a layer.
- **Testing.** Require automated tests for non-trivial code; do not ship disabled suites as the only coverage. Assert observable behavior, not private implementation. Stabilize async and time-dependent tests. Cover critical paths such as auth, payments, and data mutation.
- **Security.** Never commit secrets. Validate environment variables before use. Never build SQL or shell commands from unchecked string interpolation. Track and fix high-severity dependency advisories. Configure CSP, CORS, and rate limiting on public HTTP surfaces when applicable.
- **Performance.** Flag N+1 database or API query patterns. Paginate or bound large lists. Move expensive synchronous work off hot render paths. Split or lazy-load large client bundles when relevant.
- **Documentation and developer experience.** Keep README install and run instructions current. Document public APIs. Record breaking changes in a changelog or equivalent. Enforce consistent lint and format configuration. Use clear ordered steps in command and role docs.
- **CI and repository hygiene.** Run tests on pull requests. Commit lockfiles. Exclude generated artifacts from version control. Protect the default branch with review or policy appropriate to the project.
