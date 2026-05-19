# Artifacts

Read this reference when authoring, naming, or locating any Symphony workflow artifact (proposals, change directories, roadmaps, phase-decomposition notes, critiques, audits, deferred-bug lists, Linear todos, checkpoints).

## Proposal

`openspec/changes/<change-id>/proposal.md` plus `.openspec.yaml`. The first reviewable artifact: why, what changes, scope, out-of-scope. **Authored BEFORE tasks/design/specs.**

Slug-only directory names (no date prefix — the OpenSpec CLI prepends the date at archive time). Doubled prefixes break `openspec status --change`.

## Full OpenSpec change

Adds `tasks.md`, `design.md`, and `specs/` deltas to the proposal. Authored only after proposal approval.

Each change is scoped to **≤ 1 day per role** per `symphony-role-scoped-decomposition`. Most changes are single-role; tightly-coupled cross-role changes are allowed when forcing a split would create invisible cross-spec assumptions.

Spec delta structure: `### Requirement:` blocks with first body line containing `SHALL` or `MUST` (the OpenSpec validator parses line-by-line) and at least one `#### Scenario:` in `WHEN` / `THEN` form.

## Phase-decomposition note

For multi-change phases, lists every OpenSpec change the phase decomposes into (title, scope sketch, roles touched, dependencies, order). Authored by the Planner, critiqued by the Critic, approved by Mike, **before** per-change proposal authoring begins.

Lives alongside the roadmap (Obsidian for personal stack, stack docs repo for Yum). See `symphony-phase-decomposition` for the full methodology. Single-change phases skip this artifact.

## Roadmap

For projects requiring multiple OpenSpec changes. Location depends on shape:

| Project shape | Roadmap location |
|---|---|
| Single OpenSpec change | No roadmap. Proposal IS the plan. |
| Multiple changes, one repo | In that repo at `openspec/roadmaps/<initiative-id>.md`. |
| Multiple changes, multiple repos | Stack-specific (table below). |

For multi-repo initiatives:

| Stack | Roadmap location | Status |
|---|---|---|
| Personal | Obsidian — `Project/Personal Infra/Roadmaps/<initiative-id>.md` | Folder bootstrapped 2026-05-06. |
| `yummsapim` (and other Yum stacks) | GitLab — `<stack>/documentation` repo. For `yummsapim`: `yummsapim/documentation`. | `yummsapim/documentation` already exists; cloned locally at `~/source/gitlab/yummsapim/documentation`. |

The asymmetry (Obsidian for personal, git for Yum) is **audience-access driven, not stylistic**. Personal-stack roadmaps are read only by Mike, Coordinator, and Planner — all in Mike's home directory. Yum-stack roadmaps must be reachable from GitLab-based agents (Copilot) and possibly coworkers, so git is required.

**Roadmap content:** phase summaries, dependencies, and **hard requirements** the changes must satisfy. NOT implementation specifics. For follow-up phases, brief summary + hard requirements only — full proposals come just-in-time as each phase begins.

## Linear todo

**One per OpenSpec change**, NOT one per task within a change. Created at Initiation in `Backlog`, carried through to `Done`. Holds title, link to OpenSpec change, dependencies (`blockedBy` relations), and state. No descriptive content; the OpenSpec change is the source of truth. The `tasks.md` inside a change is the implementer's internal checklist, never surfaced as separate Linear todos.

## Checkpoint artifact

Per current commit policy (see SKILL.md's "Commit policy" section): for personal-stack Implementer-Symphony work, a Forgejo PR opened against `main` per VIL-216 (one Linear todo = one PR); for Yum, the merged commit on `dev`; for Mike-paired Symphony platform-repo work, the direct commit on `main`.

## Pre-edit audit

`openspec/changes/<change-id>/audit.md`, written by the implementer before any edit. Records intended file scope, surrounding patterns, and assumptions. Reviewed by the verification subagent.

## Critique

`openspec/changes/<change-id>/proposal-critique-<n>.md` and `decomposition-critique-<n>.md`, numbered per revision round. Stable file artifact for Critic output across both PR-flow and direct-commit flows. Under PR-flow, the file is also reachable via the PR's diff but the file remains canonical.

## Deferred-bug list

`openspec/changes/<change-id>/deferred-bugs.md`, accumulated during the change's life. Pattern for handling bugs found *outside the current change's approved scope* — by the Critic during reads, by the implementer during pre-edit audit, or by the verification subagent.

- **Never** fold these into the current change. Doing so makes the change unbounded and pollutes the spec-delta record.
- Coordinator collects them in the per-change `deferred-bugs.md` while the change is open.
- On archive, promote each entry to a new Linear todo in `Backlog` with title + one-line description + link to where it was first noticed.
- Mike triages the backlog separately. Each promoted todo runs the full Coordinator → Planner → Critic flow if it warrants more than a fast-path fix.

The point: stop the implementer (and the Critic) from quietly expanding the blast radius of an approved change because they noticed something else broken. Surface the bug, defer the work.
