---
name: symphony-role-scoped-decomposition
description: The ≤ 1 day per role per change sizing heuristic for OpenSpec changes in Mike's Symphony workflow. Use this skill whenever a Planner is sizing a proposal or fleshing out a decomposition, when a Critic is checking day-budget compliance, when an OpenSpec change spans multiple disciplines (SRE, DBA, security, backend, etc.), or when scope feels "too big" and a split is being considered. Also load when the user mentions "role-scoped", "split this change", "1-day budget", "this is too coarse for the implementer", or asks how to size or partition managed work. Trigger even when the work isn't explicitly framed as multi-role — surfacing role inventory IS part of the heuristic, so reach for this skill before assuming a change is single-role.
---

# Role-scoped decomposition

Heuristic for sizing OpenSpec changes in Mike's Symphony workflow: **≤ 1 day per role per change**, not just ≤ 1 day per change.

This skill is a methodology that applies at specific moments in `symphony-coordinator-workflow` — load that skill for the broader stage gates, state machine, and Coordinator/Planner/Critic role contracts. This skill drills into sizing and partitioning.

The canonical narrative source is `~/Documents/Documents/Journal/Project/Symphony/Role-scoped decomposition.md` in Mike's Obsidian vault. Status: **Adopted as default heuristic 2026-05-07.**

## Why role-scoped, not just per-change

The original Symphony sizing rule was "each change ≤ 1 day of one developer's work." In Mike's solo-operator context, a "developer" wears multiple hats per change (SRE, DBA, security), and conflating those hats inside one change keeps the change too coarse for implementer agents to execute well.

- **Smaller scope = better implementer agents.** Role-bounded changes fit context windows better, reduce "what should I touch" ambiguity, keep the agent in one mental mode.
- **Aligns with where Symphony is heading.** Role-specialized implementer agents (an SRE-Symphony, a DBA-Symphony) will eventually poll `Ready` tickets matching their role. Per-role labels today are forward-compatible.
- **Within-phase parallelism becomes legible.** Sparser dependency graph at the leaves — DB setup and ingress config don't block each other.
- **Sharper review and audit.** Single-role changes read in single-domain context. Pre-edit audit becomes more meaningful per role.
- **Forces explicit role inventory.** Surfaces hidden expertise needs early.

## The heuristic

Default decomposition rule for the Planner:

1. **Identify roles touched by a phase or proposal before decomposing.** Required upfront step — surfaces hidden expertise needs early.
2. **Default: one OpenSpec change per role-bounded slice, ≤ 1 day per role.** This is the headline rule.
3. **Allow tightly-coupled cross-role changes** when forcing a split would create invisible cross-spec assumptions (e.g., a connection-string handshake between SRE and DBA work). The Planner exercises judgment; the Critic flags both unnecessary cross-role spans and artificial splits of coupled work.
4. **Single-role phases or work** stay as one change. Don't invent role splits where there's only one role.

## Why a heuristic, not a strict rule

The strict version of "1 change per role" was rejected because:

- Some work has tight cross-role coupling that survives forcing a split only as invisible cross-spec assumptions.
- Cross-cutting concerns (logging, observability, secrets) span all roles by nature.
- Some changes are genuinely single-role (a docs-only change shouldn't fragment).

The heuristic captures the practical wins (smaller scope, tighter implementer-agent context, claim-signal-ready, sharper review) while letting the Planner exercise judgment when role boundaries are genuinely fuzzy.

## Cost / friction (acknowledged)

- **More changes = more orchestration overhead.** Until Symphony is fully autonomous, every Linear todo transition is a Mike-touch. 3x changes = 3x Mike-touches. Mitigated as Symphony matures.
- **Sequencing complexity.** Denser `blockedBy` graph. Manual `Blocked → Ready` promotion until VIL-32 ships native dependency awareness.
- **Role taxonomy is fuzzy in solo-operator context.** Mike wears all hats; role boundaries are cognitive frames, not org boundaries.
- **Cross-cutting concerns.** Logging/observability/secrets touch every role; risk of fragmenting or duplicating.
- **Pre-optimizes for architecture not yet built.** Role-specialized Symphony agents are aspirational; today's Implementer-Symphony executes whatever the spec says.

## Role taxonomy (working list)

Keep small — 5–8 high-level roles for the personal stack:

- **SRE** — K8s, Helm, ArgoCD, ingress, DNS, observability, deployment plumbing.
- **DBA** — Postgres / CloudNativePG, schema, migrations, backup-from-DB-perspective.
- **Security** — secrets management, push protection, history scrubbing, secret-bootstrap patterns.
- **Backend** — application code, Forgejo configuration, application-level integrations.
- **Frontend** — UI work (rare in personal stack today).
- **Docs** — runbooks, policy docs, READMEs, decision records.
- **Infra-platform** — base cluster IaC, networking, CNI, storage classes (out of current personal-stack scope).

Add roles as new contexts surface; resist proliferation.

## Critic responsibilities

The **Decomposition-stage Critic** flags **both directions**:

- **Span:** changes spanning multiple roles where a clean split was available — risk of fat changes, harder review.
- **Split:** changes split between roles where the coupling is so tight the resulting changes rely on un-pinned cross-spec assumptions — risk of integration drift.

The **Proposal-stage Critic** also gains a corresponding check: a proposal whose scope clearly spans multiple roles for >1-day-each work should be flagged for role-scoped split before decomposition begins.

## Linear claim signal (forward-compatibility)

When Symphony matures, role-specialized implementer agents poll `Ready` tickets matching their role. A label per change (e.g., `role:sre`, `role:dba`) makes the claim signal explicit. Today, the Implementer-Symphony is one Claude (or one Copilot) and ignores the role label — but the labels are still useful for filtering, reporting, and forward-compatibility.

## Open questions

These remain unresolved at adoption — surface to Mike when relevant:

- **Multiple-role-per-change sizing.** When a tightly-coupled cross-role change is allowed (rule 3), is the sizing rule "≤ 1 day per role with total possibly higher" or "≤ 1 day total still"? Default reading: per-role with a possibly-higher total when coupling justifies it. Validate in practice.
- **Cross-cutting concerns.** A "logging" addition that touches every role's code — single change with all roles inside, or one per role with shared spec? Open until we hit one.
- **Linear label scheme.** `role:sre` vs `sre` vs separate `Role` field — decide when first role-specialized Symphony agent is built.
