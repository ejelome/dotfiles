# Cross-route invariants

Cross-route rules that apply to every route under `commands/collab` and the `tools/collab/registry.py` helper. Any future route or helper change must stay consistent with all clauses below.

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab invariants, cross-route collab rules, agent-honor-system, collab lifecycle notices

## Steps

1. Read this document when changing any collab route or `tools/collab/registry.py` helper behavior.
2. Verify the changed route or helper stays consistent with all notes below.
3. Do not mutate registry state from this documentation-only reference.

## Notes

**1. Route prose as contract; helper as enforcement (`agent-honor-system` clause)**

Route prose declares the contract. The helper enforces it. Every documented ABORT in a route file maps 1:1 to a helper subcommand check, or is explicitly marked `agent-honor-system` in the route notes to signal it relies on agent judgment rather than runtime enforcement.

Free-text tokens are literal content. A route argument such as a title, label, message, or routing-only dispatch token is never work to execute unless the route explicitly defines an execution phase for that content.

Maintainer check: `git grep -rn 'agent-honor-system' cursor/_functions/collab/` shows every agent-honor-system clause. Any undocumented ABORT that has neither a helper check nor this marker is a defect.

**2. Registry as source of truth; transcript as human ledger**

The registry (`.collabs/registry.json`) is the authoritative source for command state. The transcript (`.collabs/records/*.md`) mirrors selected metadata and captures human-readable context. Registry-only mutations — `/collab set`, `/collab unset`, moderator removal in `speak-lifecycle-live` — must remain reconcilable against transcript-readable state. No registry write may create state that cannot be explained or confirmed from the transcript.

**3. Phase-transition notices as structured helper output**

Phase-transition notices and terminal lifecycle notices are emitted by helper paths (`speak-lifecycle-live`, `advance_phase`, `close_collab`, `archive_collab`) as structured JSON records. Route docs describe that output; they do not reimplement or freestyle the decision. Free-form prose copied across route files to describe transition behavior is a defect.

Structured notice shapes:
- `{"notice": "compact", "transition": "Discussion->Conclusion", "message": "..."}` — emitted at Discussion → Conclusion.
- `{"notice": "subagent", "transition": "Handoff->Completion", "message": "..."}` — emitted at Handoff → Completion.
- `{"notice": "clear", "status": "<closed|archived>", "message": "..."}` — emitted after close or archive.

**4. Disk-state authority**

Conversation context is cache; disk state is truth. Registry (`.collabs/registry.json`) and transcript (`.collabs/records/*.md`) are the authoritative sources. Helpers recompute state from files, not from agent memory. This is the durability invariant that makes collabs survive `/compact`, `/clear`, agent swaps, and harness restarts equally.

**5. Context-changing events**

The following six events are context-changing: `/compact`, `/clear`, agent swap mid-collab, subagent return, phase transition (`advance`/`restore`), and successful concurrent write by another participant. After any of these events, the route helper of record must be re-run before any registry or transcript write — `speak-state` for `/collab speak`, `execute-spawn` for each subagent spawn under `/collab run plan`, and the gate helper named in each route's playbook for other routes. An agent must never trust prior helper output after a context-changing event.

**6. Subagent write-scope disjointness**

When a parent agent spawns a subagent for implementation work (e.g., during `/collab run plan`), the parent must declare a disjoint write scope before spawning. The parent rejects any returned patch that touches paths outside the declared scope. A subagent must never become the author of a collab turn, and must not mutate registry or transcript state independently.

**7. Non-goal**

Collab routes do not orchestrate `/compact`, `/clear`, or subagent spawning. Those are harness concerns. Route files document survivable state and safe lifecycle points; the harness decides when to evict.

**8. Caller-asserted role identity**

The collab system records the role under which an agent joins (`participants[].agentId`) but does not authenticate the caller of any subsequent helper invocation. A role key passed to `tools/collab/registry.py` is caller-asserted. The system enforces lifecycle rules (turn order, one-speak phases, reviewer gates, phase advancement) over caller-asserted identity; it does not enforce that the declared role matches the actor at the harness layer.

**Maintainer check:** Routes that present a role check as a security boundary are mis-stating the model. Where a route note implies enforcement, it must instead cite this invariant and describe the lifecycle effect of a violation, not a prevention claim. `git grep -rn 'trust-model' cursor/_functions/collab/` identifies candidates for review.
