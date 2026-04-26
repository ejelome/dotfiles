#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from copy import deepcopy
from pathlib import Path


PHASES = ['Audit', 'Discussion', 'Conclusion', 'Action Plan', 'Handoff', 'Completion']
ALLOWED_SET_FIELDS = {'title', 'description', 'turn-order'}
FORCE_ONLY_FIELDS = {'active-phase'}
ALLOWED_STATUSES = {'open', 'closed', 'archived'}


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


def validate_registry(data: dict, path: Path | None = None) -> None:
    source = str(path) if path else 'registry'
    if not isinstance(data, dict):
        die(f'{source}: root must be an object')
    if data.get('schema_version') != 1:
        die(f'{source}: schema_version must be 1')

    collabs = data.get('collabs')
    if not isinstance(collabs, list):
        die(f'{source}: collabs must be a list')

    active_id = data.get('active_collab_id')
    ids: list[str] = []
    slugs: list[str] = []
    collab_map: dict[str, dict] = {}

    for entry in collabs:
        if not isinstance(entry, dict):
            die(f'{source}: collab entry must be an object')

        collab_id = entry.get('id')
        slug = entry.get('slug')
        title = entry.get('title')
        description = entry.get('description')
        status = entry.get('status')
        active_phase = entry.get('active_phase')
        moderator_role = entry.get('moderator_role')
        participants = entry.get('participants')
        turn_order = entry.get('turn_order')
        transcript_path = entry.get('transcript_path')

        for field, value in (
            ('id', collab_id),
            ('slug', slug),
            ('title', title),
            ('description', description),
            ('status', status),
            ('active_phase', active_phase),
            ('moderator_role', moderator_role),
            ('transcript_path', transcript_path),
        ):
            if not isinstance(value, str) or not value.strip():
                die(f'{source}: collab {field} must be a non-empty string')

        if status not in ALLOWED_STATUSES:
            die(f'{source}: collab status must be one of {sorted(ALLOWED_STATUSES)}')
        if active_phase not in PHASES:
            die(f'{source}: collab active_phase must be one of {PHASES}')
        if not transcript_path.startswith('.collabs/records/') or not transcript_path.endswith('.md'):
            die(f'{source}: transcript_path must stay inside .collabs/records/*.md')
        if not isinstance(entry.get('archived'), bool):
            die(f'{source}: collab archived must be a boolean')

        if not isinstance(participants, list) or not participants:
            die(f'{source}: participants must be a non-empty list')
        if not all(isinstance(role, str) and role.strip() for role in participants):
            die(f'{source}: participants must contain non-empty role strings')
        if len(set(participants)) != len(participants):
            die(f'{source}: participants must not contain duplicates')
        if moderator_role not in participants:
            die(f'{source}: moderator_role must be listed in participants')

        if not isinstance(turn_order, list) or not turn_order:
            die(f'{source}: turn_order must be a non-empty list')
        if not all(isinstance(role, str) and role.strip() for role in turn_order):
            die(f'{source}: turn_order must contain non-empty role strings')
        if len(set(turn_order)) != len(turn_order):
            die(f'{source}: turn_order must not contain duplicates')
        if not set(turn_order).issubset(set(participants)):
            die(f'{source}: turn_order must stay within participants')

        execution = entry.get('execution', {})
        if not isinstance(execution, dict):
            die(f'{source}: execution must be an object when present')

        if collab_id in collab_map:
            die(f'{source}: duplicate collab id: {collab_id}')
        ids.append(collab_id)
        slugs.append(slug)
        collab_map[collab_id] = entry

    if len(ids) != len(set(ids)):
        die(f'{source}: duplicate collab ids are not allowed')
    if len(slugs) != len(set(slugs)):
        die(f'{source}: duplicate collab slugs are not allowed')

    if active_id is not None:
        if not isinstance(active_id, str) or not active_id.strip():
            die(f'{source}: active_collab_id must be null or a non-empty string')
        if active_id not in collab_map:
            die(f'{source}: active_collab_id must point at an existing collab id')
        if collab_map[active_id].get('archived'):
            die(f'{source}: active_collab_id must not point at an archived collab')


def resolve_collab(data: dict, target: str) -> dict:
    for entry in data['collabs']:
        if target in {entry['id'], entry['slug'], entry['transcript_path']}:
            return entry
    die(f'registry target not found: {target}')


def require_active_collab(data: dict) -> dict:
    active_id = data.get('active_collab_id')
    if not active_id:
        die('registry active_collab_id is empty')
    return resolve_collab(data, active_id)


def list_collabs(data: dict) -> int:
    active_id = data.get('active_collab_id')
    for entry in data['collabs']:
        marker = '*' if entry['id'] == active_id else '-'
        print(
            f"{marker} {entry['slug']} "
            f"[{entry['status']}] "
            f"phase={entry['active_phase']} "
            f"participants={len(entry['participants'])}",
        )
    return 0


def use_collab(path: Path, target: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if entry['archived']:
        die(f'registry target archived: {target}')
    data['active_collab_id'] = entry['id']
    save_registry(path, data)
    print(entry['id'])
    return 0


def set_field(path: Path, target: str, field: str, value: str, force: bool) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    if field in FORCE_ONLY_FIELDS:
        if not force:
            die(f'field requires --force: {field}')
        if field == 'active-phase':
            if value not in PHASES:
                die(f'active-phase must be one of {PHASES}')
            entry['active_phase'] = value
    elif field not in ALLOWED_SET_FIELDS:
        die(f'field not settable: {field}')
    elif field == 'turn-order':
        turn_order = value.split()
        if not turn_order:
            die('turn-order requires at least one role')
        if len(set(turn_order)) != len(turn_order):
            die('turn-order roles must be unique')
        if not set(turn_order).issubset(set(entry['participants'])):
            die('turn-order roles must already be participants')
        entry['turn_order'] = turn_order
    else:
        if not value.strip():
            die(f'{field} requires a non-empty value')
        entry[field] = value
    save_registry(path, data)
    print(entry['id'])
    return 0


def advance_phase(path: Path, target: str, direction: str) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    index = PHASES.index(entry['active_phase'])
    if direction == 'next':
        if index == len(PHASES) - 1:
            die('no next phase')
        entry['active_phase'] = PHASES[index + 1]
    else:
        if index == 0:
            die('no previous phase')
        entry['active_phase'] = PHASES[index - 1]
    save_registry(path, data)
    print(entry['active_phase'])
    return 0


def archive_collab(path: Path, target: str, hard: bool) -> int:
    data = load_registry(path)
    entry = resolve_collab(data, target)
    transcript_path = Path(entry['transcript_path'])
    if hard:
        data['collabs'] = [candidate for candidate in data['collabs'] if candidate['id'] != entry['id']]
        if data.get('active_collab_id') == entry['id']:
            data['active_collab_id'] = None
        if transcript_path.exists():
            transcript_path.unlink()
    else:
        entry['status'] = 'archived'
        entry['archived'] = True
        if data.get('active_collab_id') == entry['id']:
            data['active_collab_id'] = None
    save_registry(path, data)
    print(entry['id'])
    return 0


def validate_command(path: Path) -> int:
    load_registry(path)
    print('registry OK')
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
    subparsers.add_parser('list')

    use_parser = subparsers.add_parser('use')
    use_parser.add_argument('target')

    set_parser = subparsers.add_parser('set')
    set_parser.add_argument('target')
    set_parser.add_argument('field')
    set_parser.add_argument('value')
    set_parser.add_argument('--force', action='store_true')

    advance_parser = subparsers.add_parser('advance')
    advance_parser.add_argument('target')
    advance_parser.add_argument('direction', choices=['next', 'prev'])

    archive_parser = subparsers.add_parser('archive')
    archive_parser.add_argument('target')
    archive_parser.add_argument('--hard', action='store_true')

    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    path = Path(args.registry)

    if args.command == 'validate':
        return validate_command(path)
    if args.command == 'list':
        return list_collabs(load_registry(path))
    if args.command == 'use':
        return use_collab(path, args.target)
    if args.command == 'set':
        return set_field(path, args.target, args.field, args.value, args.force)
    if args.command == 'advance':
        return advance_phase(path, args.target, args.direction)
    if args.command == 'archive':
        return archive_collab(path, args.target, args.hard)
    parser.error(f'unknown command: {args.command}')
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
