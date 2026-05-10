#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/command-standard.md"

grep -Fq "**Multi-stage functions:**" "$file" || fail "command-standard.md: missing multi-stage function rule"
grep -Fq "**Stage signatures:**" "$file" || fail "command-standard.md: missing stage signatures requirement"
grep -Fq "Each stage must state its own required arguments or explicitly state that no arguments are accepted." "$file" || fail "command-standard.md: missing per-stage argument validation rule"

echo "PASS: command-standard.md declares multi-stage signature contracts"
