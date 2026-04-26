#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_mdc/shared/shared-docs-precedence.mdc"

grep -Fq "Contract: [auto-context-gate](../auto/auto-context-gate.mdc), [auto-docs-markdown](../auto/auto-docs-markdown.mdc)" "$file" || fail "shared-docs-precedence.mdc: missing auto-rule contract"
grep -Fq "4. **Invocation-gated workflow directives**" "$file" || fail "shared-docs-precedence.mdc: missing invocation-gated row"
grep -Fq "5. \`auto-docs-markdown.mdc\`" "$file" || fail "shared-docs-precedence.mdc: missing auto-docs-markdown fallback row"
grep -Fq "When any instruction would infer, stub, or proceed on unread dependencies" "$file" || fail "shared-docs-precedence.mdc: missing hard stop override"

echo "PASS: shared-docs-precedence.mdc defines README resolution order"
