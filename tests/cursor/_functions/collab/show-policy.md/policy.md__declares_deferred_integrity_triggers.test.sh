#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/show-policy.md"

grep -Fq 'Capability-class enforcement for mutating collab routes' "$file" || fail "policy.md: missing deferred capability-enforcement item"
grep -Fq 'A trusted actor channel exists for at least two supported harnesses, or an integration test can distinguish a joined caller from a non-joined caller for a mutating collab route' "$file" || fail "policy.md: missing deferred capability-enforcement trigger"
grep -Fq 'When an Action Plan item resolves a Drift deferral, the same completion path must update this section before recording execution as complete' "$file" || fail "policy.md: missing drift completion binding"
grep -Fq 'Resolved structural items (provenance retained)' "$file" || fail "policy.md: missing resolved structural items table"
grep -Fq 'Join/speak registry + transcript transaction' "$file" || fail "policy.md: missing resolved join/speak transaction provenance"
grep -Fq 'Participant-table render helper' "$file" || fail "policy.md: missing resolved participant render provenance"
grep -Fq 'Tombstone-style contribution retract' "$file" || fail "policy.md: missing resolved tombstone-retract provenance"
grep -Fq 'tools/collab/registry.py retract-speak' "$file" || fail "policy.md: missing retract-speak source provenance"

echo "PASS: policy.md declares deferred integrity triggers"
