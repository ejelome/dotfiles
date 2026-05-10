#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/run-plan.md"

grep -Fq 'Layer-1 enforcement' "$file" || fail "run-plan.md: missing layer-1 enforcement note"
grep -Fq 'rejects recording `execution.<role>.status = completed` when unchecked `**<role>:**` Action Plan items remain' "$file" || fail "run-plan.md: missing layer-1 rejection condition"
grep -Fq 'execution completed blocked for role' "$file" || fail "run-plan.md: missing layer-1 abort message shape"
grep -Fq 'unchecked assigned Action Plan item(s) remain' "$file" || fail "run-plan.md: missing unchecked item count in abort message"
grep -Fq 'mark all assigned items `[x]` in the transcript, then re-run `/collab run plan`' "$file" || fail "run-plan.md: missing layer-1 recovery path"

echo "PASS: run-plan.md declares the layer-1 enforcement contract"
