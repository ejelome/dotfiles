#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_CONFIG_ROOT="${CURSOR_CONFIG_ROOT:-$ROOT}"

die() {
  echo "check-cursor-content: $*" >&2
  exit 1
}

relpath() {
  local path="$1"
  if [[ "$path" == "$ROOT/"* ]]; then
    printf '%s\n' "${path#"$ROOT"/}"
  else
    printf '%s\n' "$path"
  fi
}

cursor_source_key() {
  local path="$1"
  if [[ "$path" == "$CURSOR_CONFIG_ROOT/"* ]]; then
    printf 'cursor/%s\n' "${path#"$CURSOR_CONFIG_ROOT"/}"
  else
    relpath "$path"
  fi
}

h1_count_without_fences() {
  local file="$1"
  awk '
    BEGIN { in_fence = 0; count = 0 }
    /^```/ || /^~~~/ { in_fence = !in_fence; next }
    !in_fence && /^# / { count++ }
    END { print count }
  ' "$file"
}

section_line() {
  local file="$1" heading="$2" out count line
  out="$(grep -n "^## ${heading}\$" "$file" || true)"
  count="$(printf '%s\n' "$out" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || die "$(relpath "$file"): expected exactly one '## ${heading}' heading"
  line="${out%%:*}"
  printf '%s\n' "$line"
}

# trigger_contract_allowlisted: built in 2026-05-10-audit-agent-namespace-and-its-commands-and-flags;
# zeroed in 2026-05-10-migrate-remaining-trigger-contract-and-add-catalog-note-harness.
# Successor contract: the checker rejects **Phrases:** in any route or function file;
# invocation-note substring coverage is enforced by the catalog-note harness.
trigger_contract_allowlisted() {
  case "$1" in
    *)
      return 1
      ;;
  esac
}

trigger_block() {
  local file="$1"
  awk '
    /^## Trigger$/ { in_trigger = 1; next }
    /^## Steps$/ { in_trigger = 0 }
    in_trigger { print NR ":" $0 }
  ' "$file"
}

first_trigger_label_line() {
  local file="$1" pattern="$2"
  trigger_block "$file" | grep -E "$pattern" | head -n 1 | cut -d: -f1
}

trigger_label_count() {
  local file="$1" pattern="$2"
  trigger_block "$file" | grep -Ec "$pattern" || true
}

check_trigger_contract() {
  local file="$1" rel key slash_count prose_count search_count slash_line prose_line search_line signature_quote_line
  rel="$(relpath "$file")"
  key="$(cursor_source_key "$file")"

  [[ "$key" == "cursor/commands/commands.md" ]] && return 0
  trigger_contract_allowlisted "$key" && return 0

  slash_count="$(trigger_label_count "$file" '^[0-9]+:\*\*Slash:\*\*')"
  prose_count="$(trigger_label_count "$file" '^[0-9]+:\*\*Prose dispatch:\*\*')"
  search_count="$(trigger_label_count "$file" '^[0-9]+:\*\*Search phrases([^*]*)?:\*\*')"

  [[ "$slash_count" == "1" ]] || die "${rel}: trigger contract expected exactly one '**Slash:**' line"
  [[ "$prose_count" == "1" ]] || die "${rel}: trigger contract expected exactly one '**Prose dispatch:**' line"
  [[ "$search_count" == "1" ]] || die "${rel}: trigger contract expected exactly one '**Search phrases:**' line"

  trigger_block "$file" | grep -Eq '^[0-9]+:\*\*Phrases:\*\*' && die "${rel}: trigger contract uses old '**Phrases:**'; use '**Search phrases:**'"

  slash_line="$(first_trigger_label_line "$file" '^[0-9]+:\*\*Slash:\*\*')"
  prose_line="$(first_trigger_label_line "$file" '^[0-9]+:\*\*Prose dispatch:\*\*')"
  search_line="$(first_trigger_label_line "$file" '^[0-9]+:\*\*Search phrases([^*]*)?:\*\*')"
  (( slash_line < prose_line && prose_line < search_line )) || die "${rel}: trigger contract section order must be Slash -> Prose dispatch -> Search phrases"

  # shellcheck disable=SC2016
  trigger_block "$file" | grep -E '^[0-9]+:\*\*Slash:\*\*' | grep -Eq '`/[^`]+`|\(reference only' || die "${rel}: '**Slash:**' must declare a slash invocation or reference-only exemption"
  # shellcheck disable=SC2016
  trigger_block "$file" | grep -E '^[0-9]+:\*\*Prose dispatch:\*\*' | grep -Eq '`\([^`]+\)`|\(reference only' || die "${rel}: '**Prose dispatch:**' must declare a prose dispatch form or reference-only exemption"
  # shellcheck disable=SC2016
  trigger_block "$file" | grep -E '^[0-9]+:\*\*Search phrases([^*]*)?:\*\*' | grep -Eq '`/[^`]+`|`\([^`]+\)`' && die "${rel}: Search phrases must not contain invocable slash or prose forms"

  signature_quote_line="$(trigger_block "$file" | grep -E '^[0-9]+:\*\*(Slash|Signature|Prose dispatch):\*\*' | grep "'" || true)"
  [[ -z "$signature_quote_line" ]] || die "${rel}: invalid quote: single quotes are not a valid wrapper; use double quotes"
}

check_trigger_invocation_uniqueness() {
  local tmp duplicate
  tmp="$(mktemp)"

  while IFS= read -r file; do
    local key
    key="$(cursor_source_key "$file")"
    [[ "$key" == "cursor/commands/commands.md" ]] && continue
    trigger_contract_allowlisted "$key" && continue
    trigger_block "$file" | awk -v rel="$key" '
      /^[0-9]+:\*\*(Slash|Prose dispatch):\*\*/ && $0 !~ /\(reference only/ {
        line = $0
        while (match(line, /`[^`]+`/)) {
          value = substr(line, RSTART + 1, RLENGTH - 2)
          print value "\t" rel
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' >>"$tmp"
  done < <(
    find "$CURSOR_CONFIG_ROOT/commands" -maxdepth 1 -type f -name '*.md' | sort
    find "$CURSOR_CONFIG_ROOT/_functions" -type f -name '*.md' | sort
  )

  duplicate="$(
    awk -F '\t' '
      function duplicate_allowed(value, paths) {
        if (paths != "cursor/commands/test.md, cursor/_functions/test/run.md") {
          return 0
        }
        return value == "/test" || value == "(test <commands | rules | _functions | _mdc | _core | _roles | _settings | repo | all>)"
      }
      {
        count[$1]++
        paths[$1] = paths[$1] ? paths[$1] ", " $2 : $2
      }
      END {
        for (value in count) {
          if (count[value] > 1 && !duplicate_allowed(value, paths[value])) {
            print "'"'"'" value "'"'"' appears in " paths[value]
            exit 0
          }
        }
      }
    ' "$tmp"
  )"
  rm -f "$tmp"
  [[ -z "$duplicate" ]] || die "trigger invocable duplicate: ${duplicate}"
}

prose_dispatch_allowed_context() {
  local lower="$1"
  case "$lower" in
    *routing-only*|*reference-only*|*documentation-only*|*not\ terminal-executable*|*not\ an\ invocable\ route*|*non-invocable*|*must\ not\ be\ copied*|*must\ not\ be\ treated*|*never\ treat*|*do\ not\ treat*|*not\ promoted*|*not\ lift*|*halt*)
      return 0
      ;;
  esac
  return 1
}

check_prose_dispatch_framing_file() {
  local file="$1" rel line_number text lower
  rel="$(relpath "$file")"

  line_number=0
  while IFS= read -r text || [[ -n "$text" ]]; do
    line_number=$((line_number + 1))
    lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

    if [[ "$lower" == *"prose dispatch"* ]] && [[ "$lower" =~ (^|[^[:alnum:]_-])(run|runs|running|execute|executes|executed|executable|invoke|invokes|invoked|invocation|invocable)([^[:alnum:]_-]|$)|copyable[[:space:]]+directly ]]; then
      prose_dispatch_allowed_context "$lower" || die "${rel}:${line_number}: prose dispatch direct-execution wording needs a routing-only/reference-only qualifier"
    fi

    # shellcheck disable=SC2016
    if grep -Eq '`\((agent|collab|doc|quality|git|narrative|test)[[:space:]][^`]*\)`.*`/[^`]+`|`/[^`]+`.*`\((agent|collab|doc|quality|git|narrative|test)[[:space:]][^`]*\)`' <<<"$text"; then
      prose_dispatch_allowed_context "$lower" || die "${rel}:${line_number}: parenthetical and slash command examples need an explicit routing-only label"
    fi

    if grep -Eq '\(collab speak [A-Za-z][^)]*\)' <<<"$text"; then
      prose_dispatch_allowed_context "$lower" || die "${rel}:${line_number}: collab speak prose dispatch must not treat argument text as contribution content"
    fi
  done < "$file"
}

check_prose_dispatch_framing() {
  local candidates=(
    "$ROOT/AGENTS.md"
    "$ROOT/CLAUDE.md"
    "$CURSOR_CONFIG_ROOT/_templates/AGENTS.md"
    "$CURSOR_CONFIG_ROOT/_core/command-standard.md"
    "$CURSOR_CONFIG_ROOT/_generated/command-reference.md"
  )
  local path

  for path in "${candidates[@]}"; do
    [[ -f "$path" ]] && check_prose_dispatch_framing_file "$path"
  done

  while IFS= read -r path; do
    check_prose_dispatch_framing_file "$path"
  done < <(
    find "$CURSOR_CONFIG_ROOT/commands" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort
    find "$CURSOR_CONFIG_ROOT/_functions" -type f -name '*.md' 2>/dev/null | sort
  )
}

check_line_budget() {
  local file lines
  while IFS= read -r file; do
    lines="$(wc -l < "$file" | tr -d ' ')"
    (( lines <= 250 )) || die "$(relpath "$file"): exceeds 250-line budget (${lines})"
  done < <(find "$CURSOR_CONFIG_ROOT" -type f \( -name '*.md' -o -name '*.mdc' \) | sort)
}

check_command_shapes() {
  local file h1_count trigger_line steps_line notes_line
  while IFS= read -r file; do
    h1_count="$(h1_count_without_fences "$file")"
    [[ "$h1_count" == "1" ]] || die "$(relpath "$file"): expected exactly one H1 outside code fences"

    trigger_line="$(section_line "$file" "Trigger")"
    steps_line="$(section_line "$file" "Steps")"
    notes_line="$(section_line "$file" "Notes")"
    (( trigger_line < steps_line && steps_line < notes_line )) || die "$(relpath "$file"): section order must be Trigger -> Steps -> Notes"
    check_trigger_contract "$file"
  done < <(
    find "$CURSOR_CONFIG_ROOT/commands" -maxdepth 1 -type f -name '*.md' | sort
    find "$CURSOR_CONFIG_ROOT/_functions" -type f -name '*.md' | sort
  )

  check_trigger_invocation_uniqueness
}

check_rule_shapes() {
  local file front_matter h1_count
  while IFS= read -r file; do
    [[ "$(head -n 1 "$file")" == "---" ]] || die "$(relpath "$file"): missing YAML front matter start ('---')"

    front_matter="$(
      awk '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm { print }
      ' "$file"
    )"
    [[ -n "$front_matter" ]] || die "$(relpath "$file"): missing YAML front matter body"
    grep -Eq '^description:' <<<"$front_matter" || die "$(relpath "$file"): front matter must include description"
    grep -Eq '^alwaysApply:' <<<"$front_matter" || die "$(relpath "$file"): front matter must include alwaysApply"

    h1_count="$(h1_count_without_fences "$file")"
    [[ "$h1_count" == "1" ]] || die "$(relpath "$file"): expected exactly one H1 outside code fences"
    grep -Fq '**Triggers:**' "$file" || die "$(relpath "$file"): missing '**Triggers:**' line"
  done < <(
    find "$CURSOR_CONFIG_ROOT/rules" -maxdepth 1 -type f -name '*.mdc' | sort
    find "$CURSOR_CONFIG_ROOT/_mdc" -type f -name '*.mdc' | sort
  )
}

check_content_invariants() {
  local invariants_file invariants_rel line_number source_rel name needle file
  invariants_file="${CURSOR_CONTENT_INVARIANTS_FILE:-$CURSOR_CONFIG_ROOT/_generated/content-invariants.tsv}"
  [[ -f "$invariants_file" ]] || return 0
  invariants_rel="$(relpath "$invariants_file")"

  line_number=0
  while IFS=$'\t' read -r source_rel name needle; do
    line_number=$((line_number + 1))
    [[ -n "${source_rel}${name}${needle}" ]] || continue
    [[ "$source_rel" == \#* ]] && continue
    [[ -n "$source_rel" && -n "$name" && -n "$needle" ]] || die "${invariants_rel}: malformed invariant at line ${line_number}"

    case "$source_rel" in
      cursor/*)
        file="$CURSOR_CONFIG_ROOT/${source_rel#cursor/}"
        ;;
      *)
        file="$ROOT/$source_rel"
        ;;
    esac

    [[ -f "$file" ]] || die "${invariants_rel}: invariant ${name} targets missing file ${source_rel}"
    grep -Fq -- "$needle" "$file" || die "$(relpath "$file"): missing content invariant ${name}"
  done < "$invariants_file"
}

require_contains() {
  local file="$1" needle="$2" message="$3"
  grep -Fq -- "$needle" "$file" || die "$(relpath "$file"): $message"
}

check_agent_guidance_docs() {
  local collab effort effort_json model lifecycle budget polish flags helper_output registry_py speak join phase_commands show_flags
  collab="$CURSOR_CONFIG_ROOT/_functions/collab"
  effort="$collab/_agent-effort.md"
  effort_json="$collab/_agent-effort.json"
  model="$collab/_agent-model.md"
  lifecycle="$collab/_agent-lifecycle.md"
  budget="$collab/_contribution-budget.md"
  polish="$collab/_moderator-polish.md"
  flags="$collab/_flag-taxonomy.md"
  helper_output="$collab/_helper-output.md"
  registry_py="$ROOT/tools/collab/registry.py"
  speak="$collab/speak.md"
  join="$collab/join.md"
  phase_commands="$collab/_phase-commands.md"
  show_flags="$collab/show-flags.md"

  [[ -f "$effort" || -f "$effort_json" || -f "$model" || -f "$lifecycle" ]] || return 0

  [[ -f "$effort" ]] || die "cursor/_functions/collab/_agent-effort.md: missing collab shared dependency"
  [[ -f "$effort_json" ]] || die "cursor/_functions/collab/_agent-effort.json: missing collab shared dependency"
  [[ -f "$model" ]] || die "cursor/_functions/collab/_agent-model.md: missing collab shared dependency"
  [[ -f "$lifecycle" ]] || die "cursor/_functions/collab/_agent-lifecycle.md: missing collab shared dependency"
  [[ -f "$budget" ]] || die "cursor/_functions/collab/_contribution-budget.md: missing collab shared dependency"
  [[ -f "$polish" ]] || die "cursor/_functions/collab/_moderator-polish.md: missing collab shared dependency"
  [[ -f "$flags" ]] || die "cursor/_functions/collab/_flag-taxonomy.md: missing collab shared dependency"
  [[ -f "$helper_output" ]] || die "cursor/_functions/collab/_helper-output.md: missing collab shared dependency"

  require_contains "$effort" "[\`_agent-effort.json\`](_agent-effort.json)" "missing link to _agent-effort.json"
  require_contains "$model" "[\`_agent-effort.md\`](_agent-effort.md)" "missing link to _agent-effort.md"
  require_contains "$model" "[\`_agent-lifecycle.md\`](_agent-lifecycle.md)" "missing link to _agent-lifecycle.md"
  require_contains "$model" "honest-effort forensic capture" "missing join-model forensic-capture guidance"
  require_contains "$model" "not an enforced constraint" "missing join-model advisory guidance"
  require_contains "$model" "fallback" "missing fallback guidance"

  require_contains "$lifecycle" "[\`_agent-effort.md\`](_agent-effort.md)" "missing link to _agent-effort.md"
  require_contains "$lifecycle" "[\`_agent-model.md\`](_agent-model.md)" "missing link to _agent-model.md"
  require_contains "$lifecycle" "The join-time model does not change; only effort adjusts between phases." "missing fixed-model lifecycle guidance"

  require_contains "$effort" "[\`_agent-model.md\`](_agent-model.md)" "missing link to _agent-model.md"
  require_contains "$effort" "[\`_agent-lifecycle.md\`](_agent-lifecycle.md)" "missing link to _agent-lifecycle.md"

  [[ -f "$join" ]] && require_contains "$join" "cursor/_functions/collab/_agent-effort.json" "missing relocated effort matrix reference"
  if [[ -f "$speak" ]]; then
    require_contains "$speak" "cursor/_functions/collab/_agent-effort.json" "missing relocated effort matrix reference"
    require_contains "$speak" "cursor/_functions/collab/_agent-effort.md" "missing relocated effort guidance reference"
    require_contains "$speak" "cursor/_functions/collab/_moderator-polish.md" "missing relocated moderator polish reference"
  fi
  [[ -f "$phase_commands" ]] && require_contains "$phase_commands" "[\`_agent-effort.md\`](_agent-effort.md)" "missing same-namespace effort reference"
  [[ -f "$show_flags" ]] && require_contains "$show_flags" "cursor/_functions/collab/_flag-taxonomy.md" "missing relocated flag taxonomy reference"

  require_contains "$registry_py" "DEFAULT_CURSOR_ROOT = Path(os.environ.get('CURSOR_CONFIG_ROOT', ROOT)).expanduser().resolve()" "helper default must resolve Cursor config root from repo root"
  require_contains "$registry_py" "DEFAULT_EFFORT_PATH = DEFAULT_CURSOR_ROOT / '_functions/collab/_agent-effort.json'" "helper default must use root-layout effort matrix"
  require_contains "$registry_py" "DEFAULT_BUDGET_PATH = DEFAULT_CURSOR_ROOT / '_functions/collab/_contribution-budget.md'" "helper default must use root-layout contribution budget"
  require_contains "$registry_py" "DEFAULT_MODERATOR_POLISH_PATH = DEFAULT_CURSOR_ROOT / '_functions/collab/_moderator-polish.md'" "helper default must use root-layout moderator polish"
  require_contains "$registry_py" "DEFAULT_FLAG_TAXONOMY_PATH = DEFAULT_CURSOR_ROOT / '_functions/collab/_flag-taxonomy.md'" "helper default must use root-layout flag taxonomy"

  while IFS= read -r file; do
    local stale_line
    stale_line="$(grep -n -E '\.collabs/records/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+' "$file" | head -n 1 || true)"
    [[ -z "$stale_line" ]] || die "$(cursor_source_key "$file"):${stale_line}: remove stale .collabs record ID citation"
  done < <(find "$CURSOR_CONFIG_ROOT" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.json' \) | sort)

  while IFS= read -r file; do
    local effort_line
    effort_line="$(grep -n -E '(^|[^[:alnum:]_-])extra[- ]high([^[:alnum:]_-]|$)' "$file" | head -n 1 || true)"
    [[ -z "$effort_line" ]] || die "$(cursor_source_key "$file"):${effort_line}: use canonical effort token xhigh"
  done < <(find "$CURSOR_CONFIG_ROOT" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.json' \) | sort)
}

flagged_term_pattern() {
  local terms=(
    'leg''acy'
    'back''wards'
    'back''ward'
    'compati''bility'
    'cmopati''bility'
    'depre''cated'
    'reva''mp'
    'ev''al'
  )
  local joined term
  joined=""
  for term in "${terms[@]}"; do
    if [[ -z "$joined" ]]; then
      joined="$term"
    else
      joined="${joined}|${term}"
    fi
  done
  printf '\\b(%s)\\b\n' "$joined"
}

flagged_term_allowed() {
  local rel="$1" text="$2"
  local old_label='leg''acy'
  local back='back''ward'
  local compat='compati''ble'
  local changed='Depre''cated'

  case "$rel" in
    cursor/_tests/commands.md)
      [[ "$text" == *"${old_label} \`**Phrases:**\` blocks fail."* ]] && return 0
      ;;
    REPOSITORY.md|cursor/_templates/REPOSITORY.md)
      [[ "$text" == "- **Minor:** additive contract surface; ${back} ${compat}." ]] && return 0
      ;;
    cursor/_core/document-standard.md)
      [[ "$text" == "### ${changed}" ]] && return 0
      ;;
  esac

  return 1
}

scan_flagged_terms_fallback() {
  local path file term_list
  term_list="$(flagged_term_pattern | sed -e 's/^\\b(//' -e 's/)\\b$//' -e 's/|/ /g')"
  for path in "$@"; do
    if [[ -d "$path" ]]; then
      while IFS= read -r file; do
        awk -v path="$file" -v term_list="$term_list" '
          BEGIN {
            split(term_list, terms, " ")
          }
          {
            lower = tolower($0)
            for (i in terms) {
              term = terms[i]
              start = 1
              while ((pos = index(substr(lower, start), term)) > 0) {
                absolute = start + pos - 1
                before = absolute == 1 ? "" : substr(lower, absolute - 1, 1)
                after = substr(lower, absolute + length(term), 1)
                if (before !~ /[[:alnum:]_]/ && after !~ /[[:alnum:]_]/) {
                  print path ":" NR ":" $0
                  next
                }
                start = absolute + length(term)
              }
            }
          }
        ' "$file"
      done < <(find "$path" -type f | sort)
    elif [[ -f "$path" ]]; then
      awk -v path="$path" -v term_list="$term_list" '
        BEGIN {
          split(term_list, terms, " ")
        }
        {
          lower = tolower($0)
          for (i in terms) {
            term = terms[i]
            start = 1
            while ((pos = index(substr(lower, start), term)) > 0) {
              absolute = start + pos - 1
              before = absolute == 1 ? "" : substr(lower, absolute - 1, 1)
              after = substr(lower, absolute + length(term), 1)
              if (before !~ /[[:alnum:]_]/ && after !~ /[[:alnum:]_]/) {
                print path ":" NR ":" $0
                next
              }
              start = absolute + length(term)
            }
          }
        }
      ' "$path"
    fi
  done
}

scan_flagged_terms() {
  local pattern="$1"
  shift
  if [[ "${CHECK_CURSOR_CONTENT_NO_RG:-}" != "1" ]] && command -v rg >/dev/null 2>&1; then
    rg -n -i "$pattern" -- "$@" || true
  else
    scan_flagged_terms_fallback "$@"
  fi
}

check_flagged_terms() {
  local pattern path line text rel
  local candidates=(
    "$ROOT/AGENTS.md"
    "$ROOT/CLAUDE.md"
    "$ROOT/REPOSITORY.md"
    "$CURSOR_CONFIG_ROOT"
    "$ROOT/tools"
    "$ROOT/tests"
  )
  local existing=()

  for path in "${candidates[@]}"; do
    [[ -e "$path" ]] && existing+=("$path")
  done
  [[ "${#existing[@]}" -gt 0 ]] || return 0

  pattern="$(flagged_term_pattern)"
  while IFS=: read -r path line text; do
    [[ -n "${path}${line}${text}" ]] || continue
    rel="$(cursor_source_key "$path")"
    flagged_term_allowed "$rel" "$text" && continue
    die "${rel}:${line}: remove or justify flagged transition wording"
  done < <(scan_flagged_terms "$pattern" "${existing[@]}")
}

[[ -d "$CURSOR_CONFIG_ROOT" ]] || die "CURSOR_CONFIG_ROOT directory does not exist: $CURSOR_CONFIG_ROOT"

check_line_budget
check_command_shapes
check_rule_shapes
check_content_invariants
check_agent_guidance_docs
check_prose_dispatch_framing
check_flagged_terms

echo "check-cursor-content: OK"
