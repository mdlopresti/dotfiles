---
name: agent-creator
description: Create new Claude Code subagent definition files (.md in ~/.claude/agents/ or <project>/.claude/agents/), edit and refine existing ones, and choose the right architectural pattern for the agent's responsibilities. Use this skill whenever the user asks to "create an agent", "make a subagent", "write an agent for X", "edit/update/refine the X agent", "I need an agent to do Y", or describes a repeatable workflow that should be encapsulated as a subagent. Also use when the user is unsure whether their use case calls for an agent vs a skill vs a workflow, or when discussing agent architecture choices like autonomous vs orchestrator-workers vs prompt-chaining patterns.
---

# Agent Creator

A skill for creating Claude Code subagent definitions and editing existing ones, with built-in guidance for choosing the right architectural pattern.

This skill works with Claude Code subagent files — markdown files with YAML frontmatter that live in `~/.claude/agents/` (user-level, default) or `<project>/.claude/agents/` (project-scoped). It does NOT cover GitHub Copilot agents (separate format, separate concern), nor does it cover skill creation (use `skill-creator` for that).

**Default architectural direction:** autonomous agent design — agents that operate with their own tool budget and decide their own next steps within a scoped responsibility. This pattern fits most Claude Code subagents and is where the agent format shines. Reach for other patterns only when justified.

## When to use this skill

Trigger on any of these:

- Creating a new subagent ("write me an agent for X", "I need a subagent that does Y")
- Editing an existing one ("update the X agent to also do Y", "refine X's prompt", "add tool Z to the X agent")
- Deciding whether something should be an agent at all (vs a skill, vs an inline workflow, vs a single prompt)
- Choosing between architectural patterns (autonomous agent vs prompt chain vs orchestrator-workers, etc.)

## The workflow

Follow these steps in order. The clarifying-questions step matters — wrong assumptions at the start cost more than three questions cost.

### 1. Capture intent through clarifying questions

Before writing anything, ask (skip any that are obvious from context):

- **What's the agent's responsibility?** One clear sentence. If you can't fit it in a sentence, the scope is probably too broad — push back and ask whether it should split.
- **When should it be invoked?** What user phrases or situations should trigger it? This becomes the description field, which is what Claude uses to decide whether to spawn the agent.
- **What's the input?** What context does the agent receive when invoked?
- **What's the output?** What should the agent produce — a file, a report, a code edit, a Linear ticket, a critique?
- **What tools does it need?** Read-only? State-changing? MCP tools? Task (to spawn subagents itself)?
- **User-scoped or project-scoped?** Default to user-scoped unless the agent is bound to a specific repo's conventions or files.

If the user is editing an existing agent, also ask:
- **What specifically needs to change?** Behavior? Tools? Frontmatter (rename, model)?
- **What stays the same?** So you don't accidentally rewrite what's working.

### 2. Choose the right architectural pattern

Anthropic's "Building Effective Agents" describes six patterns. The short version:

- **Single-shot LLM call** — Just a prompt, no agent. If the task is one round-trip, don't make it an agent.
- **Prompt chaining** — Sequential steps with validation between each. Use when stages are fixed.
- **Routing** — Classify input, dispatch to specialized followup. Use when distinct categories need distinct handling.
- **Parallelization** — Independent subtasks or multi-vote in parallel. Use when subtasks don't depend on each other.
- **Orchestrator-workers** — Central LLM decomposes dynamically, delegates to workers, synthesizes. Use when subtask shape isn't predictable up-front.
- **Evaluator-optimizer** — Generator + critic loop. Use when iterative refinement converges on quality.
- **Autonomous agent** — LLM decides its own steps, uses tools, stops when goal met. Use when steps aren't predictable and the agent recognizes done.

**Most Claude Code subagents are autonomous agents** with a scoped responsibility. Default there. Reach for other patterns only when the use case actively demands one.

For the full decision tree with examples and when-NOT-to-use guidance for each pattern, read `references/anthropic-patterns.md`. Read it when:
- The user describes a workflow with clearly fixed stages (might be prompt-chain).
- The user mentions multiple agents collaborating (might be orchestrator-workers or evaluator-optimizer).
- The user wants help deciding between approaches.

### 3. Design the system prompt

The body of the agent file (everything after the YAML frontmatter) is the system prompt. It should include:

- **Role statement** — first paragraph, declarative: "You are a [Role] that [primary responsibility]."
- **Workflow** — step-by-step process. Numbered when ordering is strict; bulleted when flexible.
- **Output format** — what the agent produces and how it's structured.
- **Constraints** — what the agent should NOT do. Hidden invariants. Scope boundaries.
- **Examples (optional)** — 1-3 if the task has nuance.

For section templates, agent-computer-interface (ACI) principles, tool-prompting guidance, and writing-style anti-patterns, see `references/system-prompt-structure.md`. Read that file when actually drafting the prompt body — it has the templates and patterns to copy.

Key principle: **explain the why behind instructions**, not just the what. Today's models follow reasoned guidance better than rote MUSTs. Walls of all-caps imperatives are a yellow flag.

### 4. Select tools (minimal but sufficient)

Default to read-only tools (Read, Glob, Grep). Add state-changing tools (Edit, Write, Bash) only when the agent must modify state. Add MCP tools when the agent needs an external system.

If the agent will spawn its own subagents (orchestrator-workers pattern), include `Task`. If it needs to run scripts, include `Bash`. If it needs to fetch web content, `WebFetch`.

Bloated tool lists "just in case" are wasted context for the agent's runtime. Each tool's schema is loaded into the agent's prompt; unused tools dilute attention.

### 5. Write the file

Default path: `~/.claude/agents/<name>.md` (user-scoped, available across all projects).
Project-scoped path (only when the user explicitly asks): `<project>/.claude/agents/<name>.md`.

Frontmatter format:

```yaml
---
name: agent-name              # required, kebab-case, matches filename (without .md)
description: When to invoke    # required; used by Claude to decide whether to spawn this agent
tools: Read, Glob, Edit       # optional; defaults to all tools if omitted
model: sonnet                 # optional: sonnet | opus | haiku | inherit
color: blue                   # optional UI accent: blue | green | yellow | purple | red
---
```

Then the system prompt body in markdown.

Use Write for new files. For edits to existing agents, use Edit (see step 6 and the editing reference).

### 6. Editing existing agents

When the user asks to update an existing agent rather than create one:

1. **Read first.** Load the current file with the Read tool. Don't edit blind.
2. **Identify the smallest possible diff.** Touch one section, not the whole prompt, when possible.
3. **Use Edit (surgical), not Write (full rewrite).** Preserves git history, makes review easy, less risk of dropping content.
4. **Preserve untouched frontmatter.** If the user said "change the model to opus," touch only `model:`. Leave description, tools, color alone.
5. **Don't refactor unrelated parts.** Tempting "while we're here" cleanups inflate diffs and risk regressions the user didn't ask for. Surface them as follow-up suggestions instead.

For common edit patterns (rename, tool list change, description refinement, model swap) and pitfalls, see `references/editing-existing-agents.md`.

### 7. Validate before declaring done

Quick checklist:

- [ ] Frontmatter has `name` and `description` (required)
- [ ] `name` is kebab-case, matches filename (without `.md`)
- [ ] `description` states both WHAT the agent does AND WHEN to invoke it
- [ ] Tools list is minimal — every tool listed has a clear use
- [ ] System prompt has Role, Workflow, Output Format sections
- [ ] If editing, frontmatter fields not being changed are preserved verbatim
- [ ] Tell the user: agent definitions load at session start; **restart Claude Code** to pick up new or edited agents

## Anti-patterns to flag

- **Vague descriptions.** "Helps with X" doesn't tell Claude when to invoke. Include trigger phrases and concrete contexts.
- **Tool list bloat.** Every unused tool is wasted context budget for runtime. Start minimal, justify each addition.
- **Embedded best-practice prose that ages.** Reference Anthropic's docs rather than re-stating them; their guidance evolves and rots in your file.
- **Wall-of-MUSTs.** Rigid all-caps directives are less effective than reasoned guidance.
- **Should-have-been-a-skill.** If the task is procedural ("do X following these steps") with no decision-making, it's a skill, not an agent.
- **Multi-purpose Swiss-army agents.** A single agent should have one clear responsibility. Five unrelated jobs → five focused agents.

## Reference files

Read these only when the situation calls for them:

- `references/anthropic-patterns.md` — The six architectural patterns, when to pick which, decision tree, examples and when-NOT-to-use for each.
- `references/system-prompt-structure.md` — Section templates, ACI principles, tool prompting guidance, writing-style anti-patterns. Read this when drafting the prompt body.
- `references/editing-existing-agents.md` — Surgical-edit patterns, frontmatter preservation rules, common edit types (rename, tool change, description refinement, model swap), reload semantics.

## Scope

- **In scope**: Claude Code subagent files (`.md` in `~/.claude/agents/` or `<project>/.claude/agents/`).
- **Out of scope**: GitHub Copilot agents (different format — use the `github-copilot-agent-writer` agent for those). Skills (use the `skill-creator` skill). Agents in other systems (LangChain, AutoGen, etc.).
