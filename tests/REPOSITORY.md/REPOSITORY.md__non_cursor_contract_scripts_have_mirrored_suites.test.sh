#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

required_sources=(
  "link.sh"
  "launcher/setup-cursor-workspace-launcher.sh"
  "tools/check-agent-adapters.sh"
  "tools/check-cursor-content.sh"
  "tools/cursor-cli/clear-chat.sh"
  "tools/cursor-cli/factory-reset.sh"
  "tools/cursor/sync-commands-catalog.sh"
  "tools/lib/cursor-layout.sh"
  "tools/lib/link-targets.sh"
  "tools/manual/manual-link-fallback.sh"
  "tools/smoke-check.sh"
  "tools/zsh/install-plugins.sh"
)

for source_path in "${required_sources[@]}"; do
  suite_dir="$ROOT/tests/$source_path"
  [[ -d "$suite_dir" ]] || fail "missing mirrored test suite directory: tests/${source_path}/"

  count="$(find "$suite_dir" -maxdepth 1 -type f -name '*.test.sh' | wc -l | tr -d ' ')"
  (( count > 0 )) || fail "missing *.test.sh coverage in: tests/${source_path}/"
done

echo "PASS: non-cursor contract scripts have mirrored test suites"
