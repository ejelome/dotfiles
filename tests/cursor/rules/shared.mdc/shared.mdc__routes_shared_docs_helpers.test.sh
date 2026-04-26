#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/rules/shared.mdc"

grep -Fq "Contract: [shared-docs-precedence](../_mdc/shared/shared-docs-precedence.mdc), [shared-docs-toc](../_mdc/shared/shared-docs-toc.mdc)" "$file" || fail "shared.mdc: missing shared docs contract"
grep -Fq "\`shared-docs-precedence.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-precedence route"
grep -Fq "\`shared-docs-toc.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-toc route"

echo "PASS: shared.mdc routes the shared docs helpers"
