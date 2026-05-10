#!/usr/bin/env python3
"""Validate the pilot /collab floor rules for low-tier route execution."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


PILOT_ROUTES = (
    "cursor/_functions/collab/init.md",
    "cursor/_functions/collab/join.md",
    "cursor/_functions/collab/speak.md",
    "cursor/_functions/collab/rewrite-speak.md",
    "cursor/_functions/collab/advance.md",
    "cursor/_functions/collab/restore.md",
)

MUTATION_RE = re.compile(
    r"\b(Append|Call|Create|Ensure|Mirror|Register|Seed|Set|Stop after updating|Sync|Update|Write|writes?)\b",
    re.IGNORECASE,
)
NUMBERED_STEP_RE = re.compile(r"^\d+\.\s+(.*)$")
MARKDOWN_LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


class CheckError(Exception):
    pass


def rel(root: Path, path: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def section(text: str, heading: str) -> str:
    pattern = re.compile(rf"^## {re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        raise CheckError(f"missing ## {heading}")
    start = match.end()
    next_heading = re.search(r"^##\s+", text[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(text)
    return text[start:end].strip()


def numbered_steps(steps_section: str) -> list[str]:
    steps: list[str] = []
    current: list[str] = []
    for line in steps_section.splitlines():
        if NUMBERED_STEP_RE.match(line):
            if current:
                steps.append(" ".join(current).strip())
            current = [line]
            continue
        if current and line.strip():
            current.append(line.strip())
    if current:
        steps.append(" ".join(current).strip())
    return steps


def has_floor_rule_exemption(notes: str) -> bool:
    required = (
        "Floor rule 3 compliance",
        "temporary exemption",
        "_core/route-invariant.md",
    )
    return all(token in notes for token in required)


def check_sufficiency_contract(root: Path) -> list[str]:
    path = root / "cursor/_core/route-sufficiency.md"
    if not path.exists():
        return ["cursor/_core/route-sufficiency.md: missing sufficiency contract"]
    text = path.read_text()
    errors: list[str] = []
    try:
        mechanical = section(text, "Mechanical sufficiency")
        execution = section(text, "Execution sufficiency")
    except CheckError as exc:
        return [f"cursor/_core/route-sufficiency.md: {exc}"]

    items = re.findall(r"^\d+\.\s+\*\*[^*]+\.\*\*", mechanical, re.MULTILINE)
    if len(items) < 7:
        errors.append("cursor/_core/route-sufficiency.md: mechanical rubric must expose at least seven numbered items")
    if "first checked against its own mechanical rubric" not in text:
        errors.append("cursor/_core/route-sufficiency.md: missing self-application statement")
    if "not lintable" not in execution:
        errors.append("cursor/_core/route-sufficiency.md: execution sufficiency must be marked not lintable")
    if "fresh agent" not in execution or "no prior conversation context" not in execution:
        errors.append("cursor/_core/route-sufficiency.md: execution fixture must model constrained bootstrap")
    return errors


def has_target_resolution(text: str) -> bool:
    return (
        "Registry targeting" in text
        or ("collab id" in text and "transcript path" in text)
    ) and "ABORT" in text


def has_role_phase_precondition(text: str) -> bool:
    markers = (
        "--role <role>",
        "moderator role",
        "Moderator gate",
        "active phase",
        "Completion",
        "Phase precondition",
    )
    return any(marker in text for marker in markers)


def has_write_scope(text: str) -> bool:
    markers = (
        "Write scope",
        "Execution boundary",
        "outside `.collabs/`",
        "under `.collabs/`",
        "`.collabs/registry.json`",
    )
    return any(marker in text for marker in markers)


def has_recovery_path(text: str, notes: str) -> bool:
    return (
        "Recovery path" in notes
        or "helper defect" in text
        or has_floor_rule_exemption(notes)
    )


def check_links(root: Path, path: Path, text: str) -> list[str]:
    errors: list[str] = []
    for raw_target in MARKDOWN_LINK_RE.findall(text):
        target = raw_target.strip()
        if (
            not target
            or target.startswith("#")
            or target.startswith("http://")
            or target.startswith("https://")
            or target.startswith("mailto:")
        ):
            continue
        if target.startswith("<") and target.endswith(">"):
            target = target[1:-1]
        target = target.split("#", 1)[0]
        if not target:
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"{rel(root, path)}: broken link target: {raw_target}")
        else:
            try:
                resolved.relative_to(root.resolve())
            except ValueError:
                errors.append(f"{rel(root, path)}: link target escapes repo: {raw_target}")
    return errors


def check_route(root: Path, path: Path) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"{rel(root, path)}: missing pilot route"]

    text = path.read_text()
    try:
        steps = section(text, "Steps")
        notes = section(text, "Notes")
    except CheckError as exc:
        return [f"{rel(root, path)}: {exc}"]

    parsed_steps = numbered_steps(steps)
    combined = f"{steps}\n{notes}"
    if not has_target_resolution(combined):
        errors.append(f"{rel(root, path)}: missing explicit target resolution with ABORT path")
    if not has_role_phase_precondition(combined):
        errors.append(f"{rel(root, path)}: missing role or phase precondition")
    if not any(re.match(r"^\d+\.\s+Stop\b", step) for step in parsed_steps):
        errors.append(f"{rel(root, path)}: missing explicit stop condition in Steps")
    if "speak-state --resume <target> <role>" not in notes:
        errors.append(f"{rel(root, path)}: missing post-state resume signal")
    if not has_write_scope(combined):
        errors.append(f"{rel(root, path)}: missing declared write scope")
    if not has_recovery_path(combined, notes):
        errors.append(f"{rel(root, path)}: missing recovery path or structured exemption")

    exempt = has_floor_rule_exemption(notes)
    mutating_steps = []
    for step in parsed_steps:
        if not MUTATION_RE.search(step) or "tools/collab/registry.py" in step:
            continue
        lowered = step.lower()
        if "do not " in lowered or "contribution body" in lowered:
            continue
        mutating_steps.append(step)
    if mutating_steps and not exempt:
        step_numbers = ", ".join(step.split(".", 1)[0] for step in mutating_steps)
        errors.append(
            f"{rel(root, path)}: mutating step(s) lack helper ownership or "
            f"floor-rule exemption: {step_numbers}"
        )

    errors.extend(check_links(root, path, text))
    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="repository root")
    parser.add_argument(
        "--route",
        action="append",
        default=[],
        help="repo-relative route file to check; defaults to pilot collab routes",
    )
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    routes = args.route or list(PILOT_ROUTES)

    errors: list[str] = []
    errors.extend(check_sufficiency_contract(root))
    for route in routes:
        errors.extend(check_route(root, root / route))

    if errors:
        for error in errors:
            print(f"check-collab-floor-rules: {error}", file=sys.stderr)
        return 1

    print("check-collab-floor-rules: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
