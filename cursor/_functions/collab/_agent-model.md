# Agent model and harness

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab agent model, collab harness model, role model matrix

## Steps

1. Read this document when selecting or auditing collab role model and harness recommendations.
2. Do not mutate registry or transcript state from this documentation-only reference.

## Notes

This document defines the join-time model and harness for each collab role, per-phase effort, and fallback. It supplements [`_agent-effort.md`](_agent-effort.md) (effort levels) and [`_agent-lifecycle.md`](_agent-lifecycle.md) (lifecycle command timing). For the role schema and roster, see [`cursor/_core/agent-role.md`](../../_core/agent-role.md); for agentId precedence and capture semantics, see [`join.md`](join.md).

**Authoritative source:** This file. Values sourced from the collab that produced these values.

## Join-time model and harness

Join-model recommendations are advisory: the registry records `agentId` at join time as an honest-effort forensic capture, not an enforced constraint. To assign a different agent to a role, pick the intended agent when running `/collab join`.

The table below captures recommended defaults. Identifiers name a model family or tier, not a version. They rotate quarterly; a different model family re-evaluates each row on each rotation. When `dcc` is in use, it resolves version pinning for curated launch shortcuts; consult this table for all other harness selection.

| Role | Join model | Harness |
|------|------------|---------|
| mod | n/a (human) | Codex CLI (codex-spark) |
| tw | `sonnet` | Claude Code |
| pe | `gpt` | Codex CLI |
| pa | `opus` | Claude Code |

**Moderator harness.** Moderator turns are human-authored. `codex-spark` with `/fast` applies `_moderator-polish.md` by default and `--verbatim` bypasses that transform. Spark runs on a separate pool from `codex`, is scoped to moderator speed and transcript hygiene only, and must not be used for implementation judgment, convergence review, or action-plan ownership. If Spark is unavailable, use the fastest low-cost Codex CLI helper that preserves the moderator boundary; `mini` is the current fallback example.

**pe join-model variants.** Use `gpt` by default. Use `gpt-mini` for light advisory collabs where cap preservation matters. Use `codex` only when joining narrowly for implementation execution in Completion. Do not use Spark models as the join model for a full pe collab.

**pa fallback.** Use `sonnet` when Opus cap is exhausted or the collab is lightweight with no convergent-gate weight. Opus is cap-fragile under sustained use; Claude Max sustains roughly 2–3 pa-Opus collabs per rolling cap window.

## Per-phase effort

| Phase | mod | tw | pe | pa |
|-------|-----|----|----|----|
| Audit | low | medium | medium | xhigh |
| Discussion | low | medium | high | high |
| Conclusion | low | medium | high | xhigh |
| Action Plan | low | medium | medium | high |
| Handoff | low | high | xhigh | high |
| Completion | low | high | high | xhigh |

Values should match the phase-role matrix in `_agent-effort.json`. When the two diverge, this file is authoritative for both join model and effort matrix values; update `_agent-effort.json` to match.

## Caveats

**Declared bias.** The join-model recommendations for tw, pe, and pa were authored in the collab that produced these values by candidates for those roles: tw by `sonnet`, pe by `gpt`, pa by `opus`. The Conclusion accepted the self-recommendations and declared the bias explicitly. The `mod` Harness recommendation (`codex-spark`) was made by Codex-family agents in Discussion; declared per quarterly-rotation principle.

**Quarterly cross-review.** On each rotation, a different model family re-evaluates whether the recommended family or tier is still the right choice for each role — not which version. The authoring agent must not serve as the sole reviewer of its own row.
