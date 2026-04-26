#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/README.md"
golden="$ROOT/tests/README.md/README.md.golden"

diff -u "$golden" "$file" || fail "README.md: does not match golden file"

python3 - "$file" <<'PY' || fail "README.md: opening description must be <=80 characters"
import sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
for index, line in enumerate(lines):
    if line == "# dotfiles":
        for candidate in lines[index + 1:]:
            if candidate and not candidate.startswith("!["):
                if len(candidate) > 80:
                    raise SystemExit(1)
                raise SystemExit(0)
raise SystemExit(1)
PY

echo "PASS: README.md matches the /docs readme contract shape"
