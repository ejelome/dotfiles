# /collab policy

Document the gate policy that decides when a collaboration needs a reviewer judgment pass, and list available roles.

## Trigger

**Slash:** `/collab policy`
**Signature:** `/collab policy`
**Phrases:** collab gate policy, reviewer, gate-blocked state, available roles

## Steps

1. Read this policy when a collab needs judgment without depending on a specific participant being present.
2. Treat the trigger set as role-agnostic conditions that can fire in any collab.
3. Resolve the reviewer from registry `reviewerRole` when set; otherwise apply the **Reviewer fallback** in **Notes**.
4. If a trigger fires and no safe assignee exists, pause the collab as gate-blocked instead of advancing.
5. Do not mutate registry state from this documentation-only route.
6. To list available roles, call `tools/collab/registry.py roles` from the repository root. This reads every file under `cursor/_roles/` and outputs one participant-row per role.

## Notes

- **Parameters:** no arguments are accepted.
- **Documentation-only status:** This route documents policy and lists roles. It does not mutate registry state. No machine-readable registry field exists for gate assignment in this version. The future field name is `reviewer`.
- **Gate policy:** A gate policy separates durable trigger conditions from the role assigned to close the gate.
- **Gate triggers:** Any one condition fires the gate: all non-reviewer, non-moderator participants complete one full exchange without convergence; those participants converge but change Audit framing; the direction creates notable cost, migration, or maintenance risk not present in Audit; the moderator explicitly requests a judgment pass.
- **Reviewer:** Set the reviewer at collab initialization or roster setup using `/collab set reviewer <role>`. Do not reassign mid-collab.
- **Reviewer fallback:** When no `reviewerRole` is set, assign implementation-risk triggers to the participant with the closest implementation concerns, coherence or documentation-source triggers to the participant with the closest documentation concerns, and moderator-judgment triggers to the moderator only as a last resort before escalation.
- **Assignment timing:** Set reviewer once at initialization or initial roster setup. Do not reassign mid-collab.
- **Gate-blocked state:** Gate-blocked means a trigger fired but no current participant can safely own the gate. Gate-blocked is a non-error pause that prevents phase advancement until a safe reviewer joins or the moderator explicitly records an accepted-risk override.
- **Phase presence:** When reviewer is set via `reviewerRole`, the lifecycle enforces: reviewer speaks once, last, in convergent phases (`Audit`, `Conclusion`); reviewer may speak in `Discussion` when the optional-phases list includes it; reviewer stays silent in `Action Plan`, `Handoff`, and `Completion` unless a re-Audit signal fires.
- **Role catalog:** `tools/collab/registry.py roles` is the authoritative source for available roles. No role key is hard-coded in this policy.

## Provenance

`Audit` phase citations supplied by the moderator must be durable references accessible from the repository:

- Prefer repo-relative paths checked into the repository.
- When an external document is required, copy it to `.collabs/inputs/<filename>` before the collab opens and cite that path.
- Transient local paths (e.g., `~/Downloads/`) are not durable references. They are valid as working context during a live session but must not be the sole citation in the audit record, because they will be unresolvable from any other machine or after the file is moved.

## Drift

The following risks do not produce a single observable failure. They accumulate as gradual divergence and will not announce themselves. "No incident" is not the same as "no problem."

**Slow-rot risks (no single failure event):**

- **Spec/helper divergence:** `speak.md` and other route specs describe helper call shapes. When the helper evolves, the spec can silently contradict it. The gap only surfaces when a new contributor relies on the spec and gets an unexpected result.
- **Reviewer-prose staleness:** The reviewer block in transcript headers is hand-written. A pending reviewer that joins late, or a reviewer block that is never updated, bakes inaccurate state into the audit trail. No route breaks; the record is simply wrong.
- **Moderator-input transience:** Audit inputs cited as local paths become unresolvable when the file moves or the machine changes. The transcript remains parseable but its evidence base is gone. See **Provenance** above.

**Deferred structural items (trigger-based backlog):**

These items were surfaced in `collab-command-assessment-feedback` (2026-05-01) and explicitly deferred. They should be re-opened when the named trigger fires — not before.

| Item | Concrete-failure trigger |
|---|---|
| Atomic join/speak transaction (registry + transcript written as one unit) | A future collab requires manual recovery from visible row-order drift or mismatched contributor counts |
| Participant-table render helper (equivalent to `render-status` for the participants block) | Same trigger as above |
| Helper CLI versioning (documented contract for subcommand input/output shape) | A subcommand rename or field removal breaks a route spec in production |
| Action Plan → GitHub issue export (`/collab export-issues` or equivalent) | A collab's Action Plan is large enough that manual issue creation becomes the bottleneck |
