#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path


SCHEMA_VERSION = 1
STAGES = {'audit', 'align', 'gate'}
RERUN_MODES = {'abort', 'resume', 'replace'}
ROLE_KEY_RE = re.compile(r'^[a-z][a-z0-9-]*$')
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CURSOR_ROOT = Path(os.environ.get('CURSOR_CONFIG_ROOT', ROOT)).expanduser().resolve()
DEFAULT_ROLES_DIR = DEFAULT_CURSOR_ROOT / '_roles'
DEFAULT_NARRATIVE_GLOBS = ['**/*.md', '**/*.mdc']


def die(message: str) -> None:
    raise SystemExit(message)


def today() -> str:
    return dt.date.today().isoformat()


def state_path(repo_root: Path, day: str | None = None) -> Path:
    return repo_root / '.revamps' / f'{repo_root.name}-{day or today()}.json'


def read_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        die(f'state invalid JSON: {path}: {exc}')
    validate_state(data, path)
    return data


def write_json(path: Path, data: dict) -> None:
    validate_state(data, path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n')


def validate_string_list(data: dict, field: str, source: Path) -> None:
    value = data.get(field)
    if not isinstance(value, list) or any(not isinstance(item, str) or not item for item in value):
        die(f'{source}: {field} must be an array of non-empty strings')


def validate_concern_requirements(data: dict, source: Path) -> None:
    value = data.get('concernRequirements')
    if not isinstance(value, dict) or not value:
        die(f'{source}: concernRequirements must be a non-empty object')
    previous_defaults = {
        'audit': ['judgment', 'risk'],
        'align': ['effectiveness', 'completeness'],
        'gate': ['effectiveness', 'completeness'],
    }
    if value == previous_defaults:
        die(f'{source}: concernRequirements must use role-derived concerns, not old phase defaults')
    role_bindings = data.get('roleBindings')
    for stage, concerns in value.items():
        if stage not in STAGES:
            die(f'{source}: concernRequirements keys must be one of {sorted(STAGES)}')
        if (
            not isinstance(concerns, list)
            or any(not isinstance(item, str) or not item for item in concerns)
        ):
            die(f'{source}: concernRequirements.{stage} must be an array of non-empty strings')
        if not isinstance(role_bindings.get(stage), str) or not role_bindings[stage]:
            die(f'{source}: roleBindings.{stage} must be set when concernRequirements.{stage} is set')


def validate_state(data: dict, source: Path) -> None:
    if not isinstance(data, dict):
        die(f'{source}: state must be an object')
    if data.get('schemaVersion') != SCHEMA_VERSION:
        die(f'{source}: schemaVersion must be {SCHEMA_VERSION}')
    for field in ('repoRoot', 'activeStage', 'createdOn', 'updatedOn'):
        if not isinstance(data.get(field), str) or not data[field]:
            die(f'{source}: {field} must be a non-empty string')
    if data['activeStage'] not in STAGES:
        die(f'{source}: activeStage must be one of {sorted(STAGES)}')
    for field in ('narrativeGlobs', 'ruleAlignTargets', 'validationCommands'):
        validate_string_list(data, field, source)
    for field in ('roleBindings', 'phaseOutputs'):
        if not isinstance(data.get(field), dict):
            die(f'{source}: {field} must be an object')
    validate_concern_requirements(data, source)


def role_concerns(roles_dir: Path, role: str) -> list[str]:
    if not ROLE_KEY_RE.fullmatch(role):
        die(f'invalid role key: {role}')
    path = roles_dir / f'{role}.json'
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        die(f'role file unreadable: {path}')
    except json.JSONDecodeError as exc:
        die(f'role invalid JSON: {path}: {exc}')
    if data.get('key') != role:
        die(f'{path}: key must be {role}')
    concerns = data.get('concerns')
    if (
        not isinstance(concerns, list)
        or any(not isinstance(item, str) or not item for item in concerns)
    ):
        die(f'{path}: concerns must be an array of non-empty strings')
    return concerns


def bind_role(state: dict, stage: str, role: str, roles_dir: Path) -> None:
    state['roleBindings'][stage] = role
    state['concernRequirements'][stage] = role_concerns(roles_dir, role)


def discover_validation_commands(repo_root: Path) -> list[str]:
    repository = repo_root / 'REPOSITORY.md'
    if repository.exists():
        text = repository.read_text()
        commands = re.findall(r'`([^`]*(?:tests/run\.sh|tools/smoke-check\.sh)[^`]*)`', text)
        if commands:
            return sorted(dict.fromkeys(commands))

    package = repo_root / 'package.json'
    if package.exists():
        try:
            scripts = json.loads(package.read_text()).get('scripts', {})
        except json.JSONDecodeError:
            scripts = {}
        commands = [f'npm run {name}' for name in scripts if name in {'test', 'lint', 'typecheck'}]
        if commands:
            return commands

    tools = repo_root / 'tools'
    if tools.exists():
        commands = []
        for path in sorted(tools.glob('*.sh')):
            if os.access(path, os.X_OK):
                commands.append(f'./tools/{path.name}')
        if commands:
            return commands
    return []


def base_state(repo_root: Path, stage: str, validation_commands: list[str]) -> dict:
    day = today()
    return {
        'schemaVersion': SCHEMA_VERSION,
        'repoRoot': str(repo_root),
        'activeStage': stage,
        'createdOn': day,
        'updatedOn': day,
        'narrativeGlobs': list(DEFAULT_NARRATIVE_GLOBS),
        'ruleAlignTargets': [],
        'validationCommands': validation_commands,
        'roleBindings': {},
        'concernRequirements': {},
        'phaseOutputs': {},
    }


def load_for_transition(path: Path, rerun_mode: str, replacement: dict | None = None) -> dict:
    exists = path.exists()
    if exists and rerun_mode == 'abort':
        die(f'state exists; choose resume or replace: {path}')
    if exists and rerun_mode in {'resume', 'replace'} and replacement is None:
        return read_json(path)
    if exists and rerun_mode == 'resume':
        return read_json(path)
    if replacement is None:
        die(f'state missing: {path}')
    return replacement


def runtime_guard(repo_root: Path, runtime_root: Path) -> None:
    repo_cursor = (repo_root / 'cursor').resolve()
    runtime = runtime_root.resolve()
    if runtime == repo_cursor:
        die(f'align runtime root resolves to repository cursor tree: {runtime_root}')
    if not runtime.exists():
        die(f'align runtime root missing: {runtime_root}')


def enumerate_rule_align_targets(repo_root: Path, runtime_root: Path) -> list[str]:
    local = sorted(
        path for path in repo_root.rglob('*.mdc')
        if '.git' not in path.parts and '.revamps' not in path.parts
    )
    runtime_rules = runtime_root / 'rules'
    global_rules = sorted(runtime_rules.glob('*.mdc')) if runtime_rules.exists() else []
    targets = [str(path.relative_to(repo_root)) for path in local]
    targets.extend(f'~/.cursor/rules/{path.name}' for path in global_rules)
    return sorted(dict.fromkeys(targets))


def audit_command(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve()
    path = Path(args.state) if args.state else state_path(repo_root, args.date)
    commands = args.validation_command or discover_validation_commands(repo_root)
    state = load_for_transition(path, args.rerun_mode, base_state(repo_root, 'audit', commands))
    state['activeStage'] = 'audit'
    state['updatedOn'] = today()
    if args.validation_command:
        state['validationCommands'] = args.validation_command
    bind_role(state, 'audit', args.role, Path(args.roles_dir))
    write_json(path, state)
    print(path)
    return 0


def align_command(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve()
    path = Path(args.state) if args.state else state_path(repo_root, args.date)
    runtime_root = Path(args.runtime_root).expanduser()
    runtime_guard(repo_root, runtime_root)
    state = load_for_transition(path, args.rerun_mode)
    state['activeStage'] = 'align'
    state['updatedOn'] = today()
    state['ruleAlignTargets'] = enumerate_rule_align_targets(repo_root, runtime_root)
    bind_role(state, 'align', args.role, Path(args.roles_dir))
    write_json(path, state)
    print(path)
    return 0


def gate_command(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve()
    path = Path(args.state) if args.state else state_path(repo_root, args.date)
    state = load_for_transition(path, args.rerun_mode)
    if not state['validationCommands']:
        die(f'{path}: validationCommands must not be empty before gate')
    state['activeStage'] = 'gate'
    state['updatedOn'] = today()
    bind_role(state, 'gate', args.role, Path(args.roles_dir))
    write_json(path, state)
    print('\n'.join(state['validationCommands']))
    return 0


def guard_command(args: argparse.Namespace) -> int:
    runtime_guard(Path(args.repo_root).resolve(), Path(args.runtime_root).expanduser())
    print('ok')
    return 0


def validate_command(args: argparse.Namespace) -> int:
    read_json(Path(args.state))
    print('state OK')
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='Narrative state helper.')
    subparsers = parser.add_subparsers(dest='command', required=True)

    path_parser = subparsers.add_parser('path')
    path_parser.add_argument('--repo-root', default='.')
    path_parser.add_argument('--date')

    for name in ('audit', 'align', 'gate'):
        item = subparsers.add_parser(name)
        item.add_argument('--repo-root', default='.')
        item.add_argument('--state')
        item.add_argument('--date')
        item.add_argument('--role', required=True)
        item.add_argument('--roles-dir', default=str(DEFAULT_ROLES_DIR))
        item.add_argument('--rerun-mode', choices=sorted(RERUN_MODES), default='abort')
        if name == 'audit':
            item.add_argument('--validation-command', action='append', default=[])
        if name == 'align':
            item.add_argument('--runtime-root', default='~/.cursor')

    guard_parser = subparsers.add_parser('guard-runtime')
    guard_parser.add_argument('--repo-root', default='.')
    guard_parser.add_argument('--runtime-root', default='~/.cursor')

    validate_parser = subparsers.add_parser('validate')
    validate_parser.add_argument('state')

    return parser


def main(argv: list[str]) -> int:
    args = build_parser().parse_args(argv)
    if args.command == 'path':
        print(state_path(Path(args.repo_root).resolve(), args.date))
        return 0
    if args.command == 'audit':
        return audit_command(args)
    if args.command == 'align':
        return align_command(args)
    if args.command == 'gate':
        return gate_command(args)
    if args.command == 'guard-runtime':
        return guard_command(args)
    if args.command == 'validate':
        return validate_command(args)
    die(f'unknown command: {args.command}')
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
