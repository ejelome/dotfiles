#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_core/style.md"

grep -Fq "Contract: [document.md](document.md), [command.md](command.md), [context.md](context.md)" "$file" || fail "style.md: missing contract line"
grep -Fq "Per-type templates for common shapes live in [the document standard](document.md)" "$file" || fail "style.md: missing document standard boundary"
grep -Fq "slash playbook details live in [command standard](command.md)" "$file" || fail "style.md: missing command standard boundary"
grep -Fq "## LLM-consumed files" "$file" || fail "style.md: missing LLM-consumed files section"

echo "PASS: style.md declares core markdown contracts"
