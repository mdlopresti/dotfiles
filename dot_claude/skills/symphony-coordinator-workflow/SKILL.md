---
name: symphony-coordinator-workflow
description: The Coordinator operating pattern for Mike's Symphony — multi-stage AI-implementer-orchestrated software work tracked in Linear with OpenSpec changes. Use this skill whenever the user mentions starting a Symphony project, opening a Coordinator session, kicking off managed work, working an OpenSpec change end-to-end, the plan→critique→implement→verify loop, the Linear stage gates (Proposing, Proposal Critique, Decomposing, Verifying, etc.), spawning planner / critic / implementer / verifier subagents, deferred-bug handling, or the archive ritual. Also trigger when the topic is "managed software work", "Linear-tracked initiative", "multi-stage planning loop", or any work that needs clarification → proposal → critique → decomposition → implementation → verification → archive — even if "Symphony" isn't named explicitly. Skip for fast-path single-edit work where Mike pairs directly with Claude in a repo (that path is explicitly out of scope here).
---

# Symphony Coordinator Workflow

The operating pattern for Mike's managed software work — Coordinator-orchestrated planning + AI-implementer-executed changes against Linear-tracked initiatives. Applies to both Mike's personal infrastructure stack and Yum application stacks (`yummsapim` etc.), with stack differences captured below.

## Companion skills

This skill is the spine. Two related methodologies live in their own skills and apply at specific moments — load them when relevant:

- `symphony-role-scoped-decomposition` — the **≤ 1 day per role per change** sizing heuristic. Load when a Planner is sizing a proposal/decomposition or a Critic is checking day-budget.
- `symphony-phase-decomposition` — the methodology for multi-change phases (between roadmap approval and per-change proposal authoring). Load when scope clearly spans multiple OpenSpec changes.

## Reference files

The detailed content of this workflow is split into reference files under `references/`. Load whichever apply to the current task:

- **`references/the-flow.md`** — the 10-step flow (Initiation → Clarification → Planning → Critique → Iteration → Decomposition → Implementation → Verification → Checkpoint review → Archive). Read at the start of any managed-work project, or when transitioning between stages.
- **`references/state-machine.md`** — the Linear state machine: state diagram, full state table with transition ownership, multi-Symphony future, dependency-awareness gap. Read when transitioning a Linear todo or designing for forward-compatibility with multi-Symphony deployment.
- **`references/artifacts.md`** — full artifact taxonomy (proposal, change directory, roadmap, phase-decomposition note, critique, audit, deferred-bug list, Linear todo, checkpoint). Read when authoring, naming, or locating any artifact.
- **`references/lessons.md`** — cross-cutting lessons applied (spec-pins-observables, vendor-and-adapt, validator structural rule, force-converge thresholds, dual-signal observation, time-boxes, default-suite contracts). Read when authoring or critiquing OpenSpec proposals/decomposition/specs.

## Canonical narrative source

The canonical narrative source for this workflow is `~/Documents/Documents/Journal/Project/Symphony/Coordinator Workflow.md` in Mike's Obsidian vault. This skill (SKILL.md + references/) is the agent-consumable mirror. If they ever conflict, **Obsidian wins** — Mike edits there; the skill is a derived artifact synced manually.

## Roles

| Role | Who | Lifetime | Job |
|---|---|---|---|
| **Mike** | The user | — | Approves proposals, reviews PRs/checkpoints, makes taste calls. The single point where verdicts enter the workflow. |
| **Coordinator** | Claude in terminal (this session, when invoked for managed work) | Per project (default); persistent only for interconnected multi-project initiatives | Receive Mike's project request. Ask clarifying questions BEFORE doing anything else. Spawn Planner only after ambiguity is resolved. Spawn fresh Critic subagents to red-team Planner output at proposal AND decomposition stages — never red-team directly (the Coordinator accumulates context across iterations and stops being a credible cold reader). Relay Mike's feedback back to the Planner. Never executes implementation. |
| **Planner** | Claude subagent spawned by Coordinator | Per planning round, one-shot; re-spawn for revisions or for the next phase | Read repo + Linear context. Produce `proposal.md` first; flesh out the full OpenSpec change (`tasks.md`, `design.md`, `specs/` deltas) only after proposal approval. |
| **Critic** | One-shot Claude subagent spawned by Coordinator | Per critique pass — once at proposal stage, once at decomposition stage. Re-spawned fresh on each Planner revision | Read **only** the artifact under review. No Coordinator session history, no Planner internals, no Mike-feedback context. Output critique as a stable file in the change directory. |
| **Implementer** | **Personal:** Claude. **Yum:** GitHub Copilot. Spawned by Symphony per Linear todo | Per Linear todo | Execute one OpenSpec change end-to-end against its proposal/tasks/design/specs. Record a pre-edit audit. Commit per current commit policy (personal: per-todo worktree branch → PR against `main` per VIL-216; Yum: direct to `dev`). Never self-merges, never archives — both are the Coordinator's job. |
| **Verifier** | Fresh context-isolated Claude subagent spawned by Coordinator after implementer signals done (step 8) — runs *before* Mike's checkpoint review so spec-vs-code drift is surfaced before approval | Per verification pass | Run OpenSpec's built-in verification against the change directory and the working tree. Confirm `tasks.md` ↔ code ↔ `specs/` deltas align. Send back to `In Progress` on failure (continuation prompt to implementer); transition to `In Review` on success (queued for Mike). |

## Coordinator state and persistence

The Coordinator's durable state across sessions lives in three stores; conversation history is treated as ephemeral.

1. **Auto-memory** at `~/.claude/projects/-var-home-mike/memory/` — conventions, preferences, references that outlive any one conversation.
2. **Obsidian** at `Project/Symphony/` plus per-project subfolders — durable narrative (decisions, status snapshots, links to artifacts).
3. **Linear** — the live state of work in flight (Backlog → Done).

If a fact is worth remembering across sessions, it lives in one of those three stores. There is no separate "Coordinator session file."

## State machine summary

```
Backlog → Proposing ⇄ Proposal Critique → Proposal Approval
        → Decomposing ⇄ Decomposition Critique → Decomposition Approval
        → Ready ⇄ In Progress ⇄ Verifying ⇄ In Review → Done
                ↑
            Blocked
```

For the full state table with transition ownership, see `references/state-machine.md`.

## Two Symphony instances

| Stack | Source forge | Implementer backend |
|---|---|---|
| **Personal** | Gitea (`gitea.vilo.network/ViLoHouse/*`) | Claude |
| **Yum** (`yummsapim` is current primary) | GitLab | GitHub Copilot |

Both stacks plan with Claude (Coordinator + Planner). Only implementers vary.

**Linear is shared.** Both Symphony instances point at Mike's personal Linear workspace. Separation between personal and Yum is enforced via separate teams or projects within personal Linear. Eventually Yum work may migrate to Atlassian (Jira); until then, personal Linear is the tracker for both.

Personal Symphony is in M2 buildout. Yum Symphony is a future deployment, not same-day available.

## Commit policy

Two distinct rules apply — keep them separate.

### Symphony-managed work in downstream repos (Implementer-Symphony → PR)

When Implementer-Symphony executes a Linear-tracked OpenSpec change against a downstream repo, the agent runs in a per-todo git worktree (provisioned by Symphony's `after_create` hook per VIL-208) and opens a PR against `main` via `mcp__forgejo__create_pull_request` per VIL-216. **Mike merges** the PR after Verifier-Symphony PASS + checkpoint review at `In Review`. The agent never self-merges.

| Stack | Flow | Branch | Notes |
|---|---|---|---|
| Personal | PR-flow | `symphony/<tracker>/<issue>` → PR against `main` | Per VIL-216; in-flight forge hardening: VIL-255 (branch protection no-self-merge), VIL-256 (CI + min-test bar gating merge). Until those land, Mike's manual discipline ("don't merge until Verifier PASSes") is the only gate; the prompt instructs the agent NOT to self-merge but the forge doesn't yet enforce it. |
| Yum | direct-commit | `dev` | Direct commits to `dev`. No PR/MR step. Promotion to `main` is a separate human-driven process. Yum's eventual flow when its Symphony deployment ships is TBD — not committed here. |

### Symphony platform-repo work (orchestrator / aggregator / adapter / sandbox)

Mike-paired work on the Symphony repos themselves is direct-to-`main`. No PR step. See auto-memory entry `feedback_symphony_main_only` — this rule continues to apply for repo-conventions work on the Symphony platform itself. The PR-flow above governs Implementer-Symphony-executed work in *downstream* repos (sandbox, eventually production downstream stacks); it does not govern Mike-paired or Coordinator-direct edits to the orchestrator/aggregator/adapter codebases.

### Open prerequisites for PR-flow hardness

Per-todo worktree provisioning: **done** (VIL-208). Forge hardening still pending:

- VIL-255 — branch protection on `symphony-sandbox` `main` (disallow self-merge for implementer service account).
- VIL-256 — CI + minimum-test bar wired into branch protection (PR merge requires green CI).

Until VIL-255 + VIL-256 land, PR-flow's "checkpoint" property is prompt-discipline, not forge-enforcement. Operators reviewing the merge button are the de-facto gate.

## Out of scope for this workflow

- **Direct agent work in a repo** (Mike opens a terminal and pairs with Claude on a small fix). That's the *fast path*; this workflow is for managed work only.
- **Cross-stack coordination** — personal and Yum stacks share zero implementation state.

## Coordinator's reading list

When starting a project for Mike, also check:

- **Memory:** `project_personal_vs_yum.md`, `project_docs_repo_per_app_stack.md`, `feedback_symphony_main_only.md`, `feedback_clarify_before_assume.md`, `reference_personal_infra.md`, `reference_coordinator_workflow_doc.md`.
- **Linear:** the Symphony Creation project (personal stack) for current build state of Symphony itself. Open verifications relevant to multi-Symphony rollout: VIL-53 (blocker-gate state-name parameterization), VIL-54 (agent-driven Linear state transitions).
- **Target repo's** `openspec/specs/` and `openspec/changes/` for capability state and `CLAUDE.md` for repo conventions.
- **Existing OpenSpec skills** are cited inline in `references/the-flow.md` at the steps where each applies (steps 3, 5, 6, 7, 9, 10).
