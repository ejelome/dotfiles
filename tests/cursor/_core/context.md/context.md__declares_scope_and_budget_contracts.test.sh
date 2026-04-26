#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/context.md"

grep -Fq "Contract: [style.md](style.md#llm-consumed-files), [document.md](document.md#llm-consumed-files), [command.md](command.md)" "$file" || fail "context.md: missing contract line"
grep -Fq "## Writing commands" "$file" || fail "context.md: missing writing commands section"
grep -Fq "Reference exact file paths" "$file" || fail "context.md: missing path precision rule"
grep -Fq "### File size discipline" "$file" || fail "context.md: missing file size discipline section"

echo "PASS: context.md declares scope and budget contracts"
