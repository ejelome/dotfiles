# /collab summarize

Write a human-readable reference summary from an existing collaboration record.

## Trigger

**Slash:** `/collab summarize`
**Signature:** `/collab summarize`
**Phrases:** collab summarize, summarize collaboration, collaboration wrap up

## Steps

1. Resolve the target collab with **Registry targeting** in **Notes**.
2. Read `.collabs/registry.json` and the full resolved transcript. If either is unreadable, **ABORT**: record unreadable; name the path.
3. Draft a concise reference summary from the record's existing content.
4. Write the summary under `## Completion`. If `## Completion` already has content, append a new `### Summary — YYYY-MM-DD` subsection.
5. Preserve all previous participant contributions.
6. Stop after writing the summary.

## Notes

- **Parameters:** target collab slug, id, or legacy transcript path as the first token after `summarize`; when absent, resolved per **Registry targeting** in **Notes**.
- **Registry targeting:** Resolve the target collab from `.collabs/registry.json`, using `tools/collab/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug or id; if that token starts with `.` or `/` and ends with `.md`, match it against `transcript_path` as a legacy explicit target. Otherwise use `active_collab_id`. If the registry is unreadable or invalid, the token does not match any entry, or `active_collab_id` is empty, **ABORT**: registry target unavailable; name the registry field or token.
- **Closed records:** Summaries are allowed on closed records.
- **Fact boundary:** Summarize only what the record supports. Do not mark unaccepted proposals as accepted decisions.
