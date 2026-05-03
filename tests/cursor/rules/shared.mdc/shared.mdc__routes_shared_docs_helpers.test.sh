#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
# shellcheck source=tests/helpers/assert.sh
source "$ROOT/tests/helpers/assert.sh"

file="$ROOT/cursor/rules/shared.mdc"

grep -Fq "Contract: [shared-cmd-eval](../_mdc/shared/shared-cmd-eval.mdc), [shared-cmd-values](../_mdc/shared/shared-cmd-values.mdc), [shared-docs-precedence](../_mdc/shared/shared-docs-precedence.mdc), [shared-docs-rules](../_mdc/shared/shared-docs-rules.mdc), [shared-docs-toc](../_mdc/shared/shared-docs-toc.mdc), [shared-docs-voice](../_mdc/shared/shared-docs-voice.mdc), [shared-git-commits](../_mdc/shared/shared-git-commits.mdc)" "$file" || fail "shared.mdc: missing shared docs contract"
grep -Fq "\`shared-cmd-eval.mdc\`" "$file" || fail "shared.mdc: missing shared-cmd-eval route"
grep -Fq "\`shared-cmd-values.mdc\`" "$file" || fail "shared.mdc: missing shared-cmd-values route"
grep -Fq "\`shared-docs-precedence.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-precedence route"
grep -Fq "\`shared-docs-rules.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-rules route"
grep -Fq "\`shared-docs-toc.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-toc route"
grep -Fq "\`shared-docs-voice.mdc\`" "$file" || fail "shared.mdc: missing shared-docs-voice route"
grep -Fq "\`shared-git-commits.mdc\`" "$file" || fail "shared.mdc: missing shared-git-commits route"

echo "PASS: shared.mdc routes the shared docs helpers"
