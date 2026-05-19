# Architectural Patterns for Agents

From Anthropic's "Building Effective Agents" engineering guidance (https://www.anthropic.com/engineering/building-effective-agents). Read this file when deciding which pattern fits a use case, or when the user asks about agent architecture.

## Workflows vs Agents

- **Workflows**: systems where LLMs and tools are orchestrated through predefined code paths.
- **Agents**: systems where LLMs dynamically direct their own processes and tool usage.

Workflows are more predictable. Agents are more flexible. Choose based on whether you can predict the steps up front.

**Core principle**: start simple. Only increase complexity when it demonstrably improves outcomes. Agentic systems trade latency and cost for better task performance — only pursue them when that tradeoff is justified.

## Decision tree

Walk top to bottom. Stop at the first match.

1. **Is this a single round-trip task?** → Just use a prompt. Not an agent.
2. **Are the steps fixed and known up front?** → Workflow patterns: prompt chaining, routing, or parallelization.
3. **Are the steps dynamic but bounded by clear evaluation criteria?** → Evaluator-optimizer or orchestrator-workers.
4. **Are the steps fully open-ended with the agent recognizing "done"?** → Autonomous agent.

For most Claude Code subagents, the answer is **autonomous agent**.

## The six patterns

### 1. Prompt chaining

Decompose a task into sequential steps with programmatic validation between them.

- **Best for**: Fixed multi-step tasks where each step is simpler than the whole.
- **Examples**: Outline → draft document; English → translate → polish.
- **When NOT**: When step boundaries aren't predictable.
- **Implementation note**: Often this lives at the parent level (the spawning code/agent), not inside a single subagent. If you're tempted to put a prompt chain inside one subagent, ask whether the chain belongs in the parent.

### 2. Routing

Classify input and dispatch to a specialized followup.

- **Best for**: Tasks with distinct categories needing distinct handling.
- **Examples**: Customer-service triage; cost-optimized model selection by query complexity.
- **When NOT**: When categories aren't clearly separable, or when one specialist could handle all cases.
- **Implementation note**: Typically a parent-level concern. The routing logic spawns the appropriate subagent.

### 3. Parallelization

Run independent subtasks or multiple attempts simultaneously, then aggregate.

- **Best for**: Subtasks with no ordering dependency, or where multiple perspectives improve quality (voting).
- **Examples**: Multi-screen content moderation; multi-rater code review.
- **When NOT**: When subtasks have ordering dependencies. When aggregation is harder than the work itself.
- **Implementation note**: Usually a parent-level pattern — parent spawns N agents in parallel via Task.

### 4. Orchestrator-workers

A central LLM dynamically decomposes a task, delegates to worker subagents, synthesizes their outputs.

- **Best for**: Complex tasks where subtask shape isn't predictable up-front.
- **Examples**: Multi-file code changes; multi-source research with unknown depth.
- **When NOT**: When the work is small enough that decomposition overhead exceeds the gain.
- **Implementation note**: This is one of the few patterns that justifies a multi-agent design where one Claude Code agent has the `Task` tool and spawns its own subagents. Default to single-agent unless the dynamic decomposition is genuinely needed.

### 5. Evaluator-optimizer

One LLM generates output; another evaluates and provides refinement feedback. Loop until quality threshold met.

- **Best for**: Iterative refinement where evaluation criteria are clear.
- **Examples**: Translation polish; multi-round search and synthesis; OpenSpec proposal red-team review.
- **When NOT**: When the evaluator is the same size and quality as the generator (no signal to chase). When evaluation criteria are subjective and the loop oscillates.
- **Implementation note**: Often two distinct agents — a generator and a critic — coordinated by a parent. The Coordinator/Planner/Critic shape from the Symphony workflow is an instance of this pattern.

### 6. Autonomous agent

LLM operates independently using tools, with environmental feedback driving next steps. Stops when goal met or stopping condition triggered.

- **Best for**: Open-ended tasks where step counts aren't predictable.
- **Examples**: SWE-bench-style coding tasks; multi-step research with unknown depth; computer-use automation.
- **When NOT**: When the cost of agent runtime exceeds the value of automation. When stopping criteria can't be made explicit.
- **Implementation note**: **Always include stopping conditions** — max iterations, explicit done-criteria, or both. Autonomous failure is worse than no automation.
- **This is the default for most Claude Code subagents.**

## Picking patterns for Claude Code subagents specifically

Claude Code agents are spawned via the Task tool by a parent (the main session or another agent). The parent passes a prompt; the agent runs to completion and returns a single message.

This shape leans toward:

- **Autonomous agents** for most cases — the agent reads, plans, acts, returns.
- **Orchestrator-workers** when one agent legitimately needs to spawn its own subagents during execution.

Patterns 1-3 (prompt chaining, routing, parallelization) typically belong at the parent level, not inside a single subagent. If you find yourself building a routing pattern inside an agent, consider whether the parent should route instead.

Pattern 5 (evaluator-optimizer) shows up cleanly as **two distinct agents** — a generator and a critic — coordinated by a parent. Don't try to embed the evaluator-optimizer loop inside a single agent.

## Anti-patterns

- **Over-engineering.** Reaching for orchestrator-workers when a single prompt suffices.
- **Framework lock-in.** Heavy abstractions hide the actual prompts and make debugging hard. Keep the prompt visible.
- **Skipping measurement.** Adding complexity without confirming it improves outcomes.
- **No stopping conditions.** Autonomous agents without max-iteration or done-criteria are dangerous.
- **Compounding errors.** Multi-step agents amplify mistakes; guardrails matter more as steps grow.
- **Confusing patterns with file structure.** "Agent vs workflow" is about behavior, not file count. A single agent file can implement an autonomous-agent pattern; a parent-and-children setup can implement orchestrator-workers — but the patterns aren't identical to those file structures.
