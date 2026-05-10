#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

install_file="$ROOT/cursor/_functions/agent/install.md"
patch_file="$ROOT/cursor/_functions/agent/patch.md"
upgrade_file="$ROOT/cursor/_functions/agent/upgrade.md"
compact_file="$ROOT/cursor/_functions/doc/compact.md"
init_file="$ROOT/cursor/_functions/collab/init.md"

for file in "$install_file" "$patch_file" "$upgrade_file"; do
  grep -Fq '[--force]' "$file" || fail "${file#$ROOT/}: missing --force signature"
  grep -Fq 'cursor/_core/command-argument.md' "$file" || fail "${file#$ROOT/}: missing flag contract citation"
  grep -Fq 'Unsupported or misplaced flags **ABORT** before any route mutation' "$file" || fail "${file#$ROOT/}: missing pre-mutation flag-position rejection"
  grep -Fq 'compute `the candidate patch`' "$file" || fail "${file#$ROOT/}: missing candidate patch computation"
  grep -Fq 'render the diff from `the candidate patch`' "$file" || fail "${file#$ROOT/}: missing candidate patch diff rendering"
  grep -Fq 'apply `the candidate patch` without recomputation or re-read of source' "$file" || fail "${file#$ROOT/}: missing candidate patch write atomicity"
  grep -Fq 'Gate contract: `cursor/_core/command-argument.md`' "$file" || grep -Fq 'per [cursor/_core/command-argument.md]' "$file" || fail "${file#$ROOT/}: missing gate contract citation"
  grep -Fq '```cursor-flag' "$file" || fail "${file#$ROOT/}: missing cursor-flag block"
  grep -Fq 'flag: force' "$file" || fail "${file#$ROOT/}: missing force flag declaration"
  grep -Fq 'eligibility: eligible' "$file" || fail "${file#$ROOT/}: missing eligible declaration"
done

grep -Fq 'guard-class: hard-abort' "$install_file" || fail "install.md: missing hard-abort force declaration"
grep -Fq 'guard-class: gated-overwrite' "$patch_file" || fail "patch.md: missing gated-overwrite force declaration"
grep -Fq 'guard-class: gated-overwrite' "$upgrade_file" || fail "upgrade.md: missing gated-overwrite force declaration"
grep -Fq 'Type "confirm" to overwrite scaffold files, or "cancel" to abort.' "$install_file" || fail "install.md: missing exact-token force confirmation prompt"
grep -Fq 'If the user does not type the exact proceed token, leave all files untouched' "$install_file" || fail "install.md: missing exact-token preservation"
grep -Fq 'If the user does not type the exact proceed token, stop without any change' "$patch_file" || fail "patch.md: missing exact-token preservation"
grep -Fq 'On refusal or absent confirmation, no file is written and the marker is untouched' "$upgrade_file" || fail "upgrade.md: missing exact-token preservation"

grep -Fq 'eligibility: ineligible' "$compact_file" || fail "compact.md: missing ineligible force declaration"
grep -Fq 'guard-class: output-mode-policy' "$compact_file" || fail "compact.md: missing output-mode-policy guard class"
grep -Fq 'Step 4e is a default output-mode choice' "$compact_file" || fail "compact.md: missing output-mode ineligibility reason"

grep -Fq 'eligibility: ineligible' "$init_file" || fail "init.md: missing ineligible force declaration"
grep -Fq 'guard-class: registry-integrity' "$init_file" || fail "init.md: missing registry-integrity guard class"
grep -Fq 'Steps 8 and 12 guard against duplicate records and registry corruption' "$init_file" || fail "init.md: missing registry-integrity ineligibility reason"

echo "PASS: force route contract declarations are present"
