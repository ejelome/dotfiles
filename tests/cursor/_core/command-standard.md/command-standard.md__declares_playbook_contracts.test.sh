#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/command-standard.md"

grep -Fq "Contract: [document-standard.md](document-standard.md#command-md), [style-guide.md](style-guide.md), [context-management.md](context-management.md)" "$file" || fail "command-standard.md: missing contract line"
grep -Fq "## Required sections" "$file" || fail "command-standard.md: missing required sections contract"
grep -Fq "## Catalog" "$file" || fail "command-standard.md: missing catalog contract"
grep -Fq "P1–P11" "$file" || fail "command-standard.md: missing invariant contract"

echo "PASS: command-standard.md declares playbook contracts"
