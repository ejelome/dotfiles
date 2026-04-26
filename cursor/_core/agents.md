# Agent roles

Agent roles define how Claude (Sonnet) and Codex (GPT) divide work in multi-agent repo workflows and when to switch between them.

**Claude (Sonnet) — Language and Writing.** Use when work requires meaning judgment: naming, synthesis, narrative shaping, ambiguity resolution, or detecting conceptual drift.

**Codex (GPT) — Structure and Coding.** Use when work is code- or verification-heavy: inspect the repo, define constraints, edit canonical files, run checks, interpret failures, and loop until done.

| Area | Claude (Sonnet) — Language and Writing | Codex (GPT) — Structure and Coding |
|---|---|---|
| **Role in workflow** | Use when meaning matters as much as structure: naming judgment, cross-doc coherence, synthesis, or diagnosing drift that passes structural checks but reads wrong. | Best when the desired output is a working repo state: inspect source, map chains, make scoped edits, run validation, fix failures, report evidence. |
| **Scope** | Use repo-wide when conceptual or narrative drift is suspected but not yet located. Switch to single-output once a single drifting artifact is named. | Use repo-wide when multiple outputs may be affected. Switch to single-output when one artifact or check chain needs focused repair and re-validation. |
| **When to switch** | Stay when language judgment, synthesis, or writing is the primary work. Switch to Codex (GPT) when the output must become structured, executable, or verifiable. | Stay when the work needs formal chain maps, contract status, test status, verification evidence, or handoff notes. Switch to Claude (Sonnet) when the problem is ambiguous, prose-heavy, or exploratory. |
| **Unique strength** | Holds semantic coherence across large multi-file context; surfaces conceptual drift even when structure is consistent. Strong for naming judgment, doc coherence, and pre-scope diagnosis. | Disciplined execution: turns a scoped task into patches, test runs, failure interpretation, follow-up fixes, and concise evidence. Keeps structure, scope, and meaning stable while the repo changes. |
| **Weakness** | No default structured output — without explicit format instructions, structure varies and results may be hard to execute or verify. For implementation handoffs, use Codex (GPT). | Over-specifies small edits and over-validates trivial wording changes. For a trusted one-file prose pass, use a focused editor prompt. Do not use first when the question is still "what is wrong?" rather than "what should be changed?" |
| **When to return** | Return when language judgment is needed again: naming feels off, docs drift from intent, validation results conflict in meaning rather than structure, or the next step is writing — devblogs, playbooks, explanations, strategy docs. | Return after exploratory findings, before risky repairs, after template or schema changes, after generated catalog changes, and before merging repo-wide syncs. |

## Language and writing

Use Claude (Sonnet) to:

- Synthesize repo findings into a coherent narrative
- Produce devblogs, playbooks, strategy docs, or tradeoff explanations
- Diagnose conceptual misalignment before committing to a repair plan

Switch to Codex (GPT) when the output must become structured, executable, or verifiable.

## Structure and coding

Use Codex (GPT) to make findings executable:

- Define source/runtime contracts and output-chain boundaries
- Convert findings into concrete work orders
- State implementation constraints before edits begin
- Edit canonical source and preserve runtime mirrors as derived output
- Run validation and report pass/fail evidence
- Repair chain, contract, or test drift after syncs and refactors
- Iterate on failures until the target is complete or a real blocker is identified

Switch to Claude (Sonnet) when the work goes abstract again: reinterpretation, narrative repair, or writing-heavy output.
