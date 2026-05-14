#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/commands" "$tmp/_functions/collab" "$tmp/_generated" "$tmp/rules" "$tmp/_mdc"

cat >"$tmp/commands/demo.md" <<'EOF'
# /demo

Route demo workflows.

## Trigger

**Slash:** `/demo`
**Signature:** `/demo`
**Prose dispatch:** `(demo)` - for non-Cursor agents; not terminal-executable in Cursor.
**Search phrases:** demo workflow

## Steps

1. Resolve the route.

## Notes

- **Parameters:** none.
EOF

for file in _agent-effort.md _agent-model.md _agent-lifecycle.md _contribution-budget.md _moderator-polish.md _flag-taxonomy.md _helper-output.md; do
  cat >"$tmp/_functions/collab/$file" <<'EOF'
# Collab shared dependency

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab shared dependency

## Steps

1. Read this document.

## Notes

Placeholder.
EOF
done

cat >"$tmp/_functions/collab/_agent-effort.json" <<'EOF'
{}
EOF
cat >>"$tmp/_functions/collab/_agent-effort.md" <<'EOF'

See [`_agent-effort.json`](_agent-effort.json), [`_agent-model.md`](_agent-model.md), and [`_agent-lifecycle.md`](_agent-lifecycle.md).
EOF
cat >>"$tmp/_functions/collab/_agent-model.md" <<'EOF'

See [`_agent-effort.md`](_agent-effort.md) and [`_agent-lifecycle.md`](_agent-lifecycle.md).
Join-model recommendations are advisory: the registry records `agentId` at join time as an honest-effort forensic capture, not an enforced constraint.
fallback guidance.
See `.collabs/records/2026-05-12-old-collab.md`.
EOF
cat >>"$tmp/_functions/collab/_agent-lifecycle.md" <<'EOF'

See [`_agent-effort.md`](_agent-effort.md) and [`_agent-model.md`](_agent-model.md).
The join-time model does not change; only effort adjusts between phases.
EOF
set +e
output="$({
  CURSOR_CONFIG_ROOT="$tmp" \
  "$ROOT/tools/check-cursor-content.sh"
} 2>&1)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "check-cursor-content should reject stale collab record IDs"
assert_contains "$output" "remove stale .collabs record ID citation"

echo "PASS: check-cursor-content rejects stale collab record IDs"
