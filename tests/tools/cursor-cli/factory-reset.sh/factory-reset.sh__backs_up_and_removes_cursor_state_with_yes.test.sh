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

cat > "$mockbin/date" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "20260101-010101"
SH

cat > "$mockbin/ditto" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
src="$1"
dest="$2"
if [[ -d "$src" ]]; then
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/ 2>/dev/null || true
elif [[ -f "$src" || -L "$src" ]]; then
  if [[ -d "$dest" ]]; then
    cp -R "$src" "$dest/"
  else
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
  fi
fi
SH

chmod +x "$mockbin/pgrep" "$mockbin/date" "$mockbin/ditto"

bundle_id="com.todesktop.230313mzl4w4u92"
app_support="$home/Library/Application Support/Cursor"
dot_cursor="$home/.cursor"
pref_plist="$home/Library/Preferences/$bundle_id.plist"
cache_one="$home/Library/Caches/$bundle_id"
cache_two="$home/Library/Caches/$bundle_id.ShipIt"
saved_state="$home/Library/Saved Application State/$bundle_id.savedState"

mkdir -p "$app_support" "$dot_cursor" "$(dirname "$pref_plist")" "$cache_one" "$cache_two" "$saved_state"
printf 'app\n' > "$app_support/data.txt"
printf 'cursor\n' > "$dot_cursor/data.txt"
printf 'plist\n' > "$pref_plist"
printf 'cache\n' > "$cache_one/cache.txt"
printf 'shipit\n' > "$cache_two/cache.txt"

output="$({
  HOME="$home" \
  PATH="$mockbin:$PATH" \
  "$ROOT/tools/cursor-cli/factory-reset.sh" --yes
} 2>&1)"

backup_dir="$home/Desktop/cursor-factory-reset-backup-20260101-010101"
assert_exists "$backup_dir/Application Support/Cursor/data.txt"
assert_exists "$backup_dir/dot-cursor/data.txt"
assert_exists "$backup_dir/$bundle_id.plist"
assert_exists "$backup_dir/Caches/$bundle_id/cache.txt"
assert_exists "$backup_dir/Caches/$bundle_id.ShipIt/cache.txt"

assert_not_exists "$app_support"
assert_not_exists "$dot_cursor"
assert_not_exists "$pref_plist"
assert_not_exists "$cache_one"
assert_not_exists "$cache_two"
assert_not_exists "$saved_state"

assert_contains "$output" "Backup copy: $backup_dir"

echo "PASS: factory-reset backs up and removes cursor state with --yes"
