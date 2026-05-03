# /revamp

Route revamp workflows through one public slash so staged revamp targets stay grouped.

## Trigger

**Slash:** `/revamp`
**Signature:** `/revamp <narrative>`
**Phrases:** revamp workflow, staged revamp, narrative revamp

## Steps

1. Resolve `<narrative>` from the first token after `/revamp`. If missing or invalid, **ABORT** naming the token received.
2. Load `../_functions/revamp/<narrative>.md` from the Cursor config root.
3. Execute that route with the remaining user input and attachments.

## Notes

- **Route:** `narrative` -> [_functions/revamp/narrative](../_functions/revamp/narrative.md).
- **Parameters:** `<narrative>` — required revamp subject.
- **Examples:** `/revamp narrative audit --role pa`, `/revamp narrative align --role tw`, `/revamp narrative gate --role pe`.
