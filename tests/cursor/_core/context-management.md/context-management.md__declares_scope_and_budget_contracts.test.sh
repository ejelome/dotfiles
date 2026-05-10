#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/context-management.md"

grep -Fq "Contract: [style-guide.md](style-guide.md#llm-consumed-files), [document-standard.md](document-standard.md#llm-consumed-files), [command-standard.md](command-standard.md)" "$file" || fail "context-management.md: missing contract line"
grep -Fq "## Writing commands" "$file" || fail "context-management.md: missing writing commands section"
grep -Fq "Reference exact file paths" "$file" || fail "context-management.md: missing path precision rule"
grep -Fq "### File size discipline" "$file" || fail "context-management.md: missing file size discipline section"

echo "PASS: context-management.md declares scope and budget contracts"
