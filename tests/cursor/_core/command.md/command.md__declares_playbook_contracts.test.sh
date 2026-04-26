#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/command.md"

grep -Fq "Contract: [document.md](document.md#command-md), [style.md](style.md), [context.md](context.md)" "$file" || fail "command.md: missing contract line"
grep -Fq "## Required sections" "$file" || fail "command.md: missing required sections contract"
grep -Fq "## Catalog" "$file" || fail "command.md: missing catalog contract"
grep -Fq "P1–P11" "$file" || fail "command.md: missing invariant contract"

echo "PASS: command.md declares playbook contracts"
