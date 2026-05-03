#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.cursor.roles import load_role, participant_row, roles_command


PHASES = ['Audit', 'Discussion', 'Conclusion', 'Action Plan', 'Handoff', 'Completion']
ONE_SPEAK_PHASES = {'Audit', 'Conclusion', 'Action Plan', 'Handoff'}
AUTO_ADVANCE_EXEMPT_PHASES = {'Discussion', 'Completion'}
CONVERGENT_REVIEWER_PHASES = {'Audit', 'Conclusion'}
MOD_EXCLUDED_PHASES = {'Conclusion', 'Action Plan', 'Handoff', 'Completion'}
ALLOWED_SET_FIELDS = {'title', 'description', 'turn-order'}
FORCE_ONLY_FIELDS = {'active-phase'}
ALLOWED_STATUSES = {'open', 'closed', 'archived'}
ALLOWED_EXECUTION_STATUSES = {'in_progress', 'completed', 'failed'}
ALLOWED_REVIEWER_MODES = {'last-in-convergent-phases'}
DEFAULT_REVIEWER_MODE = 'last-in-convergent-phases'
DEFAULT_REVIEWER_OPTIONAL_PHASES = ['Discussion']
ID_RE = re.compile(r'^\d{4}-\d{2}-\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*$')
SUMMARY_RE = re.compile(r'^<summary>(?P<role>[A-Za-z0-9_-]+)(?:\s+—\s+.+)?</summary>$')
LEGACY_EXPANDED_RE = re.compile(r'^\*\*(?P<role>[A-Za-z0-9_-]+)\s+—')
LEGACY_HEADING_RE = re.compile(r'^###\s+(?P<role>[A-Za-z0-9_-]+)\s+—')
DETAILS_OPEN_RE = re.compile(r'^<details(?:\s+[^>]*)?>$')
DETAILS_CLOSE_RE = re.compile(r'^</details>$')
OLD_ROOT_KEYS = {'schema_version', 'active_collab_id'}
OLD_ENTRY_KEYS = {
    'active_phase',
    'created_on',
    'moderator_role',
    'transcript_path',
    'turn_order',
}


def die(message: str) -> None:
    raise SystemExit(message)


def load_registry(path: Path) -> dict:
    if not path.exists():
        die(f'registry missing: {path}')
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        die(f'registry invalid JSON: {path}: {exc}')
    validate_registry(data, path)
    return data


def save_registry(path: Path, data: dict) -> None:
    validate_registry(data, path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n')


def format_timestamp(now: dt.datetime | None = None) -> str:
    value = now or dt.datetime.now().astimezone()
    stamp = value.strftime('%Y-%m-%d %H:%M %z')
    return f'{stamp[:-2]}:{stamp[-2:]}'


def format_banner_timestamp(now: dt.datetime | None = None) -> str:
    value = now or dt.datetime.now().astimezone()
    day = str(value.day)
    return value.strftime(f'%b {day}, %Y @ %-I:%M %p')


def summary_role(line: str) -> str | None:
    match = SUMMARY_RE.match(line.strip())
    if not match:
        return None
    return match.group('role')


def phase_section(text: str, phase: str) -> list[str]:
    lines = text.splitlines()
    heading = f'## {phase}'
    start: int | None = None
    for index, line in enumerate(lines):
        if line.strip() == heading:
            start = index + 1
            break
    if start is None:
        die(f'transcript phase missing: {phase}')

    end = len(lines)
    for index in range(start, len(lines)):
        if lines[index].startswith('## ') and lines[index].strip() in {f'## {item}' for item in PHASES}:
            end = index
            break
    return lines[start:end]


def contribution_roles(text: str, phase: str) -> list[str]:
    roles: list[str] = []
    details_depth = 0
    for line in phase_section(text, phase):
        stripped = line.strip()
        if DETAILS_OPEN_RE.match(stripped):
            details_depth += 1
            continue
        if DETAILS_CLOSE_RE.match(stripped):
            details_depth = max(0, details_depth - 1)
            continue
        if details_depth == 1:
            role = summary_role(line)
            if role is not None:
                roles.append(role)
            continue
        if details_depth:
            continue
        for pattern in (LEGACY_EXPANDED_RE, LEGACY_HEADING_RE):
            match = pattern.match(stripped)
            if match:
                roles.append(match.group('role'))
                break
    return roles


def reviewer_role(entry: dict) -> str | None:
    value = entry.get('reviewerRole')
    if isinstance(value, str) and value.strip():
        return value
    return None


def participant_roles(entry: dict) -> list[str]:
    return [p['role'] for p in entry.get('participants', [])]


def has_participant(entry: dict, role: str) -> bool:
    return role in participant_roles(entry)


def reviewer_state(entry: dict) -> dict:
    reviewer = reviewer_role(entry)
    if reviewer is None:
        return {'reviewerRole': None, 'state': 'absent'}
    state = 'active' if has_participant(entry, reviewer) else 'pending'
    return {'reviewerRole': reviewer, 'state': state}


def active_reviewer_role(entry: dict) -> str | None:
    reviewer = reviewer_role(entry)
    if reviewer and has_participant(entry, reviewer):
        return reviewer
    return None


def pending_reviewer_role(entry: dict) -> str | None:
    reviewer = reviewer_role(entry)
    if reviewer and not has_participant(entry, reviewer):
        return reviewer
    return None


def reviewer_mode(entry: dict) -> str:
    return entry.get('reviewerMode') or DEFAULT_REVIEWER_MODE


def reviewer_optional_phases(entry: dict) -> list[str]:
    value = entry.get('reviewerOptionalPhases')
    if value is None:
        return list(DEFAULT_REVIEWER_OPTIONAL_PHASES)
    return list(value)


def reviewer_required_for_phase(entry: dict, phase: str) -> str | None:
    reviewer = active_reviewer_role(entry)
    if not reviewer:
        return None
    if reviewer_mode(entry) == 'last-in-convergent-phases' and phase in CONVERGENT_REVIEWER_PHASES:
        return reviewer
    return None


def reviewer_optional_for_phase(entry: dict, phase: str) -> str | None:
    reviewer = active_reviewer_role(entry)
    if reviewer and phase in reviewer_optional_phases(entry):
        return reviewer
    return None


def optional_reviewer_allowed_at_round_boundary(
    entry: dict,
    phase: str,
    contributors: list[str],
    order: list[str],
) -> str | None:
    reviewer = reviewer_optional_for_phase(entry, phase)
    if not reviewer or not order or not contributors:
        return None
    if contributors[-1] == reviewer:
        return None

    ordinary_contributors = [role for role in contributors if role in order]
    if len(ordinary_contributors) < len(order):
        return None
    if ordinary_contributors[-len(order):] != order:
        return None
    return reviewer


def expected_speaker(entry: dict, contributors: list[str]) -> str:
    phase = entry['activePhase']
    order = effective_turn_order(entry)
    reviewer = reviewer_required_for_phase(entry, phase)
    if reviewer and all(contributors.count(role) >= 1 for role in order):
        if contributors.count(reviewer) < 1:
            return reviewer
    ordered_contributors = [role for role in contributors if role in order]
    if not ordered_contributors:
        return order[0]
    last = ordered_contributors[-1]
    return order[(order.index(last) + 1) % len(order)]


def speak_state_for_entry(entry: dict, transcript: str) -> dict:
    phase = entry['activePhase']
    contributors = contribution_roles(transcript, phase)
    order = effective_turn_order(entry)
    expected = expected_speaker(entry, contributors)
    optional_reviewer = optional_reviewer_allowed_at_round_boundary(entry, phase, contributors, order)
    allowed_roles = [expected]
    if optional_reviewer and optional_reviewer not in allowed_roles:
        allowed_roles.append(optional_reviewer)
    return {
        'activePhase': phase,
        'turnOrder': order,
        'contributors': contributors,
        'lastContributor': contributors[-1] if contributors else None,
        'expectedRole': expected,
        'reviewerRole': reviewer_role(entry),
        'reviewerMode': reviewer_mode(entry) if reviewer_role(entry) else None,
        'reviewerOptionalPhases': reviewer_optional_phases(entry) if reviewer_role(entry) else [],
        'allowedRoles': allowed_roles,
        'autoAdvanceExempt': phase in AUTO_ADVANCE_EXEMPT_PHASES,
    }


def validate_registry(data: dict, path: Path | None = None) -> None:
    source = str(path) if path else 'registry'
    if not isinstance(data, dict):
        die(f'{source}: root must be an object')
    old_root_keys = sorted(OLD_ROOT_KEYS.intersection(data))
    if old_root_keys:
        die(f'{source}: old registry keys are not allowed: {old_root_keys}')
    if data.get('schemaVersion') != 1:
        die(f'{source}: schemaVersion must be 1')

    collabs = data.get('collabs')
    if not isinstance(collabs, list):
        die(f'{source}: collabs must be a list')

    active_id = data.get('activeCollabId')
    ids: list[str] = []
    slugs: list[str] = []
    sequences: list[int] = []
    collab_map: dict[str, dict] = {}

    for entry in collabs:
        if not isinstance(entry, dict):
            die(f'{source}: collab entry must be an object')
        old_entry_keys = sorted(OLD_ENTRY_KEYS.intersection(entry))
        if old_entry_keys:
            die(f'{source}: old collab keys are not allowed: {old_entry_keys}')

        collab_id = entry.get('id')
        slug = entry.get('slug')
        title = entry.get('title')
        description = entry.get('description')
        status = entry.get('status')
        activePhase = entry.get('activePhase')
        moderatorRole = entry.get('moderatorRole')
        participants = entry.get('participants')
        turnOrder = entry.get('turnOrder')
        transcriptPath = entry.get('transcriptPath')
        reviewerRole = entry.get('reviewerRole')
        sequence = entry.get('sequence')

        for field, value in (
            ('id', collab_id),
            ('slug', slug),
            ('title', title),
            ('description', description),
            ('status', status),
            ('activePhase', activePhase),
            ('moderatorRole', moderatorRole),
            ('transcriptPath', transcriptPath),
        ):
            if not isinstance(value, str) or not value.strip():
                die(f'{source}: collab {field} must be a non-empty string')

        if not ID_RE.match(collab_id):
            die(f'{source}: collab id must use YYYY-MM-DD-<slug>')
        expected_path = f'.collabs/records/{collab_id}.md'
        if transcriptPath != expected_path:
            die(f'{source}: transcriptPath must match .collabs/records/<id>.md')
        if collab_id[11:] != slug:
            die(f'{source}: collab id suffix must match slug')
        if status not in ALLOWED_STATUSES:
            die(f'{source}: collab status must be one of {sorted(ALLOWED_STATUSES)}')
        if activePhase not in PHASES:
            die(f'{source}: collab activePhase must be one of {PHASES}')
        if not isinstance(entry.get('archived'), bool):
            die(f'{source}: collab archived must be a boolean')
        if sequence is not None:
            if not isinstance(sequence, int) or sequence < 1:
                die(f'{source}: collab sequence must be a positive integer when present')
            sequences.append(sequence)

        if not isinstance(participants, list) or not participants:
            die(f'{source}: participants must be a non-empty list')
        if not all(
            isinstance(p, dict)
            and isinstance(p.get('role'), str) and p['role'].strip()
            and isinstance(p.get('agentId'), str)
            for p in participants
        ):
            die(f'{source}: participants must contain objects with non-empty role string and agentId string')
        participant_role_keys = [p['role'] for p in participants]
        if len(set(participant_role_keys)) != len(participant_role_keys):
            die(f'{source}: participants must not contain duplicate roles')
        if moderatorRole not in participant_role_keys:
            die(f'{source}: moderatorRole must be listed in participants')

        if not isinstance(turnOrder, list) or not turnOrder:
            die(f'{source}: turnOrder must be a non-empty list')
        if not all(isinstance(role, str) and role.strip() for role in turnOrder):
            die(f'{source}: turnOrder must contain non-empty role strings')
        if len(set(turnOrder)) != len(turnOrder):
            die(f'{source}: turnOrder must not contain duplicates')
        if not set(turnOrder).issubset(set(participant_role_keys)):
            die(f'{source}: turnOrder must stay within participants')

        if reviewerRole is not None:
            if not isinstance(reviewerRole, str) or not reviewerRole.strip():
                die(f'{source}: reviewerRole must be absent or a non-empty string')
            if reviewerRole == moderatorRole:
                die(f'{source}: reviewerRole must not equal moderatorRole')

            mode = reviewer_mode(entry)
            if mode not in ALLOWED_REVIEWER_MODES:
                die(f'{source}: reviewerMode must be one of {sorted(ALLOWED_REVIEWER_MODES)}')
            if mode == 'last-in-convergent-phases' and reviewerRole in turnOrder:
                die(f'{source}: reviewerRole must not appear in turnOrder')

            optional_phases = entry.get('reviewerOptionalPhases', DEFAULT_REVIEWER_OPTIONAL_PHASES)
            if not isinstance(optional_phases, list):
                die(f'{source}: reviewerOptionalPhases must be a list when present')
            if not all(isinstance(phase, str) and phase in PHASES for phase in optional_phases):
                die(f'{source}: reviewerOptionalPhases must contain valid phase names')

        execution = entry.get('execution', {})
        if not isinstance(execution, dict):
            die(f'{source}: execution must be an object when present')
        for role, state in execution.items():
            if not isinstance(role, str) or not role.strip():
                die(f'{source}: execution keys must be non-empty role strings')
            if not isinstance(state, dict):
                die(f'{source}: execution state must be an object')
            if state.get('status') not in ALLOWED_EXECUTION_STATUSES:
                die(f'{source}: execution status must be one of {sorted(ALLOWED_EXECUTION_STATUSES)}')
            date = state.get('date')
            if not isinstance(date, str) or not date.strip():
                die(f'{source}: execution date must be a non-empty string')
            validation_result = state.get('validationResult')
            if validation_result is not None and (
                not isinstance(validation_result, str) or not validation_result.strip()
            ):
                die(f'{source}: execution validationResult must be a non-empty string when present')
            touched_paths = state.get('touchedPaths', [])
            if not isinstance(touched_paths, list):
                die(f'{source}: execution touchedPaths must be a list when present')
            if any(not isinstance(item, str) or not item.strip() for item in touched_paths):
                die(f'{source}: execution touchedPaths must contain non-empty strings')


        if collab_id in collab_map:
            die(f'{source}: duplicate collab id: {collab_id}')
        ids.append(collab_id)
        slugs.append(slug)
        collab_map[collab_id] = entry

    if len(ids) != len(set(ids)):
        die(f'{source}: duplicate collab ids are not allowed')
    if len(slugs) != len(set(slugs)):
        die(f'{source}: duplicate collab slugs are not allowed')
    if len(sequences) != len(set(sequences)):
        die(f'{source}: duplicate collab sequences are not allowed')

    if active_id is not None:
        if not isinstance(active_id, str) or not active_id.strip():
            die(f'{source}: activeCollabId must be null or a non-empty string')
        if active_id not in collab_map:
            die(f'{source}: activeCollabId must point at an existing collab id')
        if collab_map[active_id].get('archived'):
            die(f'{source}: activeCollabId must not point at an archived collab')


def resolve_collab(data: dict, target: str) -> dict:
    numeric_target = target[1:] if target.startswith('#') else target
    if numeric_target.isdigit():
        number = int(numeric_target)
        for index, entry in enumerate(data['collabs'], start=1):
            if entry.get('sequence', index) == number:
                return entry
        die(f'registry target not found: {target}')
    for entry in data['collabs']:
        if target in {entry['id'], entry['slug']}:
            return entry
    die(f'registry target not found: {target}')


def require_active_collab(data: dict) -> dict:
    active_id = data.get('activeCollabId')
    if not active_id:
        die('registry activeCollabId is empty')
    return resolve_collab(data, active_id)


def display_title(title: str, limit: int = 20) -> str:
    if len(title) <= limit:
        return title
    return title[:limit] + '…'


def collab_date(entry: dict) -> str:
    return entry['id'][:10]


def list_collabs(data: dict, status_filter: str | None = None) -> int:
    if status_filter is not None and status_filter not in ALLOWED_STATUSES:
        die(f'invalid status filter: {status_filter}')
    active_id = data.get('activeCollabId')
    indexed = [
        (index, entry)
        for index, entry in enumerate(data['collabs'], start=1)
        if status_filter is None or entry['status'] == status_filter
    ]
    indexed.sort(key=lambda item: (
        item[1]['id'] != active_id,
        -item[1].get('sequence', item[0]),
        item[1]['slug'],
    ))
    for output_index, (index, entry) in enumerate(indexed):
        marker = '[*]' if entry['id'] == active_id else '[ ]'
        number = entry.get('sequence', index)
        title = display_title(entry['title'])
        phase = entry['activePhase'] if entry['activePhase'] else '—'
        participant_label = 'participant' if len(entry['participants']) == 1 else 'participants'
        if output_index:
            print()
        print(f"{marker} #{number} - {entry['slug']}    {title}")
        print(
            f"         {entry['status']} · {phase} · "
            f"{len(entry['participants'])} {participant_label} · {collab_date(entry)}",
        )
    return 0


def add_participant_to_entry(entry: dict, role: str, agent_id: str = '') -> bool:
    if not role.strip():
        die('participant role must be non-empty')
    changed = False
    is_reviewer = role == reviewer_role(entry) and reviewer_mode(entry) == 'last-in-convergent-phases'
    if not has_participant(entry, role):
        entry['participants'].append({'role': role, 'agentId': agent_id})
        changed = True
    if not entry['turnOrder']:
        entry['turnOrder'] = [
            p['role'] for p in entry['participants']
            if not (
                p['role'] == reviewer_role(entry)
                and reviewer_mode(entry) == 'last-in-convergent-phases'
            )
        ]
        changed = True
    elif not is_reviewer and role not in entry['turnOrder']:
        entry['turnOrder'].append(role)
        changed = True
    return changed


def effective_turn_order(entry: dict) -> list[str]:
    order = entry['turnOrder'] or participant_roles(entry)
    reviewer = reviewer_role(entry)
    if reviewer and reviewer_mode(entry) == 'last-in-convergent-phases':
        return [role for role in order if role != reviewer]
    return order


def next_phase_name(phase: str) -> str | None:
    index = PHASES.index(phase)
    if index == len(PHASES) - 1:
        return None
    return PHASES[index + 1]


def remove_moderator_from_turn_order(entry: dict, order: list[str] | None = None) -> None:
    moderator = entry['moderatorRole']
    source_order = order or effective_turn_order(entry)
    entry['turnOrder'] = [role for role in source_order if role != moderator]
    if not entry['turnOrder']:
        entry['turnOrder'] = [r for r in participant_roles(entry) if r != moderator]
    if not entry['turnOrder']:
        die('turnOrder cannot be empty after removing moderator')


def apply_speak_lifecycle_to_entry(entry: dict, contributors: list[str]) -> bool:
    phase = entry['activePhase']
    order = effective_turn_order(entry)
    reviewer = reviewer_required_for_phase(entry, phase)
    required_roles = list(order)
    if reviewer:
        required_roles.append(reviewer)
    counts = {role: contributors.count(role) for role in required_roles}

    if phase in ONE_SPEAK_PHASES:
        duplicates = [role for role, count in counts.items() if count > 1]
        if duplicates:
            die(f'duplicate contribution in one-speak phase {phase}: {duplicates[0]}')

    if phase in AUTO_ADVANCE_EXEMPT_PHASES or not all(counts.get(role, 0) >= 1 for role in required_roles):
        return False

    next_phase = next_phase_name(phase)
    if next_phase is None:
        return False
    entry['activePhase'] = next_phase
    if next_phase in MOD_EXCLUDED_PHASES:
        remove_moderator_from_turn_order(entry, order)
    return True


def close_eligible_after_execution(entry: dict, assigned_roles: list[str]) -> bool:
    roles = [role for role in assigned_roles if role != entry['moderatorRole']]
    if not roles:
        return False
    execution = entry.get('execution', {})
    return all(execution.get(role, {}).get('status') == 'completed' for role in roles)


def use_collab(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['archived']:
        die(f'registry target archived: {target}')
    data['activeCollabId'] = entry['id']
    save_registry(path, data)
    print(entry['id'])
    return 0


def add_participant(path: Path, target: str, role: str) -> int:
    print(
        'warning: participant is deprecated; use join-participants so transcript metadata is rendered',
        file=sys.stderr,
    )
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['status'] in {'closed', 'archived'}:
        die('record is closed')
    add_participant_to_entry(entry, role)
    save_registry(path, data)
    print(' '.join(participant_roles(entry)))
    return 0


def set_field(path: Path, target: str, field: str, value: str | None, force: bool) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if field in FORCE_ONLY_FIELDS:
        if value is None:
            die(f'{field} requires a value')
        if not force:
            die(f'field requires --force: {field}')
        if field == 'active-phase':
            if value not in PHASES:
                die(f'active-phase must be one of {PHASES}')
            entry['activePhase'] = value
    elif field == 'reviewer':
        if value == '--clear':
            clear_reviewer(entry)
        else:
            if value is None:
                die('reviewer requires a role or --clear')
            if not has_participant(entry, value):
                die('reviewer must already be a participant')
            if value == entry['moderatorRole']:
                die('reviewer must not be the moderator')
            if value in entry['turnOrder']:
                die('reviewer must not appear in turnOrder')
            entry['reviewerRole'] = value
            entry['reviewerMode'] = DEFAULT_REVIEWER_MODE
            entry.setdefault('reviewerOptionalPhases', list(DEFAULT_REVIEWER_OPTIONAL_PHASES))
    elif field not in ALLOWED_SET_FIELDS:
        die(f'field not settable: {field}')
    elif field == 'turn-order':
        if value is None:
            die('turn-order requires a value')
        turnOrder = value.split()
        if not turnOrder:
            die('turn-order requires at least one role')
        if len(set(turnOrder)) != len(turnOrder):
            die('turn-order roles must be unique')
        if not set(turnOrder).issubset(set(participant_roles(entry))):
            die('turn-order roles must already be participants')
        reviewer = reviewer_role(entry)
        if reviewer and reviewer in turnOrder:
            die('turn-order must not include reviewerRole')
        entry['turnOrder'] = turnOrder
    else:
        if value is None:
            die(f'{field} requires a value')
        if not value.strip():
            die(f'{field} requires a non-empty value')
        entry[field] = value
    save_registry(path, data)
    print(entry['id'])
    return 0


def clear_reviewer(entry: dict) -> bool:
    changed = False
    for key in ('reviewerRole', 'reviewerMode', 'reviewerOptionalPhases'):
        if key in entry:
            entry.pop(key)
            changed = True
    return changed


def unset_field(path: Path, target: str, field: str, roles_dir: Path) -> int:
    if field != 'reviewer':
        die(f'field not unsettable: {field}')

    data = load_registry(path)
    current_entry = resolve_collab(data, target)
    if current_entry['status'] in {'closed', 'archived'}:
        die('record is closed')

    next_data = deepcopy(data)
    next_entry = resolve_collab(next_data, target)
    clear_reviewer(next_entry)
    validate_registry(next_data, path)

    transcript_path = Path(next_entry['transcriptPath'])
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')
    transcript = transcript_path.read_text()
    status_rendered = replace_status_table(transcript, next_entry)
    rendered = replace_reviewer_section_text(status_rendered, next_entry, roles_dir)
    commit_registry_and_transcript(path, next_data, transcript_path, rendered)
    print(next_entry['id'])
    return 0


def speak_lifecycle(path: Path, target: str, contributors: list[str]) -> int:
    if not contributors:
        die('contributors requires at least one role')
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['status'] in {'closed', 'archived'}:
        die('record is closed')
    for role in contributors:
        if not has_participant(entry, role):
            die(f'contributor must already be a participant: {role}')
    advanced = apply_speak_lifecycle_to_entry(entry, contributors)
    save_registry(path, data)
    print(entry['activePhase'] if advanced else 'unchanged')
    return 0


def read_transcript_for_entry(entry: dict) -> str:
    transcript_path = Path(entry['transcriptPath'])
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')
    return transcript_path.read_text()


def speak_state(path: Path, target: str, role: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['status'] in {'closed', 'archived'}:
        die('record is closed')
    if not has_participant(entry, role):
        die(f'role must already be a participant: {role}')
    pending_reviewer = pending_reviewer_role(entry)
    if pending_reviewer:
        die(f'pending reviewerRole: {pending_reviewer}')
    state = speak_state_for_entry(entry, read_transcript_for_entry(entry))
    if role not in state['allowedRoles']:
        if role == reviewer_optional_for_phase(entry, entry['activePhase']):
            die('reviewer may speak after all turn-order participants have contributed in this round')
        die(f"expected role: {state['expectedRole']}")
    print(json.dumps(state, sort_keys=True))
    return 0


def speak_lifecycle_live(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['status'] in {'closed', 'archived'}:
        die('record is closed')
    state = speak_state_for_entry(entry, read_transcript_for_entry(entry))
    advanced = apply_speak_lifecycle_to_entry(entry, state['contributors'])
    save_registry(path, data)
    print(entry['activePhase'] if advanced else 'unchanged')
    return 0


def advance_phase(path: Path, target: str, direction: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    index = PHASES.index(entry['activePhase'])
    if direction == 'next':
        if index == len(PHASES) - 1:
            die('no next phase')
        entry['activePhase'] = PHASES[index + 1]
        if entry['activePhase'] in MOD_EXCLUDED_PHASES:
            remove_moderator_from_turn_order(entry)
    else:
        if index == 0:
            die('no previous phase')
        entry['activePhase'] = PHASES[index - 1]
    save_registry(path, data)
    print(entry['activePhase'])
    return 0


def record_execution(
    path: Path,
    target: str,
    role: str,
    status: str,
    date: str,
    assigned_roles: list[str],
    auto_close: bool,
    validation_result: str | None,
    touched_paths: list[str],
) -> int:
    if status not in ALLOWED_EXECUTION_STATUSES:
        die(f'execution status must be one of {sorted(ALLOWED_EXECUTION_STATUSES)}')
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['status'] in {'closed', 'archived'}:
        die('record is closed')
    if not has_participant(entry, role):
        die(f'execution role must already be a participant: {role}')
    for assigned_role in assigned_roles:
        if not has_participant(entry, assigned_role):
            die(f'assigned role must already be a participant: {assigned_role}')

    execution_state = {'status': status, 'date': date}
    if validation_result:
        execution_state['validationResult'] = validation_result
    if touched_paths:
        execution_state['touchedPaths'] = touched_paths
    entry.setdefault('execution', {})[role] = execution_state
    closed = False
    if auto_close and close_eligible_after_execution(entry, assigned_roles):
        entry['status'] = 'closed'
        closed = True
        if data.get('activeCollabId') == entry['id']:
            data['activeCollabId'] = None

    save_registry(path, data)
    print('closed' if closed else entry['status'])
    return 0


def rendered_status_table(entry: dict) -> str:
    reviewer = reviewer_role(entry) or '\u2014'
    turn_order = ', '.join(entry['turnOrder']) if entry['turnOrder'] else '\u2014'
    return '\n'.join([
        '| Status | Active phase | Turn order | Reviewer |',
        '|--------|--------------|------------|----------|',
        f"| {entry['status']} | {entry['activePhase']} | {turn_order} | {reviewer} |",
    ])


def rendered_participants_table(entry: dict, roles_dir: Path) -> str:
    rows = [
        '| # | Key | Role | Agent | Responsibilities |',
        '|---|-----|------|-------|------------------|',
    ]
    for index, p in enumerate(entry['participants'], start=1):
        rows.append(participant_row(load_role(roles_dir, p['role']), index, p['agentId']))
    return '\n'.join(rows)


def replace_table_after_heading(
    transcript: str,
    heading: str,
    replacement: str,
    missing_section_message: str,
    missing_table_message: str,
) -> str:
    lines = transcript.splitlines()
    heading_index: int | None = None
    for index, line in enumerate(lines):
        if line.strip() == heading:
            heading_index = index
            break
    if heading_index is None:
        die(missing_section_message)

    table_start: int | None = None
    for index in range(heading_index + 1, len(lines)):
        if lines[index].startswith('|'):
            table_start = index
            break
        if lines[index].startswith('**') or lines[index].startswith('## '):
            break
    if table_start is None:
        die(missing_table_message)

    table_end = table_start
    while table_end < len(lines) and lines[table_end].startswith('|'):
        table_end += 1

    return '\n'.join(lines[:table_start] + replacement.splitlines() + lines[table_end:]) + '\n'


def replace_status_table(transcript: str, entry: dict) -> str:
    return replace_table_after_heading(
        transcript,
        '**Status**',
        rendered_status_table(entry),
        'transcript status section missing',
        'transcript status table missing',
    )


def rendered_reviewer_section(entry: dict, roles_dir: Path) -> str | None:
    state = reviewer_state(entry)
    if state['state'] == 'absent':
        return '\u2014'
    reviewer = state['reviewerRole']
    mode = reviewer_mode(entry)
    if state['state'] == 'active':
        return (
            f'**{reviewer}** — registered in **Participants** and active as the '
            f'convergent-phase reviewer per `.collabs/registry.json` '
            f'(`reviewerMode: {mode}`). Reviewer gating is now in effect for convergent phases.'
        )
    role_data = load_role(roles_dir, reviewer)
    display_name = role_data['displayName']
    return '\n'.join([
        '| Role | Status |',
        '|------|--------|',
        f'| {reviewer} ({display_name}) | (pending) |',
        '',
        f'`{reviewer}` is assigned as reviewer but has not yet joined. Run `/collab join --role {reviewer}` before any participant may contribute.',
    ])


def replace_reviewer_section_text(transcript: str, entry: dict, roles_dir: Path) -> str:
    lines = transcript.splitlines()
    heading_index: int | None = None
    for index, line in enumerate(lines):
        if line.strip() == '**Reviewer**':
            heading_index = index
            break
    if heading_index is None:
        return transcript
    section_end: int | None = None
    for index in range(heading_index + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped == '---' or (stripped.startswith('**') and stripped.endswith('**') and len(stripped) > 4):
            section_end = index
            break
    if section_end is None:
        return transcript
    new_content = rendered_reviewer_section(entry, roles_dir)
    if new_content is None:
        return transcript
    new_lines = lines[:heading_index + 1] + [''] + new_content.splitlines() + [''] + lines[section_end:]
    return '\n'.join(new_lines) + '\n'


def replace_participants_table_text(transcript: str, entry: dict, roles_dir: Path) -> str:
    return replace_table_after_heading(
        transcript,
        '**Participants**',
        rendered_participants_table(entry, roles_dir),
        'transcript participants section missing',
        'transcript participants table missing',
    )


def replace_participants_table(transcript_path: Path, entry: dict, roles_dir: Path) -> None:
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')
    transcript = transcript_path.read_text()
    replacement = replace_participants_table_text(transcript, entry, roles_dir)
    transcript_path.write_text(replacement)


def render_status(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    transcript_path = Path(entry['transcriptPath'])
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')
    transcript_path.write_text(replace_status_table(transcript_path.read_text(), entry))
    print(transcript_path)
    return 0


def render_participants(path: Path, target: str, roles_dir: Path) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    transcript_path = Path(entry['transcriptPath'])
    replace_participants_table(transcript_path, entry, roles_dir)
    print(transcript_path)
    return 0


def commit_registry_and_transcript(
    registry_path: Path,
    data: dict,
    transcript_path: Path,
    transcript_text: str,
) -> None:
    """Commit registry and transcript updates with rollback on known write failures.

    The registry file is replaced first, then the transcript file. If either
    replace fails, the helper restores the pre-operation contents it could read
    and reports which file may be inconsistent. This is a best-effort two-file
    transaction, not a filesystem-level atomic commit.
    """
    validate_registry(data, registry_path)
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')

    registry_before = registry_path.read_text() if registry_path.exists() else None
    transcript_before = transcript_path.read_text()
    registry_after = json.dumps(data, indent=2) + '\n'
    registry_tmp = registry_path.with_name(f'{registry_path.name}.tmp')
    transcript_tmp = transcript_path.with_name(f'{transcript_path.name}.tmp')

    try:
        registry_tmp.write_text(registry_after)
        transcript_tmp.write_text(transcript_text)
        registry_tmp.replace(registry_path)
        transcript_tmp.replace(transcript_path)
    except OSError as exc:
        inconsistent: list[str] = []
        try:
            if registry_before is None:
                registry_path.unlink(missing_ok=True)
            else:
                registry_path.write_text(registry_before)
        except OSError:
            inconsistent.append(str(registry_path))
        try:
            transcript_path.write_text(transcript_before)
        except OSError:
            inconsistent.append(str(transcript_path))
        registry_tmp.unlink(missing_ok=True)
        transcript_tmp.unlink(missing_ok=True)
        if inconsistent:
            die(f'join-participants write failed; inconsistent state may remain: {", ".join(inconsistent)}: {exc}')
        die(f'join-participants write failed; restored pre-operation state: {exc}')


def join_participants(path: Path, target: str, role: str, agent_id: str, roles_dir: Path) -> int:
    data = load_registry(path)
    current_entry = resolve_collab(data, target)
    if current_entry['status'] in {'closed', 'archived'}:
        die('record is closed')

    next_data = deepcopy(data)
    next_entry = resolve_collab(next_data, target)
    add_participant_to_entry(next_entry, role, agent_id)
    validate_registry(next_data, path)

    transcript_path = Path(next_entry['transcriptPath'])
    if not transcript_path.exists():
        die(f'transcript missing: {transcript_path}')
    transcript = transcript_path.read_text()

    participant_rendered = replace_participants_table_text(transcript, next_entry, roles_dir)
    status_rendered = replace_status_table(participant_rendered, next_entry)
    rendered = replace_reviewer_section_text(status_rendered, next_entry, roles_dir)
    commit_registry_and_transcript(path, next_data, transcript_path, rendered)
    print(' '.join(participant_roles(next_entry)))
    return 0


def write_guard(route: str, paths: list[str]) -> int:
    if not paths:
        die('write-guard requires at least one path')
    if route == 'execute':
        print('ok')
        return 0
    for item in paths:
        normalized = Path(item).as_posix()
        if normalized.startswith('./'):
            normalized = normalized[2:]
        if Path(item).is_absolute() or not (normalized == '.collabs' or normalized.startswith('.collabs/')):
            die(f'route may only write under .collabs: {route}: {item}')
    print('ok')
    return 0


def archive_collab(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    entry['status'] = 'archived'
    entry['archived'] = True
    if data.get('activeCollabId') == entry['id']:
        data['activeCollabId'] = None
    save_registry(path, data)
    print(entry['id'])
    return 0


def delete_collab(path: Path, target: str, confirmed: bool) -> int:
    if not confirmed:
        die('delete requires --yes confirmation')
    data = load_registry(path)
    entry = resolve_collab(data, target)
    transcript_path = Path(entry['transcriptPath'])
    data['collabs'] = [candidate for candidate in data['collabs'] if candidate['id'] != entry['id']]
    if data.get('activeCollabId') == entry['id']:
        data['activeCollabId'] = None
    if transcript_path.exists():
        transcript_path.unlink()
    save_registry(path, data)
    print(entry['id'])
    return 0


def validate_command(path: Path) -> int:
    load_registry(path)
    print('registry OK')
    return 0


def role_row_command(roles_dir: Path, role: str, index: int) -> int:
    print(participant_row(load_role(roles_dir, role), index))
    return 0


def reviewer_state_command(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    print(json.dumps(reviewer_state(entry), sort_keys=True))
    return 0


def timestamp_command() -> int:
    print(format_timestamp())
    return 0


def banner_timestamp_command() -> int:
    print(format_banner_timestamp())
    return 0


def summary_role_command(line: str) -> int:
    role = summary_role(line)
    if role is None:
        die('summary role unavailable')
    print(role)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='Shared collab registry helper.')
    parser.add_argument(
        '--registry',
        default='.collabs/registry.json',
        help='Path to the collab registry JSON file.',
    )
    subparsers = parser.add_subparsers(dest='command', required=True)

    subparsers.add_parser('validate')
    list_parser = subparsers.add_parser('list')
    list_parser.add_argument('--status', choices=sorted(ALLOWED_STATUSES))
    subparsers.add_parser('timestamp')
    subparsers.add_parser('banner-timestamp')

    role_row_parser = subparsers.add_parser('role-row')
    role_row_parser.add_argument('role')
    role_row_parser.add_argument('--roles-dir', default='cursor/_roles')
    role_row_parser.add_argument('--index', type=int, default=1)

    roles_parser = subparsers.add_parser('roles')
    roles_parser.add_argument('--roles-dir', default='cursor/_roles')

    summary_role_parser = subparsers.add_parser('summary-role')
    summary_role_parser.add_argument('line')

    reviewer_state_parser = subparsers.add_parser('reviewer-state')
    reviewer_state_parser.add_argument('target')

    use_parser = subparsers.add_parser('use')
    use_parser.add_argument('target')

    participant_parser = subparsers.add_parser('participant')
    participant_parser.add_argument('target')
    participant_parser.add_argument('role')

    join_participants_parser = subparsers.add_parser('join-participants')
    join_participants_parser.add_argument('target')
    join_participants_parser.add_argument('role')
    join_participants_parser.add_argument('--agent-id', default='')
    join_participants_parser.add_argument('--roles-dir', default='cursor/_roles')

    set_parser = subparsers.add_parser('set')
    set_parser.add_argument('target')
    set_parser.add_argument('field')
    set_parser.add_argument('value', nargs='?')
    set_parser.add_argument('--force', action='store_true')
    set_parser.add_argument('--clear', action='store_true')

    unset_parser = subparsers.add_parser('unset')
    unset_parser.add_argument('target')
    unset_parser.add_argument('field')
    unset_parser.add_argument('--roles-dir', default='cursor/_roles')

    advance_parser = subparsers.add_parser('advance')
    advance_parser.add_argument('target')
    advance_parser.add_argument('direction', choices=['next', 'prev'])

    speak_parser = subparsers.add_parser('speak-lifecycle')
    speak_parser.add_argument('target')
    speak_parser.add_argument('contributors', nargs='+')

    speak_state_parser = subparsers.add_parser('speak-state')
    speak_state_parser.add_argument('target')
    speak_state_parser.add_argument('role')

    speak_live_parser = subparsers.add_parser('speak-lifecycle-live')
    speak_live_parser.add_argument('target')

    execution_parser = subparsers.add_parser('execution')
    execution_parser.add_argument('target')
    execution_parser.add_argument('role')
    execution_parser.add_argument('status', choices=sorted(ALLOWED_EXECUTION_STATUSES))
    execution_parser.add_argument('date')
    execution_parser.add_argument('--assigned-role', action='append', default=[])
    execution_parser.add_argument('--auto-close', action='store_true')
    execution_parser.add_argument('--validation-result')
    execution_parser.add_argument('--touched-path', action='append', default=[])

    archive_parser = subparsers.add_parser('archive')
    archive_parser.add_argument('target')

    delete_parser = subparsers.add_parser('delete')
    delete_parser.add_argument('target')
    delete_parser.add_argument('--yes', action='store_true')

    render_status_parser = subparsers.add_parser('render-status')
    render_status_parser.add_argument('target')

    render_participants_parser = subparsers.add_parser('render-participants')
    render_participants_parser.add_argument('target')
    render_participants_parser.add_argument('--roles-dir', default='cursor/_roles')

    write_guard_parser = subparsers.add_parser('write-guard')
    write_guard_parser.add_argument('route')
    write_guard_parser.add_argument('paths', nargs='+')

    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    path = Path(args.registry)

    if args.command == 'validate':
        return validate_command(path)
    if args.command == 'list':
        return list_collabs(load_registry(path), args.status)
    if args.command == 'timestamp':
        return timestamp_command()
    if args.command == 'banner-timestamp':
        return banner_timestamp_command()
    if args.command == 'role-row':
        return role_row_command(Path(args.roles_dir), args.role, args.index)
    if args.command == 'roles':
        return roles_command(Path(args.roles_dir))
    if args.command == 'summary-role':
        return summary_role_command(args.line)
    if args.command == 'reviewer-state':
        return reviewer_state_command(path, args.target)
    if args.command == 'use':
        return use_collab(path, args.target)
    if args.command == 'participant':
        return add_participant(path, args.target, args.role)
    if args.command == 'join-participants':
        return join_participants(path, args.target, args.role, args.agent_id, Path(args.roles_dir))
    if args.command == 'set':
        value = '--clear' if args.clear else args.value
        return set_field(path, args.target, args.field, value, args.force)
    if args.command == 'unset':
        return unset_field(path, args.target, args.field, Path(args.roles_dir))
    if args.command == 'speak-lifecycle':
        return speak_lifecycle(path, args.target, args.contributors)
    if args.command == 'speak-state':
        return speak_state(path, args.target, args.role)
    if args.command == 'speak-lifecycle-live':
        return speak_lifecycle_live(path, args.target)
    if args.command == 'advance':
        return advance_phase(path, args.target, args.direction)
    if args.command == 'execution':
        return record_execution(
            path,
            args.target,
            args.role,
            args.status,
            args.date,
            args.assigned_role,
            args.auto_close,
            args.validation_result,
            args.touched_path,
        )
    if args.command == 'archive':
        return archive_collab(path, args.target)
    if args.command == 'delete':
        return delete_collab(path, args.target, args.yes)
    if args.command == 'render-status':
        return render_status(path, args.target)
    if args.command == 'render-participants':
        return render_participants(path, args.target, Path(args.roles_dir))
    if args.command == 'write-guard':
        return write_guard(args.route, args.paths)
    parser.error(f'unknown command: {args.command}')
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
