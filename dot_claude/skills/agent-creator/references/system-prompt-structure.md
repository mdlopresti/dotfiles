# System Prompt Structure for Subagents

Templates and guidance for writing the body of an agent definition file. The body (everything after the YAML frontmatter) becomes the agent's system prompt at runtime. Read this file when actually drafting the prompt — copy the templates, then customize.

## Recommended structure

Use these sections in this order. Not all are required for every agent — but if you include a section, follow the order so prompts read consistently across agents.

```markdown
## [Agent Name]

You are a **[Role]** that [primary responsibility]. [One or two sentences of essential context — what the agent does, and any non-obvious framing.]

Your core functions:
- [Function 1]
- [Function 2]
- [Function 3]

---

### When to use this agent

[Trigger conditions. What invocations should reach this agent. Example phrases the user might say. Cases where another agent or no agent at all is more appropriate. This often duplicates the frontmatter description, but in agent-facing language rather than Claude-routing language.]

---

### Your workflow

[Step-by-step process. Numbered if ordering is strict; bulleted if order is flexible. Be specific about decision points and what to do when an assumption doesn't hold.]

1. [First step]
2. [Second step]
3. [Third step]

---

### Tools you have

[Brief explanation of what each tool is for in this agent's context. Don't re-document the tool's general use — focus on how this agent should use it. If a tool has a non-obvious usage pattern in this agent's flow, name it.]

---

### Output format

[What the agent should produce. If structured, give the structure (markdown headings, JSON schema, file path conventions). If freeform, describe the expected shape and length. Be specific — "concise" is less useful than "1-3 sentences per section."]

---

### Constraints

[What the agent should NOT do. Hidden invariants. Scope boundaries. Things that would surprise a reader. This section catches scope creep at runtime.]

---

### Examples

[1-3 worked examples if the task has nuance. Each example shows input + expected output. Examples are powerful — models often learn the desired shape better from one example than from three paragraphs of description.]

**Example 1:**
Input: [...]
Output: [...]
```

## ACI principles (Agent-Computer Interface)

From Anthropic's guidance:

1. **Maintain simplicity in agent design.** Don't over-engineer. Complexity earns its place; it doesn't get assumed in.
2. **Prioritize transparency.** The agent should explain its plans and decisions in its outputs. This makes the agent debuggable when something goes wrong, and makes its outputs more useful even when nothing goes wrong.
3. **Treat agent prompts as user experience.** The same care that goes into HCI (human-computer interface) design goes into ACI (agent-computer interface) design. Tool definitions, system prompts, and output formats are all UX surfaces — for the agent.

## Tool prompting

When telling an agent how to use its tools (whether in the dedicated Tools section or inline in the workflow):

- **Minimize cognitive overhead.** Avoid formats that force the agent to count thousands of lines or do string-escape gymnastics. Prefer formats the model has seen often: markdown, JSON, YAML.
- **Give the agent room to think.** Reasoning before action reduces errors. Don't force terse-only output if the task benefits from deliberation.
- **Include examples and edge cases.** Tools described abstractly are misused more often than tools shown working.
- **Apply poka-yoke.** Make mistakes harder to make. If absolute paths are required, mandate them. If a flag is mutually exclusive with another, document the constraint inline at the use site.

## Writing style

- **Explain the why, not just the what.** "Read the file before editing — otherwise the Edit tool will fail" beats "ALWAYS read before editing." The model already follows reasoned advice; reasoning generalizes to edge cases the rule didn't anticipate.
- **Avoid wall-of-MUSTs.** All-caps imperatives are a yellow flag. If you find yourself writing ALWAYS or NEVER in caps, reframe with reasoning.
- **Use imperative form.** "Read the file" not "You should read the file." Less hedging, clearer guidance.
- **Be specific over generic.** "Run `python scripts/validate.py --input {filename}` to check format" beats "Validate the data."
- **Don't over-constrain.** Rigid structures and exhaustive rules can prevent the agent from adapting to inputs you didn't anticipate. Aim for principles + a few worked examples, not a 200-line decision tree.

## Common section anti-patterns

- **Walls of text.** Models skim too. Use bullets, numbered lists, headers — visual structure helps the agent locate the relevant guidance at runtime.
- **Critical instructions buried.** Important rules in the third paragraph of section seven get missed. Put load-bearing instructions up top, in the Role statement or the first workflow step.
- **Ambiguous language.** "Make sure to validate things properly" is uninterpretable. "Verify project name is non-empty, at least one team member assigned, start date is not in the past" is actionable.
- **Implicit assumptions.** If the agent needs to know something to do its job, state it. Don't assume the model has context it wasn't given.
- **Dead instructions.** Lines that don't change behavior. If removing a sentence wouldn't change what the agent does, remove it. Lean prompts beat verbose prompts.

## Length guidance

- A focused subagent's system prompt typically fits in 50-200 lines of markdown. If you're past 300, ask whether the agent's responsibility is too broad.
- For agents with genuinely complex domain knowledge, push detail into reference files inside the agent's project (or skill files invoked by the agent), not into the prompt itself.

## Common templates by pattern

### Autonomous agent template

For an agent that decides its own steps and stops when done:

```markdown
## [Agent Name]

You are a **[Role]** that [responsibility]. You operate autonomously: read context, plan, act with tools, and stop when [stopping condition].

### Your workflow

1. Read [input source] to understand the task.
2. Plan your approach. If the task is ambiguous, ask one clarifying question rather than guessing.
3. Execute, using tools as needed. After each tool call, briefly note what you learned and what you'll do next.
4. Stop when [explicit done-criteria]. If you've taken [N] iterations without progress, stop and report the blocker.

### Output format

Return a single message containing:
- Summary of what you did (1-2 sentences)
- Key findings or changes (bulleted)
- Any unresolved issues (if applicable)
```

### Evaluator (critic) template

For an agent in an evaluator-optimizer pair:

```markdown
## [Agent Name]

You are a **[Critic]** that reviews [artifact type] without the full context the author had. Your job is to surface issues the author may have missed BECAUSE they had too much context.

### Your workflow

1. Read ONLY the artifact under review. Do NOT read planning notes, prior conversation, or the author's reasoning.
2. Apply [N] critique heuristics: [list].
3. Surface the most significant issues, not all issues. Aim for 3-5 actionable critiques.

### Output format

For each critique:
- **Issue**: [one sentence]
- **Why it matters**: [one sentence on consequences]
- **Suggested fix**: [one sentence on direction, not full implementation]
```
