#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

if grep -En '(\$HOME/\.cursor|~/\.cursor|[[:space:]"'\'']\.cursor/|cp[[:space:]].*\.cursor|rsync[[:space:]].*\.cursor)' "$ROOT/link.sh" >/tmp/link-dotcursor-runtime.txt; then
  output="$(cat /tmp/link-dotcursor-runtime.txt)"
  rm -f /tmp/link-dotcursor-runtime.txt
  fail "link.sh must not write/copy/sync into ~/.cursor: $output"
fi
rm -f /tmp/link-dotcursor-runtime.txt

echo "PASS: link.sh does not write dotcursor runtime"
