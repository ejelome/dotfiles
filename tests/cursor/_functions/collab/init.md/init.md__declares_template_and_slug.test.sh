#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/collab/init.md"

grep -Fq 'Capture the full remaining text after `/collab init` as `<name>`' "$file" || fail "init.md: missing full remaining text capture"
grep -Fq 'replace every run of non-alphanumeric characters with one hyphen' "$file" || fail "init.md: missing slug normalization"
grep -Fq 'If the slug is empty, **ABORT**' "$file" || fail "init.md: missing empty slug abort"
grep -Fq 'Create or update `.collabs/registry.json`' "$file" || fail "init.md: missing registry bootstrap step"
grep -Fq 'Successful init appends one collab entry to `.collabs/registry.json`' "$file" || fail "init.md: missing registry side effect note"
grep -Fq '**Participants:** none' "$file" || fail "init.md: missing participants metadata"
grep -Fq '## Audit' "$file" || fail "init.md: missing Audit phase"
grep -Fq '## Handoff' "$file" || fail "init.md: missing Handoff phase"
grep -Fq 'Use a numbered checklist when sequence matters. Use an unordered checklist only when sequence genuinely does not matter.' "$file" || fail "init.md: missing Action Plan ordering cue"
grep -Fq '1. [ ] **{role}:** {action} — _acceptance: {condition}_' "$file" || fail "init.md: missing Action Plan placeholder"
grep -Fq 'Use a numbered list. Use an unordered list only when sequence genuinely does not matter.' "$file" || fail "init.md: missing Handoff ordering cue"
grep -Fq '1. **{role} ←** {artifact or decision} — _requires: #N, next: {action}_' "$file" || fail "init.md: missing Handoff placeholder with requires field"
grep -Fq '**Turn order:**' "$file" || fail "init.md: missing Turn order metadata field documentation"
grep -Fq 'Registry-backed collab state is authoritative.' "$file" || fail "init.md: missing transcript-mirror note"
grep -Fq 'Await `/collab execute` to run assigned action-plan items, or `/collab close` to close without execution.' "$file" || fail "init.md: missing Completion next-action placeholder"
if grep -Fq 'Await `/collab execute` to mark execution authorization' "$file"; then
  fail "init.md: must not describe execute as authorization-only"
fi
if grep -Fq '## Participants' "$file"; then
  fail "init.md: Participants must stay metadata, not a phase"
fi
if grep -Fq '.collabs/.active' "$file"; then
  fail "init.md: must not bootstrap .active after the registry migration"
fi

echo "PASS: collab init declares template and slug behavior"
