#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT

tests=()
while IFS= read -r t; do
  tests+=("$t")
done < <(find "$ROOT/tests" -type f -name '*.test.sh' | sort)

if ((${#tests[@]} == 0)); then
  echo "tests: no test files found"
  exit 1
fi

pass=0
fail=0

for t in "${tests[@]}"; do
  rel="${t#"$ROOT"/}"
  echo "tests: RUN $rel"
  if bash "$t"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "tests: FAIL $rel"
  fi
done

echo "tests: summary pass=$pass fail=$fail total=${#tests[@]}"
((fail == 0))
