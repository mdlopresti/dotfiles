---
name: symphony-phase-decomposition
description: Methodology for decomposing a multi-change phase into individual OpenSpec changes BEFORE per-change proposal authoring begins, in Mike's Symphony workflow. Use this skill whenever the user mentions a multi-change phase, a roadmap with multiple OpenSpec changes per phase, decomposing an initiative into parallel/sequential changes, "phase decomposition", "phase plan", "list of changes for this phase", or when the Coordinator clarification round reveals scope clearly spans multiple changes. Also load when authoring or critiquing a phase-decomposition note, or when sequencing dependencies (`blockedBy` relations) across a batch of changes. Trigger before per-change proposals begin for any phase containing more than one OpenSpec change — single-change phases skip this step.
---

# Phase decomposition

Explicit step in Mike's Symphony Coordinator workflow that bridges roadmap (phases) and per-change planning (proposals). **For multi-change phases only.**

This skill is a methodology that applies between roadmap approval and per-change proposal authoring. Load `symphony-coordinator-workflow` for the broader stage gates and state machine; load `symphony-role-scoped-decomposition` for the role-inventory and ≤ 1-day-per-role sizing rule that this methodology depends on.

The canonical narrative source is `~/Documents/Documents/Journal/Project/Symphony/Phase decomposition.md` in Mike's Obsidian vault. Status: **Adopted 2026-05-07.**

## Why this step exists

Without phase decomposition, the Planner picks change-1 scope implicitly when authoring its proposal — there's no place where the *full* set of changes for a phase is enumerated in advance. Under role-scoped decomposition (which raises change counts and emphasizes role inventory), that implicit decomposition becomes a real visibility problem. Phase decomposition surfaces the full change list before any proposal commits scope.

## The step

For multi-change phases, between roadmap approval and per-change proposal authoring:

1. **Planner authors a phase-decomposition note.** Lists every OpenSpec change the phase decomposes into, with role coverage and dependencies.
2. **Fresh Critic red-teams the decomposition note.**
3. **Mike approves the decomposition.**
4. **Coordinator creates one Linear todo per identified change** in `Backlog`, with `blockedBy` relations reflecting dependency order.
5. Per-change proposal authoring (existing Coordinator workflow step 3) begins for the first change in execution order.

**Single-change phases skip this step entirely** — the proposal IS the decomposition.

## Artifact: phase-decomposition note

**Filename:** `<initiative-id> phase <n> decomposition.md` (e.g., `Forge Platform phase 1 decomposition.md`).

**Location:**

- **Personal stack:** Obsidian, alongside the roadmap. Same folder as `Project/Personal Infra/Roadmaps/<initiative-id>.md`.
- **Yum stacks:** `<stack>/documentation/roadmaps/<initiative-id>-phase-<n>-decomposition.md`.

**Header section:**

- Phase being decomposed (link back to the roadmap section).
- Role inventory — union of all roles touched across the phase's changes (per `symphony-role-scoped-decomposition`).
- Cross-change concerns surfaced during decomposition (handshakes, shared state, integration risks).

**Per change:**

- Change title (becomes the Linear todo title).
- One-paragraph scope sketch.
- Roles touched.
- Dependencies on other changes (`blockedBy` relations).
- Suggested execution order.
- Loose size estimate per role (≤ 1 day per role per the heuristic).

## Critic flags (phase-decomposition stage)

The Critic at this altitude is briefed differently than at proposal or decomposition stage. Flags:

- **Missing roles.** The decomposition omits role work the phase clearly needs (e.g., security work absent in a phase that touches secret bootstrap).
- **Unnecessary cross-role span.** A change spans multiple roles where a clean role-scoped split was available.
- **Artificial split.** A change is split between roles where the coupling is so tight it creates invisible cross-spec assumptions.
- **Missing dependencies.** A change blocks another but the `blockedBy` is not declared.
- **Ordering errors.** Suggested execution order is wrong (foundations not built first).
- **Sizing violations.** A change's per-role slice already exceeds 1 day at sketch level — almost certainly more under task-level detail.
- **Phase scope drift.** A change is in the list that doesn't belong to this phase per the roadmap.
- **Phase scope holes.** A phase deliverable has no change covering it.

## Critique output

Same convention as proposal/decomposition critiques: `<initiative-id> phase <n> decomposition critique <m>.md`, numbered per revision round. Lives in the same folder as the decomposition note itself.

## Linear lifecycle (for the phase-decomposition step itself)

The phase-decomposition step happens **before** any per-change Linear todos exist. Today: track out-of-band — the artifact files are the state; conversation is the channel. Once Mike approves the decomposition, the per-change todos are created and the per-change Linear flow begins as today.

Future option: Linear project milestones — one per phase — with state mirroring the phase-decomposition lifecycle. Defer until friction is felt.

No new Linear states needed today.

## Three decomposition altitudes

With this step adopted alongside `symphony-role-scoped-decomposition`, the Coordinator workflow has three nested decomposition layers:

| Altitude | Output | Author | Critique | Approve |
|---|---|---|---|---|
| **Roadmap** (multi-phase project) | Phases with hard requirements | Planner | Critic | Mike |
| **Phase decomposition** (multi-change phase) | Changes per phase, with roles + dependencies | Planner | Critic | Mike |
| **Per-change** | Proposal → tasks/design/specs deltas | Planner (twice — proposal then decomposition) | Critic (twice) | Mike (twice) |

Each altitude is progressively narrower. Each has its own artifact, its own critique cycle, its own approval. The author/critic/approver roles repeat at each layer.

## Open questions

These remain unresolved at adoption — surface to Mike when relevant:

- **Re-entering phase decomposition mid-flight.** If a new change is identified after some phase-1 changes are done, do we re-run phase decomposition, or just append-and-approve? Default: append-and-approve (light revision) unless the new change forces re-ordering of existing in-flight changes.
- **Single-change-phase edge case.** Truly single-change phases skip this step. Does the Planner make this judgment, or is it pre-declared in the roadmap? Default: roadmap signals (a phase whose deliverables clearly fit one change is annotated as such); Planner can request promotion to multi-change if it disagrees.
- **Cross-phase changes.** Some work might genuinely span phases (e.g., a runbook updated in both Phase 1 and Phase 5). Default: keep within-phase scope; treat cross-phase touches as separate per-phase changes.
