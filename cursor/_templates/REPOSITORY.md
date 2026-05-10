# Repository Contract

Contract between this repository (source plane) and the global Cursor runtime at `~/.cursor/*`.

## 1) System Model

The contract has three planes:

- **Source plane:** version-controlled files in this repository.
- **Global runtime plane:** `~/.cursor/*`.
- **Project overlay plane:** optional project-local `.cursor/`.

Only the source plane is authoritative. Runtime planes are derived execution contexts.

## 2) Authority Chain

Authority is strict and ordered:

1. Repo-owned executable checks and scripts:
   <!-- TODO(agent): list repo-specific validation and contract scripts -->
2. Repo-owned source files and policy documents:
   <!-- TODO(agent): describe authoritative source directories and documents -->
3. Derived runtime or generated outputs:
   <!-- TODO(agent): describe runtime mirrors, generated files, or overlays -->

## 3) Output Chain Contract

<!-- TODO(agent): describe the root outputs this repo projects or generates, their deepest dependency chains, and how each output is validated -->

## 4) Mutation Protocol and Ownership

- Must edit tracked source only.
<!-- TODO(agent): define repo-specific ownership boundaries, generated outputs, and files that must not be edited directly -->

## 5) Validation Modes

### Source Mode (required)

<!-- TODO(agent): list required source-mode validation commands -->

### Runtime Mode (required if the repo projects runtime state)

<!-- TODO(agent): list runtime or projection validation commands, or state explicitly that none exist -->

### Overlay Mode (optional)

<!-- TODO(agent): describe any project-local or environment-specific validation gates -->

## 6) Contract Versioning

Contract version: `0.1.0`.

- **Patch:** wording or validation tightening with no behavioral change.
- **Minor:** additive contract surface; backward compatible.
- **Major:** precedence, path, or ownership changes requiring migration.

## 7) Reporting Contract

<!-- TODO(agent): define the validation results and residual risks that must be reported when work completes -->
