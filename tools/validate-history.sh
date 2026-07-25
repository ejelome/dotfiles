#!/usr/bin/env bash
# Validate the calendar-dated project record used by local and hosted gates.
set -euo pipefail

fail() {
  printf 'validate-history: %s\n' "$*" >&2
  exit 1
}

root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

changelog="CHANGELOG.md"
tag_namespace="${DOTFILES_TAG_NAMESPACE:-refs/tags}"
tag_namespace="${tag_namespace%/}"

[[ -f "$changelog" ]] || fail "missing $changelog"

unreleased_count="$(
  awk '$0 == "## [Unreleased]" { count++ } END { print count + 0 }' "$changelog"
)"
[[ "$unreleased_count" -eq 1 ]] ||
  fail "[Unreleased] must occur exactly once"

awk '
  $0 == "## [Unreleased]" { active = 1; next }
  active && /^## \[/ { found_release = 1; exit }
  active && NF { exit 1 }
  END { if (!found_release) exit 1 }
' "$changelog" || fail "[Unreleased] must be newest and empty"

roots_file="$(mktemp)"
commits_file="$(mktemp)"
dates_file="$(mktemp)"
expected_refs_file="$(mktemp)"
actual_refs_file="$(mktemp)"
actual_dates_file="$(mktemp)"
body_file="$(mktemp)"
section_file="$(mktemp)"
trap 'rm -f "$roots_file" "$commits_file" "$dates_file" \
  "$expected_refs_file" "$actual_refs_file" "$actual_dates_file" \
  "$body_file" "$section_file"' EXIT

git rev-list --max-parents=0 HEAD >"$roots_file"
[[ "$(wc -l <"$roots_file" | tr -d ' ')" -eq 1 ]] ||
  fail "history must contain exactly one root"
root_commit="$(sed -n '1p' "$roots_file")"

[[ -z "$(git rev-list --min-parents=2 HEAD)" ]] ||
  fail "history must be linear"
[[ -z "$(git for-each-ref --points-at="$root_commit" \
  --format='%(refname)' "$tag_namespace")" ]] ||
  fail "the initial commit must remain untagged"

git rev-list --reverse "$root_commit..HEAD" >"$commits_file"
[[ -s "$commits_file" ]] || fail "history has no dated project records"

previous_date=""
latest_tag=""
while IFS= read -r commit_oid; do
  commit_date="$(git show -s --format='%cI' "$commit_oid" | cut -c1-10)"
  [[ "$commit_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
    fail "invalid committer date on $commit_oid"
  [[ "$commit_date" != "$previous_date" ]] ||
    fail "multiple project records share $commit_date"
  previous_date="$commit_date"
  printf '%s\n' "$commit_date" >>"$dates_file"

  dotted_date="$(printf '%s' "$commit_date" | tr '-' '.')"
  tag_name="v$dotted_date"
  tag_ref="$tag_namespace/$tag_name"
  latest_tag="$tag_name"
  printf '%s\n' "$tag_ref" >>"$expected_refs_file"

  [[ "$(git cat-file -t "$tag_ref" 2>/dev/null || true)" == "tag" ]] ||
    fail "$tag_name must be an annotated tag"
  [[ "$(git rev-parse "$tag_ref^{}")" == "$commit_oid" ]] ||
    fail "$tag_name points to the wrong project record"
  tag_message="$(git for-each-ref --format='%(contents)' "$tag_ref")"
  tag_subject="${tag_message%%$'\n'*}"
  tag_body="${tag_message#*$'\n\n'}"
  [[ "$tag_message" == "$tag_subject"$'\n\n'"$tag_body" ]] ||
    fail "$tag_name annotation must separate subject and body once"
  [[ "$tag_subject" != *$'\n'* && "$tag_body" != *$'\n'* ]] ||
    fail "$tag_name annotation body must be one paragraph"
  [[ "${#tag_subject}" -le 64 ]] ||
    fail "$tag_name annotation subject exceeds 64 characters"
  [[ "$tag_subject" =~ ^[^.!?]+[.!?]$ ]] ||
    fail "$tag_name annotation subject must be one sentence"
  [[ "$tag_body" =~ ^[^.!?]+[.!?]([[:space:]][^.!?]+[.!?]){2,4}$ ]] ||
    fail "$tag_name annotation body must contain three to five sentences"

  read -r footprint_files footprint_insertions footprint_deletions < <(
    git diff-tree --no-commit-id --numstat -r "$commit_oid" |
      awk '{
        files++
        if ($1 ~ /^[0-9]+$/) insertions += $1
        if ($2 ~ /^[0-9]+$/) deletions += $2
      }
      END { print files + 0, insertions + 0, deletions + 0 }'
  )
  file_word=files
  insertion_word=insertions
  deletion_word=deletions
  [[ "$footprint_files" -ne 1 ]] || file_word="file"
  [[ "$footprint_insertions" -ne 1 ]] || insertion_word="insertion"
  [[ "$footprint_deletions" -ne 1 ]] || deletion_word="deletion"
  expected_footprint="The project footprint is $footprint_files $file_word"
  expected_footprint+=" changed, with $footprint_insertions $insertion_word"
  expected_footprint+=" and $footprint_deletions $deletion_word."
  [[ "$tag_body" == *"$expected_footprint" ]] ||
    fail "$tag_name annotation has the wrong project footprint"

  pointed_refs="$(
    git for-each-ref --points-at="$commit_oid" --format='%(refname)' \
      "$tag_namespace"
  )"
  [[ "$pointed_refs" == "$tag_ref" ]] ||
    fail "$commit_date must have exactly one calendar tag"

  subject="$(git show -s --format='%s' "$commit_oid")"
  [[ "${#subject}" -le 72 ]] || fail "subject exceeds 72 characters"
  [[ "$subject" =~ ^[a-z]+\([a-z0-9._/-]+\):[[:space:]][a-z0-9] ]] ||
    fail "subject is not a scoped Conventional Commit"

  git show -s --format='%b' "$commit_oid" >"$body_file"
  awk '
    function heading_rank(line) {
      if (line == "Added:") return 1
      if (line == "Changed:") return 2
      if (line == "Deprecated:") return 3
      if (line == "Removed:") return 4
      if (line == "Fixed:") return 5
      if (line == "Security:") return 6
      return 0
    }
    BEGIN { current = 0; bullets = 0 }
    !NF { next }
    {
      rank = heading_rank($0)
      if (rank) {
        if (rank <= current) exit 1
        current = rank
        next
      }
      if ($0 ~ /^- /) {
        if (!current || length($0) > 72 || $0 !~ /\.$/) exit 1
        bullets++
        next
      }
      exit 1
    }
    END { if (!bullets) exit 1 }
  ' "$body_file" || fail "invalid structured body on $commit_date"

  if LC_ALL=C grep -Eiq \
    '(^|[^[:alnum:]_])(git|github|commit|tag|branch|ref|history|release|version|publication|agent|prompt)([^[:alnum:]_]|$)|v?[0-9]+\.[0-9]+\.[0-9]+' \
    <(
      printf '%s\n%s\n%s\n' "$subject" "$tag_subject" "$tag_body"
      cat "$body_file"
    ); then
    fail "project wording gate failed on $commit_date"
  fi

  release_heading="## [$commit_date] - $commit_date"
  [[ "$(grep -Fxc "$release_heading" "$changelog")" -eq 1 ]] ||
    fail "missing or duplicate changelog section for $commit_date"
  awk -v heading="$release_heading" '
    $0 == heading { active = 1; next }
    active && /^## \[/ { exit }
    active { print }
  ' "$changelog" >"$section_file"

  while IFS= read -r bullet; do
    [[ "${#bullet}" -le 72 ]] ||
      fail "changelog bullet exceeds 72 characters on $commit_date"
    grep -Fqx -- "$bullet" "$body_file" ||
      fail "changelog bullet is absent from the matching body"
  done < <(grep '^- ' "$section_file")

  grep -Fq "[$commit_date]:" "$changelog" ||
    fail "missing changelog link for $commit_date"
done <"$commits_file"

git for-each-ref --format='%(refname)' "$tag_namespace" |
  LC_ALL=C sort >"$actual_refs_file"
LC_ALL=C sort "$expected_refs_file" -o "$expected_refs_file"
cmp -s "$expected_refs_file" "$actual_refs_file" ||
  fail "calendar tag inventory does not match project records"

grep '^## \[20' "$changelog" |
  sed -E 's/^## \[([0-9-]+)\] - .*/\1/' >"$actual_dates_file"
awk '{ values[NR] = $0 } END { for (i = NR; i >= 1; i--) print values[i] }' \
  "$dates_file" | cmp -s - "$actual_dates_file" ||
  fail "changelog dates do not match project records"

grep -Fq "Current release: [$latest_tag]" README.md ||
  fail "README does not name the current calendar tag"

printf 'validate-history: PASS (%s records, latest %s)\n' \
  "$(wc -l <"$commits_file" | tr -d ' ')" "$latest_tag"
