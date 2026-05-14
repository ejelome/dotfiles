#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path


TOKEN_RE = re.compile(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$')
TABLE_ROW_RE = re.compile(r'^\|[^|]+\|\s*`([^`]+)`\s*\|$')
SLASH_RE = re.compile(r'^\*\*Slash:\*\*\s+`([^`]+)`\s*$')

STRICT_NAMESPACES = {'collab', 'doc', 'quality', 'narrative'}
TOOL_DOMAIN_NAMESPACES = {'git'}
COMMAND_FILE_EXCEPTIONS = {'commands.md'}
PRIVATE_FUNCTION_EXCEPTIONS = {'init-helper-spec.md'}


def die(message: str) -> None:
    raise SystemExit(f'check-cursor-naming: {message}')


def valid_token(value: str) -> bool:
    return bool(TOKEN_RE.match(value))


def load_reserved_verbs(root: Path) -> set[str]:
    naming = root / 'cursor/_core/command-convention.md'
    if not naming.exists():
        die(f'missing naming standard: {naming}')
    verbs: set[str] = set()
    for line in naming.read_text().splitlines():
        match = TABLE_ROW_RE.match(line.strip())
        if not match:
            continue
        first = match.group(1).split()[0]
        if valid_token(first):
            verbs.add(first)
    if not verbs:
        die('reserved-form table has no parseable verbs')
    return verbs


def slash_for(path: Path) -> str | None:
    for line in path.read_text().splitlines():
        match = SLASH_RE.match(line.strip())
        if match:
            return match.group(1)
    return None


def iter_helper_subcommands(path: Path) -> list[str]:
    tree = ast.parse(path.read_text(), filename=str(path))
    names: list[str] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        if not isinstance(node.func, ast.Attribute) or node.func.attr != 'add_parser':
            continue
        if not node.args:
            continue
        value = node.args[0]
        if isinstance(value, ast.Constant) and isinstance(value.value, str):
            names.append(value.value)
    return sorted(set(names))


def validate_command_files(root: Path, failures: list[str]) -> None:
    commands = root / 'cursor/commands'
    for path in sorted(commands.glob('*.md')):
        if path.name in COMMAND_FILE_EXCEPTIONS:
            continue
        namespace = path.stem
        if not valid_token(namespace):
            failures.append(f'{path}: namespace must be lowercase kebab-case')
        if namespace.endswith('s') and namespace not in TOOL_DOMAIN_NAMESPACES:
            failures.append(f'{path}: namespace should be singular')


def validate_function_slash(root: Path, verbs: set[str], failures: list[str]) -> None:
    functions = root / 'cursor/_functions'
    for path in sorted(functions.glob('*/*.md')):
        namespace = path.parent.name
        if path.name.startswith('_'):
            continue
        if path.name in PRIVATE_FUNCTION_EXCEPTIONS:
            continue
        if not valid_token(path.stem):
            failures.append(f'{path}: function filename must be lowercase kebab-case')
        if path.stem.startswith('re-'):
            failures.append(f'{path}: re-* route filenames are retired; use rewrite <target>')

        slash = slash_for(path)
        if slash is None:
            failures.append(f'{path}: missing **Slash:** declaration')
            continue
        parts = slash.split()
        if not parts or parts[0] != f'/{namespace}':
            failures.append(f'{path}: slash namespace must match _functions/{namespace}')
            continue
        route_tokens = parts[1:]
        if namespace == 'test' and not route_tokens:
            continue
        if not route_tokens:
            failures.append(f'{path}: slash route must include a verb')
            continue
        for token in route_tokens:
            if token.startswith('--'):
                break
            if token.startswith('_') and namespace != 'test':
                failures.append(f'{path}: underscore route targets are reserved for /test')
            comparable = token[1:] if token.startswith('_') else token
            if not valid_token(comparable):
                failures.append(f'{path}: invalid route token: {token}')
            if token.startswith('re-'):
                failures.append(f'{path}: re-* route tokens are retired; use rewrite <target>')

        verb = route_tokens[0]
        if namespace in STRICT_NAMESPACES and verb not in verbs:
            failures.append(f'{path}: unknown reserved verb: {verb}')
        if verb == 'rewrite' and len(route_tokens) < 2:
            failures.append(f'{path}: rewrite requires a target')


def validate_helper_subcommands(root: Path, failures: list[str]) -> None:
    helper = root / 'tools/collab/registry.py'
    for name in iter_helper_subcommands(helper):
        if not all(valid_token(part) for part in name.split('-')):
            failures.append(f'{helper}: helper subcommand must be kebab-case: {name}')
        if name.startswith('re-'):
            failures.append(f'{helper}: re-* helper subcommands are retired: {name}')


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description='Validate Cursor command naming conventions.')
    parser.add_argument('--root', default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    root = Path(args.root)
    failures: list[str] = []
    verbs = load_reserved_verbs(root)
    validate_command_files(root, failures)
    validate_function_slash(root, verbs, failures)
    validate_helper_subcommands(root, failures)
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print('check-cursor-naming: OK')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
