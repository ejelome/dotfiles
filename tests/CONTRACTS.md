# Test Contract Annotation

Shell tests under `tests/` use this header when they are touched for contract cleanup:

```bash
# CONTRACT: <specific protected surface>
# OWNER: <self|central-checker>
# TYPE: <behavior|generated-consistency|structure|prose-duplicate>
# REGRESSION: <commit-sha|none|unknown>
```

Field rules:

- `CONTRACT` names the exact protected surface, such as `collab run-plan layer-1 enforcement note`, not a category such as `docs`.
- `OWNER: self` means this test remains the executable owner for that surface.
- `OWNER: central-checker` means another checked-in executable checker owns the same surface and has a test that exercises it.
- `TYPE: behavior` runs code, helpers, scripts, CLIs, projection, or smoke checks against fixtures.
- `TYPE: generated-consistency` compares a committed artifact with output or facts generated from repo-owned sources.
- `TYPE: structure` validates a repeatable schema, section shape, roster, route mapping, or link relationship.
- `TYPE: prose-duplicate` validates route-local wording that should migrate into a named invariant list before local copies are removed.
- `REGRESSION` is `unknown` until checked against git history. `REGRESSION: none` is never a deletion reason by itself.

Deletion eligibility:

- `behavior` and `generated-consistency` rows are retained by default.
- `structure` rows are deletion candidates only after `OWNER: central-checker` is verified against a central checker test for the same surface.
- `prose-duplicate` rows are deletion candidates only after the phrase contract is present in a named invariant list validated by a shared checker.
- README and MANUAL snapshot assertions may be removed only in the same batch as narrower generated-artifact checks. The snapshot files themselves stay until reviewer approval for file deletion.
