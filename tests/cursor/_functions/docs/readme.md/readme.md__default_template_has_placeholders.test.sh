#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/_functions/docs/readme.md"

grep -Fq "OWNER/REPO" "$file" || fail "readme.md: Default README template missing OWNER/REPO placeholder"
grep -Fq 'Required for the repository root **`README.md`** in this workspace' "$file" || fail "readme.md: missing root README required TOC rule"
grep -Fq '≤80 characters if one line' "$file" || fail "readme.md: missing README brief description limit"
grep -Fq '### Description standards' "$file" || fail "readme.md: missing description standards section"
grep -Fq 'Prefer 50-100 characters when package metadata is in scope.' "$file" || fail "readme.md: missing package registry summary guidance"
grep -Fq 'Prefer one sentence; use two short sentences only when needed.' "$file" || fail "readme.md: missing README opening paragraph guidance"
grep -Fq 'GitHub allows 350 characters, but prefer fewer than 120.' "$file" || fail "readme.md: missing GitHub description guidance"
grep -Fq 'long mission statements, implementation details, setup instructions, and marketing fluff' "$file" || fail "readme.md: missing README description avoid-list"
grep -Fq 'Dotfiles for shell, Git, Cursor, and local development workflows.' "$file" || fail "readme.md: Default README template missing refined opening line"
grep -Fq -- '- `launcher/` — Cursor workspace launcher setup scripts' "$file" || fail "readme.md: Default README template missing launcher structure entry"
grep -Fq '`link.sh` is the supported way to project this repository’s shell and Cursor configuration.' "$file" || fail "readme.md: Default README template missing refined status line"

python3 - "$file" <<'PY' || fail "readme.md: Default README template TOC must be wrapped with --- before and after"
import sys

text = open(sys.argv[1], encoding="utf-8").read()
expected = """---

**Table of contents**

- [Overview](#overview)
- [Setup](#setup)
- [Usage](#usage)
- [Structure](#structure)
- [Links](#links)
- [Status](#status)

---"""

if expected not in text:
    raise SystemExit(1)
PY

python3 - "$file" <<'PY' || fail "readme.md: Default README template opening line must be <=80 characters"
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

echo "PASS: readme.md default template has OWNER/REPO placeholder"
