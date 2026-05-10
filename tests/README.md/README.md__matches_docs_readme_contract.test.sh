#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/README.md"
readme="$(<"$file")"

for heading in Overview Setup Usage Structure Links Status; do
  assert_contains "$readme" "## $heading"
done

assert_contains "$readme" "This repository is the source of truth"
assert_contains "$readme" "REPOSITORY.md"
assert_contains "$readme" "SKIP_TESTS_RUN=1 ./tools/smoke-check.sh"
assert_contains "$readme" "./tests/run.sh"

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

python3 - "$ROOT" "$file" <<'PY' || fail "README.md: generated TOC and relative links must match committed artifact"
import os
import re
import sys

root, path = sys.argv[1:]
text = open(path, encoding="utf-8").read()
lines = text.splitlines()

headings = [line[3:] for line in lines if line.startswith("## ")]
toc_entries = []
in_toc = False
for line in lines:
    if line == "**Table of contents**":
        in_toc = True
        continue
    if in_toc and line == "---":
        break
    if in_toc and line.startswith("- ["):
        toc_entries.append(re.sub(r"^- \[(.*)\]\(#.*\)$", r"\1", line))
if toc_entries != headings:
    raise SystemExit(1)

for target in re.findall(r"!??\[[^\]]*\]\(([^)]+)\)", text):
    if "://" in target or target.startswith("#"):
        continue
    target = target.split("#", 1)[0]
    if not target:
        continue
    if not os.path.exists(os.path.join(root, target)):
        raise SystemExit(1)
PY

echo "PASS: README.md matches targeted generated-artifact checks"
