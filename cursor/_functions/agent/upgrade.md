# /agent upgrade

Apply current scaffold templates to an already-installed multi-agent scaffold in the current repository.

## Trigger

**Slash:** `/agent upgrade`
**Signature:** `/agent upgrade`
**Phrases:** agent upgrade, upgrade multi-agent scaffold, upgrade scaffold templates

## Steps

1. Resolve the repo root as the directory where the command runs. If not inside a git repository, **ABORT**: must be run from a git repository root.
2. Verify `AGENTS.md`, `CLAUDE.md`, and `REPOSITORY.md` exist in the repo root. If any is missing, **ABORT** naming the missing path — run `/agent install` first.
3. Read the installed `AGENTS.md` and locate the `<!-- scaffold-version: <ISO-date> -->` marker line. If absent, **ABORT**: scaffold-version marker not found in `AGENTS.md`; restore the marker manually or reinstall with `/agent install` in a fresh repo.
4. Read `~/.cursor/_templates/AGENTS.md` and locate its `<!-- scaffold-version: <ISO-date> -->` marker line.
5. Compare the two marker strings using lexicographic equality. If equal, compare every installed scaffold file against its corresponding template byte-for-byte. If the markers match and every file is identical to its template, report "scaffold is up to date" and exit.
6. For `REPOSITORY.md`: compare the installed file against `~/.cursor/_templates/REPOSITORY.md`. If the proposed change overlaps any section that has been patched beyond the scaffold-owned header and §6 contract block — that is, any content that is not a `<!-- TODO(agent): ... -->` placeholder — record a targeted skip message for `REPOSITORY.md` and exclude it from the confirmation step. Proceed to evaluate the remaining files.
7. For each of `AGENTS.md` and `CLAUDE.md` where the installed file differs from its template, collect the file and compute a per-file changed-block summary: file name, before/after view of the changed sections, and a statement of what will be overwritten.
8. If no files remain after step 6 excludes `REPOSITORY.md` and no other file differs, report "scaffold is up to date" with a note that `REPOSITORY.md` was skipped due to patched-section overlap, and exit.
9. Present each collected file with its changed-block summary. Ask for a single yes/no confirmation before writing anything. If the user declines or no confirmation is received, leave all files and the marker untouched. Report which files had unconfirmed changes.
10. If confirmed: write every accepted file in full from the corresponding template. All writes are all-or-nothing — if any single write fails, treat the entire set as failed and do not leave a partial upgrade. The marker in the newly written `AGENTS.md` is the current template marker value; no separate marker update step is needed.
11. Report all files written and the new scaffold version marker value. If `REPOSITORY.md` was skipped, include the skip reason in the report.

## Notes

- **Parameters:** none. Default target is the repo root where the command runs.
- **Examples:** `/agent upgrade`.
- **Boundary:** Reads installed scaffold files and `~/.cursor/_templates/`; writes only `AGENTS.md`, `CLAUDE.md`, and (when overlap-free) `REPOSITORY.md` in the repo root. Does not write to `~/.cursor/`, does not modify agent settings JSON.
- **Idempotency:** Re-running upgrade on an already-current scaffold reports "scaffold is up to date" and exits without modifying any file.
- **Marker comparison:** Compare the full `<!-- scaffold-version: <ISO-date> -->` comment line as a string using lexicographic equality. Do not parse the date or apply date arithmetic. Equal → up to date; not equal → present diff and confirm.
- **`REPOSITORY.md` overlap check:** `REPOSITORY.md` is upgraded only when the proposed change is confined to scaffold-owned text. If any patched section (consumer-authored content that replaced a `<!-- TODO(agent): ... -->` placeholder) falls inside the changed region, the upgrade for that file is aborted with a targeted message and the other files continue. This is not a full-route abort.
- **Marker-missing abort:** A present `AGENTS.md` without the scaffold-version marker line is an unknown-state scaffold. Do not infer an older version; abort with a specific message so the user can restore the marker manually.
- **Confirm-before-write:** The confirmation step is mandatory and not optional. On refusal or absent confirmation, no file is written and the marker is untouched.
- **All-or-nothing write:** All confirmed files are written as a set. If any single write fails mid-set, the entire set is treated as failed; do not leave a partial upgrade.
- **Marker-as-comment risk:** The `<!-- scaffold-version: ... -->` marker is an HTML comment with no structural protection. If `AGENTS.md` is ever edited by a tool that rewrites the file body, the marker could be moved or removed. Today `/agent patch` does not edit `AGENTS.md`, so this is not a current failure mode — but if that changes, the marker becomes load-bearing surface that looks like a comment.
- **Next step after upgrade:** If `REPOSITORY.md` was skipped due to patched-section overlap and a scaffold change to that file is important, apply the change manually.
