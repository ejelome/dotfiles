#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

dir="$ROOT/cursor/_functions/collab"

# Reject step labels matching the pattern ^[0-9]+[a-z] (e.g. "4a."), which
# creates parsing ambiguity. Sub-steps must use decimal notation (4.1, 4.2).
found=0
while IFS= read -r -d '' file; do
  if grep -En '^[[:space:]]*[0-9]+[a-z]\.' "$file" 2>/dev/null; then
    echo "FAIL: alphanumeric step label in $file"
    found=1
  fi
done < <(find "$dir" -name '*.md' -print0)

[ "$found" -eq 0 ] || fail "One or more collab function files contain alphanumeric step labels (e.g. '4a.'). Use consecutive integers or decimal sub-steps (4.1, 4.2)."

echo "PASS: collab function files use consecutive integer step labels"
