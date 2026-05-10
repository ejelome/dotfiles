#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_mdc/auto/auto-docs-markdown.mdc"

grep -Fq "Contract: [shared-docs-precedence](../shared/shared-docs-precedence.mdc), [shared-docs-toc](../shared/shared-docs-toc.mdc)" "$file" || fail "auto-docs-markdown.mdc: missing shared docs contract"
grep -Fq "shared-docs-precedence.mdc" "$file" || fail "auto-docs-markdown.mdc: missing precedence dependency"
grep -Fq "shared-docs-toc.mdc" "$file" || fail "auto-docs-markdown.mdc: missing TOC dependency"
grep -Fq "[style-guide](../../_core/style-guide.md)" "$file" || fail "auto-docs-markdown.mdc: missing style guide dependency"
grep -Fq "[document-standard](../../_core/document-standard.md)" "$file" || fail "auto-docs-markdown.mdc: missing document standard dependency"
grep -Fq "[context-engineering](../../_core/context-management.md)" "$file" || fail "auto-docs-markdown.mdc: missing context engineering dependency"

echo "PASS: auto-docs-markdown.mdc declares README dependencies"
