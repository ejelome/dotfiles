#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/cursor/_core" "$work/cursor/commands" "$work/cursor/_functions/collab" "$work/cursor/_functions/test" "$work/tools/collab"

cat >"$work/cursor/_core/command-convention.md" <<'EOF'
# Naming

| Operation class | Canonical form |
|---|---|
| Rewrite last authored artifact | `rewrite <target>` |
| Speak contribution | `speak` |
EOF

cat >"$work/cursor/commands/collab.md" <<'EOF'
# /collab

**Slash:** `/collab`
EOF

cat >"$work/cursor/_functions/collab/rewrite-speak.md" <<'EOF'
# /collab rewrite speak

**Slash:** `/collab rewrite speak`
EOF

cat >"$work/cursor/_functions/collab/_shared-doc.md" <<'EOF'
# Shared collab doc

**Slash:** (reference only — not an invocable route)
EOF

cat >"$work/cursor/_functions/test/run.md" <<'EOF'
# /test

**Slash:** `/test`
EOF

cat >"$work/tools/collab/registry.py" <<'EOF'
def build_parser():
    subparsers.add_parser('rewrite-speak-render')
EOF

python3 "$ROOT/tools/check-cursor-naming.py" --root "$work" >/dev/null

cat >"$work/cursor/_functions/collab/re-speak.md" <<'EOF'
# /collab re-speak

**Slash:** `/collab re-speak`
EOF

if python3 "$ROOT/tools/check-cursor-naming.py" --root "$work" >"$work/out" 2>&1; then
  fail "check-cursor-naming.py: re-* route must fail"
fi
assert_contains "$(cat "$work/out")" "re-* route filenames are retired"

echo "PASS: check-cursor-naming.py validates command names"
