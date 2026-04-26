#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/rules/auto.mdc"

grep -Fq "Contract: [auto-context-gate](../_mdc/auto/auto-context-gate.mdc), [auto-docs-markdown](../_mdc/auto/auto-docs-markdown.mdc), [auto-code-typescript](../_mdc/auto/auto-code-typescript.mdc), [auto-collab-message-format](../_mdc/auto/auto-collab-message-format.mdc), [shared router](shared.mdc)" "$file" || fail "auto.mdc: missing private rule contract"
grep -Fq "\`auto-context-gate.mdc\`" "$file" || fail "auto.mdc: missing auto-context-gate route"
grep -Fq "\`auto-docs-markdown.mdc\`" "$file" || fail "auto.mdc: missing auto-docs-markdown route"
grep -Fq "\`auto-code-typescript.mdc\`" "$file" || fail "auto.mdc: missing auto-code-typescript route"
grep -Fq "\`auto-collab-message-format.mdc\`" "$file" || fail "auto.mdc: missing auto-collab-message-format route"
grep -Fq "shared.mdc" "$file" || fail "auto.mdc: missing shared router dependency"

echo "PASS: auto.mdc routes the README rule stack"
