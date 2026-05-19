# The flow — Coordinator workflow steps 1 through 10

Read this reference when the Coordinator is orchestrating a managed-work project — at initiation, between stages, when transitioning Linear states, or when a subagent needs to know what artifacts to produce at the current stage. The 10 steps cover the full lifecycle from Mike's request to archive.

> **For multi-change phases:** between step 2 (clarification) and step 3 (per-change proposal authoring), invoke `symphony-phase-decomposition`. Single-change projects skip phase decomposition entirely.

## 1. Initiation

Mike → Coordinator: "start a project on X" in the relevant Coordinator session.

For **single-change projects**, create the Linear todo immediately in `Backlog`. For **multi-change phases**, Linear todos are created later — one per change, in a single batch, after phase decomposition is approved.

Either way, todos stay in `Backlog` until a Planner is spawned. No state transition fires while Mike and the Coordinator are talking — no autonomous runner is involved yet. Implementer-Symphony only ever claims `Ready`. Creating tickets up front gives every artifact a stable identifier; it does not commit to scope.

## 2. Clarification round

**Ask clarifying questions before doing anything else.** Targets:

- **Scope** — what's in, what's out, what's a future phase
- **Success criteria** — how will Mike know this is done
- **Hard constraints** — deadlines, compatibility requirements, things that must not change
- **Stakeholders** — who else cares, who reviews, who depends on it
- **Repo / app stack** — confirm the target so the Planner is loaded right

Never proceed to Planning while ambiguity remains. Better to ask three questions than assume one wrong thing. Cap questions at the genuinely-needed set; voice dictation makes long question batches friction.

## 3. Planning (proposal stage)

Transition the Linear todo to `Proposing`. Spawn a Planner subagent with the clarified goal plus full repo + Linear context. Planner produces:

- **Small project:** the proposal artifact — `proposal.md` plus `.openspec.yaml` — lands in the change directory.
- **Larger project:** roadmap doc lands first (in the repo or stack docs repo), then the *first* `proposal.md`. Subsequent proposals authored just-in-time as their phase approaches.

How the artifact "lands" depends on commit policy: personal-stack Implementer-Symphony work uses PR-flow per VIL-216 (per-todo worktree branch → PR against `main`); Yum-stack uses direct-to-`dev`; Mike-paired Symphony platform-repo work uses direct-to-`main` (see SKILL.md's "Commit policy" section). All flows treat Mike's approval at `Proposal Approval` as the signal to proceed.

**Only `proposal.md` (and `.openspec.yaml`) at this stage.** No `tasks.md`, no `design.md`, no `specs/` deltas yet. The proposal must stand on its own for review without enumerating tasks; if scope cannot be evaluated without the task list, the proposal is too vague.

OpenSpec skill at this step: `openspec-new-change` for proposal scaffolding.

## 4. Critique (proposal stage)

On Planner session done, transition to `Proposal Critique`. Spawn a fresh Critic subagent. **Critic receives only `proposal.md` and `.openspec.yaml`** — no Planner notes, no prior conversation, no Coordinator framing.

Critique lands as `openspec/changes/<change-id>/proposal-critique-<n>.md` (numbered per revision round, starting at `proposal-critique-1.md`) — a stable file artifact regardless of forge state. Under PR-flow, also cross-post as a PR comment; the file remains canonical. For multi-change projects, roadmap-stage critique lands alongside the roadmap.

**Proposal-stage Critic flags:**

- Implementation detail leaking into the proposal/roadmap
- Hard requirements missing or under-specified
- Proposals exceeding **1 day per role** (load `symphony-role-scoped-decomposition`; request a role-scoped split)
- Sequencing errors / missing dependencies
- Scope ambiguity that should have surfaced in the clarification round (feedback on Coordinator's own performance)
- **Bugs found in adjacent code while reading the repo for context** — these are deferred-bug candidates, not in-scope fixes

Re-spawn a fresh Critic on each Planner revision; never reuse a Critic across iterations.

## 5. Iteration

**Default mode: autonomous.** Run the Planner-revise → fresh-Critic → re-critique loop without per-round Mike gating. Mike sees the loop output only when it converges (clean Critic verdict) or when an escalation condition fires.

**State oscillation.** Each revision round transitions the Linear todo back to `Proposing` and forward to `Proposal Critique`. The oscillation is the multi-Symphony future's claim signal — do it today exactly so each future Symphony instance can rely on the transition to claim. On a clean Critic verdict, transition to `Proposal Approval` (queued for Mike).

**Escalation conditions** (Coordinator pauses and brings Mike in):

- Revision count on a single artifact exceeds **12 rounds** — probably stuck in a critic-vs-planner taste disagreement that needs Mike's call. Pause and recommend switching that artifact to gated mode (Mike reviews each revision). Threshold tuned by experience; raise or lower if 12 turns out wrong in practice.
- Critic identifies a missing hard requirement that wasn't in Mike's clarification answers — pause to confirm scope before the Planner invents one.

Step 6 inherits these escalations for decomposition-stage iteration and adds one more — the "Revise proposal first" verdict (see step 6).

**Gated mode** (per-round Mike review) remains available on request — for sensitive areas, contested scope, or when autonomous has stalled. Use it as the exception, not the default.

OpenSpec skills: `openspec-continue-change` for revisions; `openspec-ff-change` for fast-forward (no semantic change, just cleanup the critic flagged).

## 6. Decomposition (post-approval)

On Mike's approval at `Proposal Approval`:

- Proposal artifact (and roadmap, if any) is finalized.
- Transition the Linear todo to `Decomposing` and re-engage the Planner to flesh out the OpenSpec change directory: `tasks.md` (implementer's checklist), `design.md` (implementation sketch), `specs/` deltas.
- On Planner session done, transition to `Decomposition Critique`. Spawn a fresh Critic subagent on the fleshed-out change directory. Same context-isolation rule. Critique lands as `decomposition-critique-<n>.md`.

**Decomposition-stage Critic flags:**

- `tasks.md` doesn't cover the proposal scope (missing tasks for stated proposal items)
- `design.md` invents work outside approved scope
- `specs/` deltas don't align with the proposal's stated capability changes
- Scope exceeds **1 day per role** (load `symphony-role-scoped-decomposition`; request split or revise)
- **Role-scoping violations both directions** — multi-role spans where a clean split was available, OR artificial splits creating invisible cross-spec assumptions
- Hidden ambiguity that became visible only with task-level detail (sometimes the right move is back to step 4 to revise the proposal)
- Bugs in adjacent code → deferred-bug candidates, not in-scope fixes

Same autonomous-by-default iteration rules as step 5. State oscillates between `Decomposing` and `Decomposition Critique` per round. Clean Critic verdict → `Decomposition Approval`.

**"Revise proposal first" verdict.** When the decomposition-stage Critic concludes that the right fix is back in the proposal itself:

- **Default:** pause and surface the verdict to Mike. The proposal was already approved; reopening it is a deliberate decision.
- **Exception — straight reversion:** if the Critic's recommended proposal revision is *just reverting decisions Mike already made* (often because the Critic doesn't see the rationale that was hashed out in the clarification round), continue without escalating. The clarification round IS the record of those decisions; note the rejected reversion in the change directory and proceed.

On Mike's approval at `Decomposition Approval`:

- Update the Linear todo with title refinements, link to change, `blockedBy` dependencies.
- Transition to `Ready` — or to `Blocked` if it has unresolved dependencies.

OpenSpec skills: `openspec-continue-change` for fleshing out and Critic-driven revisions; `openspec-ff-change` for fast-forward revisions.

## 7. Implementation

Implementer-Symphony picks up `Ready` todos and transitions them to `In Progress` on claim:

- Spawn the implementer (Claude or Copilot) with the full OpenSpec change directory as primary context.
- **Pre-edit audit.** Implementer first records a short audit pass — what files it intends to touch, what existing patterns it found, what it confirmed about the surrounding code — before any edit. Lands in the change directory as `audit.md`. Reduces the "I edited the wrong layer" failure mode.
- Commit per current commit policy: personal Implementer-Symphony work uses PR-flow (per VIL-216 — per-todo worktree branch `symphony/<tracker>/<issue>` → PR against `main` via `mcp__forgejo__create_pull_request`); Yum uses direct-to-`dev`; Mike-paired Symphony platform-repo work uses direct-to-`main`.
- On implementer session done, transition to `Verifying` (step 8). Uniform across both flows. Mike does not have the ball yet — the mechanical verifier runs first.
- **Implementer never archives the change directory.** Archive is exclusively a Coordinator action gated on Mike's checkpoint approval (step 9), which itself is gated on verifier pass (step 8).

OpenSpec skill: `openspec-apply-change` is the implementer's primary entry point.

## 8. Verification

**First gate after implementer signals done.** Implementer transitions `In Progress → Verifying` on session done. Coordinator (or the Verifier-Symphony role, when deployed) spawns a fresh verification subagent (context-isolated, like the Critic). Run OpenSpec's built-in verification against the change directory and the working tree. **Mechanical check before Mike's eyes** — surfacing spec-vs-code drift to Mike *before* his approval lets him weigh that information into the checkpoint review at step 9.

OpenSpec skill: `openspec-verify-change`.

- Confirm `tasks.md` checkboxes match actual code state, `specs/` deltas reflected in codebase, no spec-vs-code drift.
- **Failure** → transition `Verifying → In Progress`; failure becomes a continuation prompt to the implementer. Re-verify after fix.
- **Pass** → transition `Verifying → In Review` (queued for Mike's final approval, step 9). Verifier's pass-report is surfaced to Mike alongside the change for his checkpoint review.

## 9. Checkpoint review

**Final gate before archive.** Mike reviews the PR (or commit, depending on the change's commit policy) directly, with the verifier's pass-report from step 8 as additional context. The plan was the Coordinator's value-add; review is Mike's. The Coordinator does not re-review.

Mike's signal back is a reply in the Coordinator session — uniform across both commit policies. Two outcomes:

- **Approve** ("LGTM" or equivalent) → run archive (step 10) and transition `In Review → Done` once archive lands.
- **Send back with feedback** → Mike's feedback IS the continuation directive. Transition `In Review → In Progress`, pipe the feedback into Symphony's continuation prompt to the implementer, re-run. On done, transition back through `Verifying → In Review` and Mike re-reviews.

Same signal pattern (reply in Coordinator session, Coordinator transitions Linear state) is used for Mike-gated transitions at `Proposal Approval → Decomposing` (step 6 entry) and `Decomposition Approval → Ready/Blocked` (step 6 exit).

## 10. Archive & completion

On Mike's checkpoint approval (step 9):

- **Coordinator** (not implementer) moves the OpenSpec change to `openspec/changes/archive/YYYY-MM-DD-<id>/`.
- OpenSpec skill: `openspec-archive-change`.
- Finalize the Linear todo to `Done`. Re-evaluate dependent `Blocked` todos and promote to `Ready` if their blockers are now closed (until VIL-32 ships native dependency awareness).
- Append any deferred-bug entries surfaced during the change to the project's deferred-bug list and file them as new Linear todos in `Backlog`.
- For phased / multi-change projects, re-engage the Planner for the next phase with completed-phase artifacts as context.
