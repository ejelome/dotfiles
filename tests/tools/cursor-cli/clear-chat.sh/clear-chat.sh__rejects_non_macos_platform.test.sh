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

mockbin="$tmp/mockbin"
mkdir -p "$mockbin"

cat > "$mockbin/uname" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "Linux"
SH
chmod +x "$mockbin/uname"

set +e
output="$(
  PATH="$mockbin:$PATH" \
  "$ROOT/tools/cursor-cli/clear-chat.sh" 2>&1
)"
status=$?
set -e

[[ $status -ne 0 ]] || fail "clear-chat.sh should fail for non-macOS platforms"
assert_contains "$output" "--cursor target requires macOS"

echo "PASS: clear-chat rejects non-macOS platform"
