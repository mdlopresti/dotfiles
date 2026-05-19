# Linear state machine

Read this reference when transitioning a Linear todo between states, deciding which subagent to spawn next, or designing for the multi-Symphony future where separate Symphony instances poll disjoint state slices.

States track **autonomous-runner activity and queued-for-Mike work**. The Coordinator's live conversation in a terminal is *not* mirrored in state — when Mike and the Coordinator are talking through clarifications, no state transition fires.

## Diagram

```
Backlog → Proposing ⇄ Proposal Critique → Proposal Approval
        → Decomposing ⇄ Decomposition Critique → Decomposition Approval
        → Ready ⇄ In Progress ⇄ Verifying ⇄ In Review → Done
                ↑
            Blocked
```

`In Progress ⇄ Verifying` captures the verifier-failure path: verification failure transitions `Verifying → In Progress` so the implementer re-runs with the failure as continuation prompt (step 8).

`In Progress ⇄ In Review` captures the Mike-feedback path: Mike's "send back" reply at step 9 reverts `In Review → In Progress`; on implementer-done it returns through `Verifying → In Review` (verifier re-runs) and Mike re-reviews.

## State table

| State | Meaning | Owner of transition out |
|---|---|---|
| `Backlog` | Captured but not yet in planning. Default for tickets at Initiation and for deferred-bug entries. | Coordinator (after clarification closes) |
| `Proposing` | Planner-role autonomous runner active on the proposal. | Planner runner on session done |
| `Proposal Critique` | Critic-role autonomous runner active on the proposal. | Critic — back to `Proposing` on revise; forward to `Proposal Approval` on clean |
| `Proposal Approval` | Critic loop converged; queued for Mike. No autonomous runner. | Coordinator (after Mike approves in session) |
| `Decomposing` | Planner active on `tasks.md`, `design.md`, `specs/`. | Planner runner on session done |
| `Decomposition Critique` | Critic active on the decomposition. | Critic — same revise/clean fork as proposal stage |
| `Decomposition Approval` | Decomposition Critic loop converged; queued for Mike. | Coordinator → `Ready` or `Blocked` |
| `Ready` | Approved, dependencies clear, eligible for Implementer-Symphony to claim. The **only** state Implementer-Symphony will claim. | Implementer-Symphony on claim |
| `Blocked` | Approved but has unresolved `blockedBy` relations. Withheld from `Ready` until blockers close. | Coordinator on blocker-resolution (until VIL-32 lands native filtering) |
| `In Progress` | Implementer-Symphony actively executing. | Implementer runner on session done → `Verifying` |
| `Verifying` | Verification subagent active after implementer signals done. Mechanical gate before Mike's eyes. | Verifier — back to `In Progress` on fail; forward to `In Review` on pass (step 8) |
| `In Review` | Verifier passed; queued for Mike's final checkpoint approval (step 9). | Coordinator — forward to `Done` after archive on approve; back to `In Progress` on send-back |
| `Done` | Verified, archived. Terminal. | — |

## Multi-Symphony future

Today, the Coordinator orchestrates Planner / Critic / Verifier work via subagents and transitions states accordingly. Tomorrow, separate Symphony instances poll disjoint slices of active states:

- `Proposing` / `Decomposing` → Planner-Symphony
- `Proposal Critique` / `Decomposition Critique` → Critic-Symphony
- `Ready` → Implementer-Symphony
- `Verifying` → Verifier-Symphony

The Coordinator's session-orchestration role is replaced by state transitions as the trigger surface; the workflow shape is identical. Authoring the doc this way today means zero rework when those instances deploy. See VIL-53 (blocker-gate state-name parameterization) and VIL-54 (agent-driven state transitions) for orchestrator-side verification questions.

## Dependency awareness — current gap

Symphony's tracker filters by workflow state but does **not** consult Linear's `blockedBy` relations. Until VIL-32 (`tracker-dependency-awareness`, M4 backlog) ships:

- **Workaround:** the Coordinator (or Mike directly) holds dependent todos in `Blocked` state. When a blocker closes, the Coordinator promotes dependents to `Ready`. Symphony only ever sees `Ready` and claims naively.
- **Long-term:** VIL-32 lands the native filter; the Coordinator no longer mediates state transitions for dependencies.
