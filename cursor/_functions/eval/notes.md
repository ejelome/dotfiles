# /eval notes

Serve as the append-only log for QA learning notes approved during `/eval tune` runs.

## Trigger

**Slash:** `/eval notes`
**Signature:** `/eval notes`
**Phrases:** eval notes, QA notes, learning log

## Steps

1. Load this route only through `/eval tune`; do not invoke `/eval notes` directly.
2. Let `/eval tune` append approved learning notes per **Append behavior** in **Notes**.
3. If direct user input asks to rewrite prior entries, **ABORT**: notes are append-only.

## Notes

- **Parameters:** no arguments accepted.
- **Authority:** `/eval tune` owns approved appends to this file.
- **Append-only:** Never replace or rewrite prior audit sections.
- **Append behavior:** When learning is enabled and the user confirms note retention, append one section under `## QA audit — YYYY-MM-DD`; add a counter suffix when the same date heading already exists.
- **Status:** No retained QA audit entries yet.
