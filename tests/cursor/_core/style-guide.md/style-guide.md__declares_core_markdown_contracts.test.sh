#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/style-guide.md"

grep -Fq "Contract: [document-standard.md](document-standard.md), [command-standard.md](command-standard.md), [context-management.md](context-management.md)" "$file" || fail "style-guide.md: missing contract line"
grep -Fq "Per-type templates for common shapes live in [the document standard](document-standard.md)" "$file" || fail "style-guide.md: missing document standard boundary"
grep -Fq "slash playbook details live in [command standard](command-standard.md)" "$file" || fail "style-guide.md: missing command standard boundary"
grep -Fq "## LLM-consumed files" "$file" || fail "style-guide.md: missing LLM-consumed files section"

echo "PASS: style-guide.md declares core markdown contracts"
