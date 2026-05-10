#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/document-standard.md"

grep -Fq "## Usage"  "$file" || fail "document-standard.md: Readme skeleton missing ## Usage"
grep -Fq "## Status" "$file" || fail "document-standard.md: Readme skeleton missing ## Status"
grep -Fq "**Brief description:** ≤80 characters" "$file" || fail "document-standard.md: missing README brief description limit"
grep -Fq "**README opening paragraph:** one sentence when possible" "$file" || fail "document-standard.md: missing README opening paragraph guidance"
grep -Fq "package registry summaries are best at 50–100 characters" "$file" || fail "document-standard.md: missing package metadata description guidance"
grep -Fq "GitHub repository descriptions should stay under 120 characters" "$file" || fail "document-standard.md: missing GitHub description guidance"
grep -Fq "long mission statements, implementation details, setup instructions, and marketing fluff" "$file" || fail "document-standard.md: missing README description avoid-list"

echo "PASS: document-standard.md readme skeleton has required sections"
