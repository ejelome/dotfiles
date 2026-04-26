#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

home="$tmp/home"
mockbin="$tmp/mockbin"
mkdir -p "$home" "$mockbin"

cat > "$mockbin/pgrep" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exit 1
SH
chmod +x "$mockbin/pgrep"

output="$({
  HOME="$home" \
  PATH="$mockbin:$PATH" \
  "$ROOT/tools/cursor-cli/factory-reset.sh"
} 2>&1)"

assert_contains "$output" "Cursor factory reset (macOS)"
assert_contains "$output" "To proceed:"
assert_contains "$output" "--yes"

echo "PASS: factory-reset shows preview without --yes"
