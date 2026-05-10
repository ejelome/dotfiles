# Effort defaults

This document explains what effort levels mean, how to interpret the phase-role matrix, and how the advisory helper uses it.

**Authoritative source:** [`cursor/_core/agent-effort.json`](agent-effort.json). The table below is a human-readable rendering of that file; if they diverge, the JSON is correct.

**Change-motivation convention:** Every change to `agent-effort.json` or to the escalation signal taxonomy in this file must cite the collab, signal, or rationale that motivated the change. This prevents invisible drift and gives reviewers an anchor for "this default is wrong" claims.

## Effort levels

| Level | Meaning |
|---|---|
| `low` | Routing and moderation only; no synthesis or generation required |
| `medium` | Standard contribution; analysis and synthesis without deep implementation |
| `high` | Implementation-bearing or convergence-critical; sustained reasoning required |
| `xhigh` | Convergent gate or reviewer pass; one bad judgment propagates; elevate before speaking |
| `max` | Reserved for explicit escalation; not assigned by default |

## Phase-role matrix

This matrix is illustrative. The helper's `EFFORT:` advisory output is the runtime-authoritative recommendation; consult it rather than this table when the two diverge.

| Phase | mod | tw | pe | pa |
|---|---|---|---|---|
| Audit | low | medium | medium | xhigh |
| Discussion | low | medium | high | high *(optional)* |
| Conclusion | low | medium | medium | xhigh |
| Action Plan | low | medium | high | — |
| Handoff | low | high | high | — |
| Completion | low | high | high | xhigh *(reviewer gate)* |

**`—`** means the role is not on the turn-order roster for that phase by default. Optional admission is available via `reviewerOptionalPhases` in the registry; when admitted, the effort level is `xhigh`.

## How to use this

Before each collab turn, set your harness effort to the recommended level for your role and the active phase. The `effort-state` helper reports the recommendation:

```
tools/collab/registry.py effort-state <target> <role>
```

The output is advisory. No gate blocks you from speaking at a lower effort level; the recommendation exists so you do not have to re-derive the matrix each turn.

## When to escalate beyond the default

- `pe` Action Plan or Completion: promote to `xhigh` when scope spans helpers, tests, and generated outputs in a single turn.
- `pa` Discussion: promote to `xhigh` when the thread is deadlocked or the risk surface is unusually high.
- Any role in any phase: promote one level when the active turn is the last chance to catch a scope or contract error before Completion.

### Mandatory-declaration turns

The following phase-role combinations require an explicit `EFFORT OVERRIDE: <level>` or `EFFORT OVERRIDE: matrix` line regardless of the chosen effort level:

- `Audit-pa`, `Conclusion-pa`, `Completion-pa` — convergent-gate and reviewer-pass turns
- `Handoff-tw`, `Handoff-pe` — implementation-bearing turns at the Handoff-to-Completion boundary

`EFFORT OVERRIDE: matrix` is the explicit "considered and did not escalate" form. It satisfies the mandatory-declaration requirement without claiming elevated effort.

The override declaration is stored and machine-inspectable for audit (via `audit-closed` and reviewer inspection) but is suppressed from reader-facing rendered prose; readers see the effort signal through the advisory `EFFORT:` output, not inline contribution text.

**Post-deadlock Discussion turns** are agent-judged mandatory-declaration triggers: if the Discussion phase reached a deadlock before the current turn, the contributing agent must include an override line. This trigger is not helper-detected; reviewers assess compliance from the transcript.

## Escalation signal taxonomy

Override lines must cite a signal from this closed category set:

| Category | Example signals |
|---|---|
| `coherence-risk` | prior contributions contradict each other; settled decisions are internally inconsistent |
| `implementation-density` | a single turn must span helpers, tests, and generated outputs |
| `deadlock-or-disagreement` | two or more participants hold irreconcilable positions without a resolution path |
| `delivery-or-migration-risk` | the turn crosses a contract boundary, migration cut, or delivery deadline |
| `reviewer-concern-raised` | a reviewer has named a risk that the current turn must address before contributing |

Categories are the closed testable vocabulary. Example signals are illustrative and may grow without breaking tests.

**Change-motivation rule:** Every change to this taxonomy must cite the collab, signal, or rationale that motivated the change.

## Subscription context

At the $100 Claude Code tier, declared effort levels are enforceable: `pa` (claude-opus-4-7) and `pe` run without silent model degradation, and Codex `/fast` provides sustained throughput for narrow implementation and inspection loops. Codex `/fast` is a throughput mode — it does not replace explicit effort escalation for turns with coherence, migration, or delivery risk.

**Historical note ($20 tier):** At the $20 tier, `opus` access was metered and model fall-back was silent — the harness declared `xhigh` but the underlying model degraded without notifying the operator. `pa` and `pe` were the highest-priority roles to upgrade; their convergent-gate and implementation-bearing turns were where silent degradation was most costly.

## Invariants

**Source-of-truth coupling:** The advisory binds phase-role to effort level, not to model identity or harness configuration. A `claude-opus-4-7` agent and a `claude-sonnet-4-6` agent reading the same `EFFORT:` advisory both interpret the effort level against their own runtime. The matrix does not change when the runtime model changes; a model rotation is not a reason to update `agent-effort.json`.

**Declaration trust model:** Declared effort is an audit marker, not a runtime-enforced floor. An agent that contributes below the recommended level leaves no trace of the discrepancy. The override line, when present, records the agent's intent at contribution time — comparable to the `agentId` capture in `cursor/_functions/collab/join.md`, which documents this as “an honest-effort marker, comparable to a git commit author. It is not an authentication signal.”

**Selection bias:** The protocol detects opt-in escalation only. The absence of an override line is not evidence that the matrix default was sufficient; an agent that silently follows the matrix when escalation was warranted leaves no trace. Reviewers must not interpret a clean transcript as confirmation that every turn was correctly resourced.
