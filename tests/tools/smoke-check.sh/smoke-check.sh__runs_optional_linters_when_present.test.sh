#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

mockbin="$tmp/mockbin"
shellcheck_log="$tmp/shellcheck.log"
markdownlint_log="$tmp/markdownlint.log"
mkdir -p "$mockbin"

cat > "$mockbin/shellcheck" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${MOCK_SHELLCHECK_LOG:?}"
echo "$*" >> "$MOCK_SHELLCHECK_LOG"
SH

cat > "$mockbin/markdownlint" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${MOCK_MARKDOWNLINT_LOG:?}"
echo "$*" >> "$MOCK_MARKDOWNLINT_LOG"
SH

chmod +x "$mockbin/shellcheck" "$mockbin/markdownlint"

output="$({
  SKIP_TESTS_RUN=1 \
  PYTHONPYCACHEPREFIX="$tmp/pycache" \
  MOCK_SHELLCHECK_LOG="$shellcheck_log" \
  MOCK_MARKDOWNLINT_LOG="$markdownlint_log" \
  PATH="$mockbin:$PATH" \
  "$ROOT/tools/smoke-check.sh"
} 2>&1)"

assert_contains "$output" "smoke-check: shellcheck …"
assert_contains "$output" "smoke-check: markdownlint …"

shellcheck_text="$(cat "$shellcheck_log")"
assert_contains "$shellcheck_text" "$ROOT/link.sh"
assert_contains "$shellcheck_text" "$ROOT/tools/smoke-check.sh"

markdownlint_text="$(cat "$markdownlint_log")"
assert_contains "$markdownlint_text" "README.md"
assert_contains "$markdownlint_text" "AGENTS.md"

echo "PASS: smoke-check runs optional linters when present"
