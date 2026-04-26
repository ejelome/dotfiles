# /eval

Route specialist evaluation workflows through one namespace so review commands stay grouped.

## Trigger

**Slash:** `/eval`
**Signature:** `/eval <uid | wse | igd | ops | tune>`
**Phrases:** evaluation workflow, principal review, rubric review

## Steps

1. Resolve `<route>` from the first token after `/eval`. If missing or invalid, **ABORT** naming the token received.
2. Load `../_functions/eval/<route>.md` from the Cursor config root.
3. Execute that route with the remaining user input and attachments.

## Notes

- **Route:** `uid` -> [_functions/eval/uid](../_functions/eval/uid.md); `wse` -> [_functions/eval/wse](../_functions/eval/wse.md); `igd` -> [_functions/eval/igd](../_functions/eval/igd.md); `ops` -> [_functions/eval/ops](../_functions/eval/ops.md); `tune` -> [_functions/eval/tune](../_functions/eval/tune.md).
- **Parameters:** `<uid | wse | igd | ops | tune>` — required evaluation route.
- **Examples:** `/eval uid screenshot.png /path/to/project`, `/eval wse /path/to/project`, `/eval tune wse /path/to/project`.
