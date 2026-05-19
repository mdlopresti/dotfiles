# Lessons applied (cross-cutting, from prior critic rounds)

Read this reference when authoring or critiquing OpenSpec proposals / decomposition / specs. These patterns recur across many Symphony runs and are worth preemptively applying — they prevent the same critic flags from firing round after round.

## Pattern 1 — Spec pins observable contracts, not implementation details

Test file paths, marker registration mechanism, fixture wiring, env-var names — all `design.md` territory, not spec territory. Spec describes **system properties** (e.g., "the suite SHALL provide an opt-in selector for real-LLM tests"), not how those properties are achieved (e.g., "use `pytest -m e2e-llm`").

The marker name itself IS observable to anyone running the suite, so naming it in the spec is fine; the registration mechanism (where in `pyproject.toml`, what `addopts` line) is not.

## Pattern 2 — Cite by Requirement title, not line numbers

Line numbers rot. Requirement titles are stable. When a critique or design references an existing Requirement, name it by its title, not its position.

## Pattern 3 — Vendor-and-adapt over hand-roll

Before authoring a new test fixture, harness, or helper, check whether existing code in the repo (or a sibling repo) already solves the problem. Hand-rolling new infrastructure when an existing one fits is a recurring cause of round-after-round critic flags. The implementer should also check this during pre-edit audit.

## Pattern 4 — OpenSpec validator structural rule

The **first body line** of each `### Requirement:` MUST contain `SHALL` or `MUST`. The validator parses line-by-line — a Requirement whose first body line is e.g. an opening parenthesis or a sub-heading will fail validation even if SHALL/MUST appears later.

Same for scenarios: each `#### Scenario:` block must contain `WHEN` and `THEN` clauses.

## Pattern 5 — Force-converge at round 5–7

If proposal-stage critic surfaces 5+ rounds of recurring concerns (especially scope, impl-detail leakage, taste reversals between successive critics), **force-converge**: apply real fixes, hold reversals, move to decomposition. Don't keep iterating — diminishing returns set in around round 5–7.

The escalation threshold for Mike's intervention is 12 rounds (see `the-flow.md` step 5). Force-convergence is a Coordinator judgment call below that threshold when the loop is grinding without producing real improvements.

## Pattern 6 — Dual-signal observation for non-deterministic tests

Real-LLM responses, real-network calls, real-clock timing — all introduce variation. Don't pin tests on a single signal that can flake (e.g., the LLM's exact reply text). Pin **two independent observable signals** that don't co-flake (e.g., workspace cleanup observed AND orchestrator exit-0).

The test asserts on the orchestrator's externally-observable lifecycle, not on the conversational content traversing the JSON-RPC pipe.

## Pattern 7 — Pin time-boxes for risky bits

When a test exercises something with real-world latency (LLM round-trips, network calls, subprocess startup), pin a concrete trigger: "if X exceeds 60s on a clean run, surface the flake mode." A timeout with a stage-naming diagnostic > an unbounded wait that occasionally hangs CI.

## Pattern 8 — Default-suite vs opt-in marker IS a contract decision

When adding a new pytest marker, decide upfront whether the default `pytest` invocation includes or excludes it, and pin that decision in the spec. The mechanism (`addopts` deselect, conftest hook, etc.) is design.md territory; the contract ("default suite excludes both `e2e` and `e2e-llm`") is spec territory.
