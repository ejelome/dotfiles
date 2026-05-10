# Test Contract Inventory

Initial inventory for the test-reduction collaboration opened on 2026-05-08.

This is a first executable inventory, not a deletion list. The audit estimate named 63 doc-contract tests; the current tree contains 50 pure doc-contract shell tests plus fixture-backed mixed tests that also contain doc assertions. Until that discrepancy is reconciled, only the verified rows below are eligible for classification work.

## Summary

| Bucket | Count | Status |
| --- | ---: | --- |
| Pure doc-contract shell tests | 50 | Retain pending owner review |
| Mixed doc-contract shell tests | 3 | Retain; fixture behavior present |
| Repo artifact and golden-adjacent shell tests | 10 | Retain unless replacement coverage and review land |
| Golden snapshot files | 2 | Not deleted in this batch |
| `cursor/_tests/*.md` harness files | 10 | Out of deletion scope |

## Annotation Defaults

Rows below default to `REGRESSION: unknown`. A later deletion batch must check git history and replace `unknown` with `none` or a specific commit before requesting review.

## Pure Doc-Contract Tests

| Path | Assertion style | Protected surface | Owner | Type | Status |
| --- | --- | --- | --- | --- | --- |
| `tests/REPOSITORY.md/REPOSITORY.md__chain_referenced_sections_exist.test.sh` | grep | Repository contract section chain and output-chain names | self | structure | retain |
| `tests/cursor/_core/command-standard.md/command-standard.md__declares_multistage_signature_contract.test.sh` | grep | Command contract multistage signature rules | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/command-standard.md/command-standard.md__declares_playbook_contracts.test.sh` | grep | Command playbook trigger/steps/notes contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/context-management.md/context-management.md__declares_scope_and_budget_contracts.test.sh` | grep | Context scope and 250-line budget contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/document-standard.md/document-standard.md__readme_skeleton_has_required_sections.test.sh` | grep | README skeleton and description limits | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/agent-effort.md/agent-effort.md__declares_effort_override_taxonomy.test.sh` | grep | Effort override taxonomy | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/command-argument.md/command-argument.md__declares_force_negative_contract.test.sh` | grep | Force flag negative contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_core/style-guide.md/style-guide.md__declares_core_markdown_contracts.test.sh` | grep | Core markdown style contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/agent/upgrade.md/upgrade.md__declares_upgrade_safety_contract.test.sh` | grep | Agent upgrade safety gates | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/advance.md/next.md__declares_phase_sequence.test.sh` | grep | Collab phase sequence and next-role output | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/close.md/close.md__declares_closed_status_contract.test.sh` | grep | Collab close status and clear notice contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/init.md/init.md__declares_template_and_slug.test.sh` | grep | Collab init template and slug contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/join.md/join.md__declares_role_json_contract.test.sh` | grep | Collab join role JSON and participant table contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/registry_routes__declare_management_contract.test.sh` | grep | Collab management route registry contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/restore.md/prev.md__declares_append_only_rollback.test.sh` | grep | Collab restore append-only rollback contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/rewrite-execution.md/re-execute.md__declares_rewrite_and_retry_contract.test.sh` | grep | Collab rewrite execution retry contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/rewrite-speak.md/re-speak.md__declares_rewrite_contract.test.sh` | grep | Collab rewrite speak revision contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/rewrite-summary.md/re-summarize.md__declares_rewrite_contract.test.sh` | grep | Collab rewrite summary in-place contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/routes__declare_explicit_record_targeting.test.sh` | grep | Collab route registry targeting language | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/run-plan.md/execute.md__declares_completion_only_execution_marker.test.sh` | grep | Collab run-plan completion-only execution marker | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/run-plan.md/run-plan.md__declares_layer1_enforcement_contract.test.sh` | grep | Collab run-plan layer-1 enforcement note | central-checker | prose-duplicate | invariant listed |
| `tests/cursor/_functions/collab/set.md/set.md__declares_field_ownership_boundary.test.sh` | grep | Collab set field ownership boundary | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/show-policy.md/policy.md__declares_deferred_integrity_triggers.test.sh` | grep | Collab policy deferred integrity triggers | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/show-policy.md/policy.md__no_hardcoded_acronyms.test.sh` | grep | Collab policy role discovery avoids hardcoded acronyms | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/speak.md/speak.md__declares_effort_override_slot.test.sh` | grep | Collab speak effort override slot | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/speak.md/speak.md__declares_write_gates.test.sh` | grep | Collab speak write gates and action-plan checklist shape | central-checker | prose-duplicate | invariant listed |
| `tests/cursor/_functions/collab/unset.md/unset.md__declares_scoped_reviewer_clear.test.sh` | grep | Collab unset scoped reviewer clear contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/collab/write-summary.md/summarize.md__declares_summary_boundary.test.sh` | grep | Collab summary boundary contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/doc/write-changelog.md/changelog.md__declares_replay_contract.test.sh` | grep | Changelog replay contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/doc/write-readme.md/readme.md__default_template_has_placeholders.test.sh` | grep/python | README default template placeholders and TOC shape | self | generated-consistency | retain |
| `tests/cursor/_functions/flags__declare_force_route_contract.test.sh` | grep | Force route declaration contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/git/commit.md/commit.md__declares_atomic_grouping_and_squash_contract.test.sh` | grep | Git commit atomic grouping and squash contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/narrative/rewrite-content.md/narrative.md__declares_handoff_state_contract.test.sh` | grep | Narrative handoff state contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/narrative/rewrite-content.md/narrative.md__declares_role_resolution_contract.test.sh` | grep | Narrative role resolution contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_functions/narrative/rewrite-content.md/narrative.md__declares_stage_signatures.test.sh` | grep | Narrative stage signatures | self | structure | centralize before deletion |
| `tests/cursor/_functions/quality/show-notes.md/notes.md__matches_eval_tune_contract.test.sh` | grep | Quality notes route/tune contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_mdc/auto/auto-collab-format.mdc/auto-collab-format.mdc__declares_structure_only_contract.test.sh` | grep | Collab format rule structure-only boundary | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_mdc/auto/auto-context-gate.mdc/auto-context-gate.mdc__declares_hard_stop_contract.test.sh` | grep | Context gate hard-stop contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_mdc/auto/auto-docs-markdown.mdc/auto-docs-markdown.mdc__declares_readme_dependencies.test.sh` | grep | Docs markdown dependency contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_mdc/shared/shared-docs-precedence.mdc/shared-docs-precedence.mdc__defines_readme_resolution_order.test.sh` | grep | README resolution order contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_mdc/shared/shared-docs-toc.mdc/shared-docs-toc.mdc__defers_to_precedence_and_anchors.test.sh` | grep | Docs TOC precedence and anchor contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/_templates/_templates__scaffold_contract.test.sh` | grep | Agent scaffold template contract | self | prose-duplicate | migrate before deletion |
| `tests/cursor/commands/agent.md/agent.md__routes_agent_workflow.test.sh` | grep | Agent router workflow and route map | self | structure | centralize before deletion |
| `tests/cursor/commands/collab.md/collab.md__routes_collab_workflow.test.sh` | grep | Collab router workflow and route map | self | structure | centralize before deletion |
| `tests/cursor/commands/commands.md/commands.md__catalog_lists_docs_readme_route.test.sh` | grep | Commands catalog `/doc write readme` roster entry | self | structure | centralize before deletion |
| `tests/cursor/commands/commands.md/commands.md__prose_dispatch_boundary.test.sh` | grep/python | Prose dispatch boundary and examples | self | structure | centralize before deletion |
| `tests/cursor/commands/doc.md/doc.md__routes_write_readme_through_command_contract.test.sh` | grep | Doc router write-readme route | self | structure | centralize before deletion |
| `tests/cursor/commands/narrative.md/narrative.md__routes_rewrite_through_command_contract.test.sh` | grep | Narrative router rewrite-content route | self | structure | centralize before deletion |
| `tests/cursor/rules/auto.mdc/auto.mdc__routes_readme_rule_stack.test.sh` | grep | Auto rule README stack links | self | structure | centralize before deletion |
| `tests/cursor/rules/shared.mdc/shared.mdc__routes_shared_docs_helpers.test.sh` | grep | Shared rule docs helper links | self | structure | centralize before deletion |

## Mixed Doc-Contract Tests

| Path | Assertion style | Protected surface | Owner | Type | Status |
| --- | --- | --- | --- | --- | --- |
| `tests/cursor/_core/route-sufficiency.md/route-sufficiency.md__declares_route_sufficiency_contract.test.sh` | grep + fixture | Route sufficiency contract and sample shape | self | behavior | retain |
| `tests/cursor/_functions/agent/upgrade.md/upgrade.md__updates_old_prefix_fixture.test.sh` | fixture + grep | Agent upgrade old-prefix rewrite behavior | self | behavior | retain |
| `tests/cursor/_functions/collab/helper-cli-contract__init_and_speak_render.test.sh` | helper execution + grep | Collab helper CLI init/speak-render behavior | self | behavior | retain |

## Repo Artifact And Golden-Adjacent Tests

| Path | Assertion style | Protected surface | Owner | Type | Status |
| --- | --- | --- | --- | --- | --- |
| `tests/README.md/README.md__matches_docs_readme_contract.test.sh` | generated checks + link validation | README required sections, TOC, links, and validation commands | self | generated-consistency | retain |
| `tests/MANUAL.md/MANUAL.md__mirrors_link_targets_contract.test.sh` | generated link-target checks + link validation | MANUAL link target tables, TOC, links, and traced status | self | generated-consistency | retain |
| `tests/REPOSITORY.md/REPOSITORY.md__chain_referenced_sections_exist.test.sh` | grep | Repository output-chain and validation-mode sections | self | structure | retain |
| `tests/REPOSITORY.md/REPOSITORY.md__non_cursor_contract_scripts_have_mirrored_suites.test.sh` | shell scan | Non-Cursor contract scripts have mirrored test suites | self | behavior | retain |
| `tests/link.sh/link.sh__symlinks_and_is_idempotent.test.sh` | fixture execution | Linker symlink creation and idempotency | self | behavior | retain |
| `tests/link.sh/link.sh__backs_up_existing_targets.test.sh` | fixture execution | Linker backup behavior | self | behavior | retain |
| `tests/link.sh/link.sh__rejects_unknown_nested_layout.test.sh` | fixture execution | Linker nested-layout rejection | self | behavior | retain |
| `tests/link.sh/link.sh__cleans_known_nested_mirror_symlinks.test.sh` | fixture execution | Linker nested-mirror cleanup | self | behavior | retain |
| `tests/launcher/setup-cursor-workspace-launcher.sh/setup-cursor-workspace-launcher.sh__rejects_unknown_argument.test.sh` | script execution | Launcher setup argument rejection | self | behavior | retain |
| `tests/launcher/setup-cursor-workspace-launcher.sh/setup-cursor-workspace-launcher.sh__shows_help.test.sh` | script execution | Launcher setup help output | self | behavior | retain |

## Golden Snapshot Files

| Path | Current owner | Status |
| --- | --- | --- |
| `tests/README.md/README.md.golden` | none after targeted checks | keep until reviewer-approved file deletion |
| `tests/MANUAL.md/MANUAL.md.golden` | none after targeted checks | keep until reviewer-approved file deletion |

## Deletion Batch 0 Report

- Test-count delta: 0 files.
- Phrase-grep delta: 0 local route greps removed.
- Removed assertions: README full-file diff and MANUAL full-file cmp were replaced by targeted generated-artifact checks.
- Replacement owner: `tests/README.md/README.md__matches_docs_readme_contract.test.sh`, `tests/MANUAL.md/MANUAL.md__mirrors_link_targets_contract.test.sh`, and `tools/check-cursor-content.sh`.
- Coverage-equivalence rationale: full-file snapshots no longer own ordinary prose stability; required sections, generated TOC shape, source-of-truth markers, link validity, and generated link-target rows now own the artifact contract.
- Validation commands: `SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`, `./tests/run.sh`, `./link.sh`, `SMOKE_CHECK_RUNTIME=1 SKIP_TESTS_RUN=1 ./tools/smoke-check.sh`.

## Reviewer Findings (pa, 2026-05-08)

Reviewer pass against the gate from `## Conclusion` (pa adjudication): a row is deletion-eligible only if `CONTRACT` names a specific surface, `OWNER: central-checker` is verified by reading the central checker test, `TYPE ∈ {structure, prose-duplicate}`, and (for golden-file rows) replacement coverage including a generator/artifact divergence check lands in the same batch.

**Batch 0 review.** Reported deletions: 0 files. Replacement checks landed for README and MANUAL (`tests/README.md/README.md__matches_docs_readme_contract.test.sh`, `tests/MANUAL.md/MANUAL.md__mirrors_link_targets_contract.test.sh`). MANUAL's replacement reads link-spec helpers from `tools/lib/link-targets.sh` and asserts the generated rows are present, which satisfies the generator/artifact divergence requirement. README's replacement uses the same shape. The two snapshot files remain in place per gate. **Batch 0 verdict: approved as annotation + replacement-landing only; no `rm` executed.**

**Rows currently flagged `OWNER: central-checker` — verdict: REJECT for the next deletion batch.**

1. `tests/cursor/_functions/collab/run-plan.md/run-plan.md__declares_layer1_enforcement_contract.test.sh` — Inventory marks `central-checker` / `invariant listed`. Verification: `cursor/_generated/content-invariants.tsv` registers exactly one needle for this file, `Layer-1 enforcement`. The route-local test asserts five distinct phrases (`Layer-1 enforcement`, the rejection-condition sentence, the abort-message shape, the unchecked-item-count fragment, and the recovery-path sentence). The central checker (`tools/check-cursor-content.sh check_content_invariants`) exercises only the first phrase. The remaining four phrases have no central executable owner. **Reject:** `OWNER: central-checker` is not satisfied for the surface as a whole. Remediation: either add the four remaining phrases as named invariants in `content-invariants.tsv` (and re-verify), or downgrade the row to `OWNER: self` and treat as `migrate before deletion`.

2. `tests/cursor/_functions/collab/speak.md/speak.md__declares_write_gates.test.sh` — Inventory marks `central-checker` / `invariant listed`. Verification: `content-invariants.tsv` registers one needle for this file, `Action Plan checklist shape`. The route-local test asserts ~30 distinct phrases covering closed-record gate, join-before-speak gate, moderator content boundary, `--turn-order` flag, helper-backed speak-state, collapsible block shape, registry phase/participant/turn-order authority, no-retract recovery, and several negative anti-drift assertions. Of these, only the action-plan-shape needle is centralized. **Reject:** `OWNER: central-checker` is not satisfied for the surface as a whole. Remediation: same as row 1 — extend `content-invariants.tsv` to cover the additional protected phrases before changing the row to deletion-eligible, or downgrade to `OWNER: self`.

**Rows marked `centralize before deletion` (TYPE: structure, OWNER: self).** Not deletion-eligible this round by the gate (`OWNER` is `self`, central coverage not yet established). Strengthening `tools/check-cursor-content.sh` plus its tests is the precondition; until then these stay.

**Rows marked `migrate before deletion` (TYPE: prose-duplicate, OWNER: self).** Not deletion-eligible this round. Migration into a named invariant list validated by a shared checker is the precondition.

**Behavior and generated-consistency rows.** Retained as recorded. Not in scope for deletion this round.

**Golden snapshot files.** `tests/README.md/README.md.golden` and `tests/MANUAL.md/MANUAL.md.golden` stay until reviewer-approved file deletion in a future batch. Removing them additionally requires demonstrating that the targeted replacement checks cover generator/artifact divergence — already partially in place via the link-spec helper assertions in the MANUAL replacement; equivalent coverage for README should be confirmed before the snapshot file is removed.

**Out-of-scope reminders for the next executor.** Behavioral test removal, `cursor/_tests/*.md` reduction, and any deletion justified by `REGRESSION: none` alone remain prohibited per the Conclusion.

**Net effect of this review.** Of the 50 pure doc-contract rows, **0 rows are deletion-eligible** in the next batch as currently annotated. The two `central-checker` rows fail verification and revert to non-eligible until the central TSV is broadened or the row is downgraded. The fastest path to a non-zero deletion batch is to extend `content-invariants.tsv` to enumerate the additional phrase invariants the route-local tests currently protect, then re-run review.
