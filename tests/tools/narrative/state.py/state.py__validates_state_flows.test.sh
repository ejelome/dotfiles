#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"
export CURSOR_CONFIG_ROOT="$ROOT/cursor"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

repo="$tmp/project"
runtime="$tmp/runtime-cursor"
mkdir -p "$repo/cursor/rules" "$repo/project/.cursor/rules" "$runtime/rules"
printf 'repo rule\n' >"$repo/project/.cursor/rules/local.mdc"
printf 'runtime rule\n' >"$runtime/rules/auto.mdc"

state="$repo/.revamps/project-2026-04-30.json"
python3 "$ROOT/tools/narrative/state.py" audit \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --role pe \
  --validation-command "sh tests/run.sh" >/dev/null

python3 "$ROOT/tools/narrative/state.py" validate "$state" >/dev/null
python3 - "$state" "$repo" <<'PY' || fail "narrative state: audit must persist camelCase schema fields"
import json
import os
import sys
data = json.load(open(sys.argv[1]))
assert data["schemaVersion"] == 1
assert data["repoRoot"] == os.path.realpath(sys.argv[2])
assert data["activeStage"] == "audit"
assert data["narrativeGlobs"] == ["**/*.md", "**/*.mdc"]
assert data["ruleAlignTargets"] == []
assert data["validationCommands"] == ["sh tests/run.sh"]
assert data["roleBindings"] == {"audit": "pe"}
assert data["concernRequirements"] == {"audit": ["effectiveness", "efficiency", "completeness", "optimization"]}
assert isinstance(data["phaseOutputs"], dict)
PY

empty_state="$tmp/empty-concerns.json"
python3 - "$state" "$empty_state" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1]))
data["concernRequirements"] = {}
with open(sys.argv[2], "w") as fh:
    json.dump(data, fh)
PY
! python3 "$ROOT/tools/narrative/state.py" validate "$empty_state" >/dev/null 2>&1 || fail "narrative state: validate must reject empty concernRequirements"

! python3 "$ROOT/tools/narrative/state.py" audit \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --role pe \
  --validation-command "sh tests/run.sh" >/dev/null 2>&1 || fail "narrative state: audit must abort on same-day rerun by default"

linked_runtime="$tmp/linked-runtime"
ln -s "$repo/cursor" "$linked_runtime"
! python3 "$ROOT/tools/narrative/state.py" guard-runtime \
  --repo-root "$repo" \
  --runtime-root "$linked_runtime" >/dev/null 2>&1 || fail "narrative state: guard must reject runtime root that resolves to repo cursor"

python3 "$ROOT/tools/narrative/state.py" align \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --role pe \
  --runtime-root "$runtime" \
  --rerun-mode resume >/dev/null

python3 - "$state" <<'PY' || fail "narrative state: align must persist targets and active stage"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["activeStage"] == "align"
assert data["roleBindings"]["align"] == "pe"
assert data["concernRequirements"]["align"] == ["effectiveness", "efficiency", "completeness", "optimization"]
assert "project/.cursor/rules/local.mdc" in data["ruleAlignTargets"]
assert "~/.cursor/rules/auto.mdc" in data["ruleAlignTargets"]
PY

gate_output="$(python3 "$ROOT/tools/narrative/state.py" gate --repo-root "$repo" --date 2026-04-30 --role pe --rerun-mode resume)"
[[ "$gate_output" == "sh tests/run.sh" ]] || fail "narrative state: gate must print validationCommands"
python3 - "$state" <<'PY' || fail "narrative state: gate must persist active stage"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["activeStage"] == "gate"
assert data["roleBindings"]["gate"] == "pe"
assert data["concernRequirements"]["gate"] == ["effectiveness", "efficiency", "completeness", "optimization"]
PY

echo "PASS: narrative state helper validates narrative state flows"
