# /docs compact

Compact a Markdown document while preserving all facts, structure, and constraints, and return the result with a short change note.

## Trigger

**Slash:** `/docs compact`
**Signature:** `/docs compact <path>`
**Phrases:** `compact markdown`, `compare then compact`, `tighten markdown`, `shrink doc`

## Steps

1. Resolve `<path>` from the first argument or attachment. If missing, **ABORT**: `<path>` is required.
2. If **`shared-docs-precedence.mdc`**, **`auto-docs-markdown.mdc`**, or (when a TOC is in play) **`shared-docs-toc.mdc`** is required and unreadable, **ABORT** per **`auto-context-gate.mdc`**.
3. Run the same **preservation check** as **`/docs compare`**: refined (or working copy) must retain facts, numbers, caveats, constraints, examples, definitions, key terms, and headings. Restore gaps before finalizing.
4. Execute steps 4a–4e in order:
   - **4a.** Duplicate the resolved document in memory as a working copy.
   - **4b.** Compact the working copy.
   - **4c.** Compare the working copy to the original using the preservation check from step 3.
   - **4d.** Repeat 4b–4c until the preservation check passes or **five** compaction passes complete; if still failing, return the last working copy, list preservation gaps, and stop.
   - **4e.** Return the working copy. Do not overwrite the source file unless the user explicitly requests an in-place update.
5. Default to **response-only** output. Return the **final refined text** and a **short note** (bullets or two to three sentences) on what changed and why.

## Notes

- **Parameters:** `<path>` — Markdown file path (required); attachment is equivalent.
- **TOC:** Do not add by default. Preserve an existing TOC unless the user asks to drop it. Add only when the user asks; follow **`shared-docs-toc.mdc`**; place after title and short intro when present.
- Do not add content beyond what the original supports.
