# /docs

Route documentation workflows through one namespace so the command palette stays compact.

## Trigger

**Slash:** `/docs`
**Signature:** `/docs <assess | changelog | compact | compare | manual | readme>`
**Phrases:** docs workflow, documentation command, markdown workflow

## Steps

1. Resolve `<route>` from the first token after `/docs`. If missing or invalid, **ABORT** naming the token received.
2. Load `../_functions/docs/<route>.md` from the Cursor config root.
3. Execute that route with the remaining user input and attachments.

## Notes

- **Route:** `assess` -> [_functions/docs/assess](../_functions/docs/assess.md); `changelog` -> [_functions/docs/changelog](../_functions/docs/changelog.md); `compact` -> [_functions/docs/compact](../_functions/docs/compact.md); `compare` -> [_functions/docs/compare](../_functions/docs/compare.md); `manual` -> [_functions/docs/manual](../_functions/docs/manual.md); `readme` -> [_functions/docs/readme](../_functions/docs/readme.md).
- **Parameters:** `<assess | changelog | compact | compare | manual | readme>` — required documentation route.
- **Examples:** `/docs readme`, `/docs manual`, `/docs changelog atomic`, `/docs assess README.md`, `/docs compare old.md new.md`, `/docs compact README.md`.
