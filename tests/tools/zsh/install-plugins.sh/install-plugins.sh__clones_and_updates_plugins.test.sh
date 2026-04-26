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

plugins_dir="$tmp/plugins"
mockbin="$tmp/mockbin"
git_log="$tmp/git.log"
mkdir -p "$plugins_dir/zsh-autosuggestions/.git" "$mockbin"

cat > "$mockbin/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${MOCK_GIT_LOG:?}"
echo "$*" >> "$MOCK_GIT_LOG"
if [[ "${1:-}" == "-C" ]]; then
  exit 0
fi
if [[ "${1:-}" == "clone" ]]; then
  dest="${@: -1}"
  mkdir -p "$dest/.git"
  exit 0
fi
exit 0
SH
chmod +x "$mockbin/git"

output="$({
  PATH="$mockbin:$PATH" \
  MOCK_GIT_LOG="$git_log" \
  ZSH_PLUGINS_DIR="$plugins_dir" \
  "$ROOT/tools/zsh/install-plugins.sh"
} 2>&1)"

assert_exists "$plugins_dir/zsh-autosuggestions/.git"
assert_exists "$plugins_dir/zsh-syntax-highlighting/.git"
assert_contains "$output" "update zsh-autosuggestions"
assert_contains "$output" "clone zsh-syntax-highlighting"
assert_contains "$output" "install-zsh-plugins: done"

log_text="$(cat "$git_log")"
assert_contains "$log_text" "-C $plugins_dir/zsh-autosuggestions pull --ff-only"
assert_contains "$log_text" "clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting $plugins_dir/zsh-syntax-highlighting"

echo "PASS: install-plugins clones and updates plugins"
