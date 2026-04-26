#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_mdc/shared/shared-docs-toc.mdc"

grep -Fq "Contract: [shared-docs-precedence](shared-docs-precedence.mdc)" "$file" || fail "shared-docs-toc.mdc: missing precedence contract"
grep -Fq "TOC inclusion decisions follow the layer ordering in \`shared-docs-precedence.mdc\`." "$file" || fail "shared-docs-toc.mdc: missing precedence deferral"
grep -Fq "Use \`**Table of contents**\` with no trailing \`:\` as the label" "$file" || fail "shared-docs-toc.mdc: missing TOC label rule"
grep -Fq "Spaces become hyphens" "$file" || fail "shared-docs-toc.mdc: missing slug rule"

echo "PASS: shared-docs-toc.mdc defers to precedence and anchors"
