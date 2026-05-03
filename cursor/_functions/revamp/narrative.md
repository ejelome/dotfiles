# /revamp narrative

Run a staged narrative revamp: audit drift in narrative content, align project rules against the global Cursor tree, and gate the result.

**Narrative content:** repository-authored text (`*.md`, `*.mdc`) that conveys meaning rather than executing behavior. Code comments, config values, and executable scripts are out of scope unless the runner opts in.

## Trigger

**Slash:** `/revamp narrative`
**Signature:** `/revamp narrative <audit | align | gate> --role <key>`
**Phrases (audit):** site-wide narrative audit, revamp audit, narrative drift audit with role
**Phrases (align):** narrative rule align, mdc sync check, project rule alignment with role
**Phrases (gate):** narrative revamp gate, final revamp validation with role

## Steps

1. Resolve `<audit | align | gate>` from the first token after `/revamp narrative`. If missing or invalid, **ABORT** naming the token received. Recovery: re-invoke with one of `audit`, `align`, or `gate`.
2. Resolve `--role <key>` from the remaining input. If missing, **ABORT**: `--role <key>` is required.
3. Read `cursor/_roles/<key>.json`. If unreadable, **ABORT**: role file unreadable; name the expected path.
4. Validate the role JSON against [cursor/_core/role.md](../../_core/role.md): `key` must match `<key>`, and `displayName` and non-empty `concerns` must be present. If invalid, **ABORT**: invalid role JSON; name the failed field.
5. For `audit`, run **Phase 1 — Audit**. Focus: meaning assessment — locating drift before scope is known.
6. For `align`, resolve the state file through `tools/revamp/state.py align`. If the state file is missing or `~/.cursor` resolves to the repository `cursor/` tree, **ABORT** naming the failed path. Recovery: re-run `audit` to create state or run `./link.sh` to refresh the runtime tree before continuing. Then run **Phase 2 — Align**. Focus: surface enumeration, verifiable match.
7. For `gate`, resolve `validationCommands` through `tools/revamp/state.py gate`. If the state file is missing or `validationCommands` is empty, **ABORT** naming the missing field. Recovery: re-run `audit` to populate the state file before continuing. Then run **Phase 3 — Gate**. Focus: verifiable execution.

## Notes

- **Route:** `audit` → Phase 1; `align` → Phase 2; `gate` → Phase 3.
- **Stage signatures:** `/revamp narrative audit --role <key>` — `--role` required. `/revamp narrative align --role <key>` — reads state file; `--role` required. `/revamp narrative gate --role <key>` — reads `validationCommands` from state; `--role` required.
- **State helper:** `tools/revamp/state.py` owns state paths, schema validation, rerun mode, runtime guard, and phase transitions for `audit`, `align`, and `gate`.
- **State file:** `.revamps/<repo-basename>-<YYYY-MM-DD>.json` — command-owned session state written to the invocation repo root. Created by `audit`; updated by each subsequent phase. Same-day reruns must choose `abort`, `resume`, or `replace` through the state helper.

| Field | Type | Set by | Description |
|---|---|---|---|
| `repoRoot` | string | audit | Absolute path of the CWD at invocation time |
| `activeStage` | string | each phase | Last completed stage name |
| `narrativeGlobs` | array | audit | Narrative file globs in scope |
| `ruleAlignTargets` | array | align | Project and runtime rule paths compared by align |
| `validationCommands` | array | audit | Repo-specific validation commands discovered at invocation time |
| `roleBindings` | object | each phase | Key of the role that executed each phase, written at the start of each phase invocation; overwritten on rerun. |
| `concernRequirements` | object | each phase | Map of phase name to the executing role's `concerns` array, written after `roleBindings` is resolved; enforced as a hard gate at phase completion. |
| `phaseOutputs` | object | each phase | Machine-readable structured artifact written by each phase to state; read by subsequent phases as the authoritative prior-phase output. |

- **Role contract:** [cursor/_core/role.md](../../_core/role.md) — schema, key uniqueness, and canonical `--role` invocation.
- **Role state writes:** At the start of every phase invocation, write the resolved key to `roleBindings[phase]` and the resolved role's `concerns` array to `concernRequirements[phase]` before producing the phase output. Reruns overwrite `roleBindings[phase]`, `concernRequirements[phase]`, and `phaseOutputs[phase]` together; do not append history.
- **Phase output writes:** After a phase emits its structured artifact, write that artifact to `phaseOutputs[phase]` in the state file. `align` must read `phaseOutputs.audit` before producing output. `gate` must read both `phaseOutputs.audit` and `phaseOutputs.align` before producing output. Never rely on chat history or prose outside the state file for prior-phase handoff.
- **Concern coverage hard gate:** Each phase artifact must include `coveredConcerns`. Verify that `coveredConcerns` is a superset of `concernRequirements[phase]` and that the artifact has non-empty content for every claimed concern. On a miss, emit the full artifact and name missing concern keys. For `audit` and `align`, **ABORT** after emitting the artifact; for `gate`, report `Result: fail`.
- **Discovering `validationCommands`:** In `audit`, resolve the invocation repo's validation surface with `tools/revamp/state.py audit`: check `REPOSITORY.md` for documented commands first; if not found, detect from `package.json` scripts; if not found, detect executable scripts under `tools/`. Write the resolved list to the state file. Gate reads `validationCommands` from state; it does not use hardcoded commands.
- **Audit surfaces:** Every narrative file under `~/.cursor/` is a valid audit surface: `_core/`, `_functions/`, `commands/`, `_tests/`, `rules/`, and `_mdc/`.
- **Align surface:** Project-local `*.mdc` files checked against their counterparts under `~/.cursor/rules/`. Failure modes: file present locally but absent globally, or present globally but absent locally.
- **Phase 1 — Audit:** Do not edit files. Resolve and write the state file. Write `roleBindings.audit` and `concernRequirements.audit` from the resolved role. After emitting the artifact, verify `coveredConcerns` and write the artifact to `phaseOutputs.audit`; on coverage miss, emit the artifact, name missing keys, and **ABORT** before handing off. Emit:

```text
### Phase 1 — Audit

Output artifacts:
- <path>: <purpose>

Drift themes:
- <theme>: <evidence>

Style violations:
- <path>: <violation>

Recommended scope:
<full | path>

Files to edit:
- <path>: <reason>

coveredConcerns:
- <concern key>

Next phase:
Run `/revamp narrative align --role <key>` to check project rule alignment, then `/revamp narrative gate --role <key>`.
```

- **Phase 2 — Align:** Do not edit files outside the alignment surface. Call `tools/revamp/state.py align` before comparing files so the runtime guard rejects symlinked `~/.cursor` projections. Enumerate project-local `*.mdc` files and compare each against `~/.cursor/rules/`. Read `phaseOutputs.audit` from state before producing output; if missing or malformed, **ABORT** naming `phaseOutputs.audit`. Report mismatches — do not auto-resolve. Update state `activeStage: align`, write `roleBindings.align` and `concernRequirements.align` from the resolved role, then verify `coveredConcerns` and write the artifact to `phaseOutputs.align`; on coverage miss, emit the artifact, name missing keys, and **ABORT** before handing off. Emit:

```text
### Phase 2 — Align

Aligned:
- <path>: matches ~/.cursor/rules/<counterpart>

Mismatched:
- <path>: <local state> vs <global state>

Missing locally:
- <path>: present in ~/.cursor/rules/ but absent in project

Missing globally:
- <path>: present in project but absent in ~/.cursor/rules/

coveredConcerns:
- <concern key>

Next phase:
Run `/revamp narrative gate --role <key>`.
```

- **Phase 3 — Gate:** Read `validationCommands` from state. Report only — do not attempt fixes. Also read `phaseOutputs.audit` and `phaseOutputs.align` from state. Update state `activeStage: gate`, write `roleBindings.gate` and `concernRequirements.gate` from the resolved role, then verify prior handoff shape and concern coverage before reporting pass. Write the gate artifact to `phaseOutputs.gate`. If current coverage misses required keys, emit the full artifact, name missing keys, and report `Result: fail`. If prior `phaseOutputs` entries are missing or malformed, report `Result: blocked`. Emit:

```text
### Phase 3 — Gate

Repo root: <repoRoot from state>

Handoff verification:
- audit phaseOutputs: <present | malformed>
- align phaseOutputs: <present | malformed>
- audit concern coverage: <pass | fail — missing: <key>>
- align concern coverage: <pass | fail — missing: <key>>

Source validation:
- `<command>`: <pass | fail | not run>

Result:
<pass | fail | blocked>

Failures or blockers:
- <command/path>: <reason>

coveredConcerns:
- <concern key>
```

- **Stop points:** Stop after each phase. Do not feed unresolved contract guesses into gate. The next-phase instructions in each output block are the only data that should cross phase boundaries.
