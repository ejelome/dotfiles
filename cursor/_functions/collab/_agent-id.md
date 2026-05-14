# agentId vocabulary

Shared vocabulary for the `agentId` value recorded in collab registry `participants[]`.

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab agentId, agent identity vocabulary, stable model family tokens

## Steps

1. Read this document before changing init, join, registry schema prose, or helper validation for `agentId`.
2. Use this document as the single source for route prose. Do not duplicate the precedence list in downstream route files.
3. Do not mutate registry state from this documentation-only reference.

## Notes

- **Purpose:** `agentId` is an at-join forensic marker for the active runtime harness. It is not authentication and is not a model-enforcement mechanism.

- **Precedence:** Declare the first usable value from this list:
  1. Stable model-family token when the harness exposes one: `opus`, `sonnet`, `haiku`, `claude`, `gpt`, `gpt-mini`, or `codex`.
  2. Versioned model identifier when the harness exposes only an exact model string, such as `claude-sonnet-4-6` or `gpt-5.5`.
  3. Harness or surface name when no model identity is available, such as `cursor-composer`, `claude-code`, or `codex-cli`.
  4. The literal string `unknown`, exact lowercase, only when the harness exposes no usable identity.

- **Format:** Use lowercase, hyphenated tokens. Prefer stable family or surface tokens for new joins. Existing versioned registry values remain historical records and must not be migrated solely to match this vocabulary.

- **Unavailable identity:** `unknown` is the only fallback for unavailable identity. Free-form alternatives such as `UNKNOWN`, `unspecified`, and `n/a` are rejected by the helper.

- **Trust model:** The helper enforces presence, whitespace stripping, the exact lowercase `unknown` token, and invalid unavailable-identity aliases. It cannot verify whether the caller chose the highest-precedence available token.
