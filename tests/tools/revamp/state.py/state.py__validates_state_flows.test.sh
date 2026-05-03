#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

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
python3 "$ROOT/tools/revamp/state.py" audit \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --validation-command "sh tests/run.sh" >/dev/null

python3 "$ROOT/tools/revamp/state.py" validate "$state" >/dev/null
python3 - "$state" "$repo" <<'PY' || fail "revamp state: audit must persist camelCase schema fields"
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
assert isinstance(data["roleBindings"], dict)
assert isinstance(data["concernRequirements"], dict)
assert isinstance(data["phaseOutputs"], dict)
PY

! python3 "$ROOT/tools/revamp/state.py" audit \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --validation-command "sh tests/run.sh" >/dev/null 2>&1 || fail "revamp state: audit must abort on same-day rerun by default"

linked_runtime="$tmp/linked-runtime"
ln -s "$repo/cursor" "$linked_runtime"
! python3 "$ROOT/tools/revamp/state.py" guard-runtime \
  --repo-root "$repo" \
  --runtime-root "$linked_runtime" >/dev/null 2>&1 || fail "revamp state: guard must reject runtime root that resolves to repo cursor"

python3 "$ROOT/tools/revamp/state.py" align \
  --repo-root "$repo" \
  --date 2026-04-30 \
  --runtime-root "$runtime" \
  --rerun-mode resume >/dev/null

python3 - "$state" <<'PY' || fail "revamp state: align must persist targets and active stage"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["activeStage"] == "align"
assert "project/.cursor/rules/local.mdc" in data["ruleAlignTargets"]
assert "~/.cursor/rules/auto.mdc" in data["ruleAlignTargets"]
PY

gate_output="$(python3 "$ROOT/tools/revamp/state.py" gate --repo-root "$repo" --date 2026-04-30 --rerun-mode resume)"
[[ "$gate_output" == "sh tests/run.sh" ]] || fail "revamp state: gate must print validationCommands"
python3 - "$state" <<'PY' || fail "revamp state: gate must persist active stage"
import json
import sys
data = json.load(open(sys.argv[1]))
assert data["activeStage"] == "gate"
PY

echo "PASS: revamp state helper validates narrative state flows"
