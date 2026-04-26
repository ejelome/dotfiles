#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_mdc/auto/auto-context-gate.mdc"

grep -Fq "Contract: [shared-docs-precedence](../shared/shared-docs-precedence.mdc)" "$file" || fail "auto-context-gate.mdc: missing precedence contract"
grep -Fq "alwaysApply: true" "$file" || fail "auto-context-gate.mdc: missing alwaysApply: true"
grep -Fq "Never proceed while any dependency is not directly readable." "$file" || fail "auto-context-gate.mdc: missing direct-readability stop"
grep -Fq "### Required response when aborting" "$file" || fail "auto-context-gate.mdc: missing abort response contract"

echo "PASS: auto-context-gate.mdc declares the hard-stop contract"
