# Editing Existing Agents

Surgical edits beat full rewrites when refining an agent. Read this file when the user asks to update an existing agent rather than create a new one.

## Before editing

1. **Read the current file.** Use the Read tool to load it before any change. Don't edit blind — you might miss content you'd accidentally drop.
2. **Note what's working.** The user is asking for a specific change. They want the rest preserved.
3. **Identify the smallest possible diff.** Edit one section, not the whole prompt, when possible. Small diffs are easier to review and less likely to introduce regressions.

## Common edit types

### Add or remove tools

Change only the `tools:` line in frontmatter. Leave everything else alone.

```yaml
# Before
tools: Read, Glob, Edit

# After (added Bash)
tools: Read, Glob, Edit, Bash
```

If removing a tool, also scan the system prompt body — if the prompt references the tool you're removing, the body needs an update too.

### Refine a workflow step

Find the specific step in the system prompt body. Edit just that step's text. Don't touch surrounding steps unless dependencies require it.

If the change cascades (changing step 2 invalidates step 3), update the affected steps explicitly. Don't silently leave inconsistent guidance.

### Update the description

Frontmatter `description:` field only. This is what Claude uses to decide whether to invoke the agent — the trigger conditions matter more than the wording.

When updating a description, ask: are we trying to fix under-triggering (agent doesn't load when it should) or over-triggering (loads when it shouldn't)? The fix differs:

- **Under-triggering**: add more trigger phrases, mention specific contexts the user might describe, make the description "pushier" with explicit "use this whenever..." language.
- **Over-triggering**: add negative triggers ("Do NOT use for X"), be more specific about scope, narrow the trigger phrases.

### Rename an agent

Three things must change in lockstep:

1. The filename: `<old-name>.md` → `<new-name>.md` (use `mv`)
2. The `name:` field in frontmatter
3. Any references to this agent by name in OTHER agents (use Grep to find them)

If you rename and miss step 3, agents that mention the old name may try to spawn an agent that no longer exists.

### Change the model

Frontmatter `model:` field only. Valid values: `sonnet`, `opus`, `haiku`, `inherit`. Anything else and the agent fails to load.

### Reorganize sections

If the user wants the system prompt restructured (e.g., move Constraints up, add an Examples section), use multiple targeted Edit calls rather than a single Write that replaces the whole body. This preserves any content not being moved and makes the diff legible.

## Frontmatter preservation rules

When editing the body, do NOT touch frontmatter unless the user explicitly asked.
When editing one frontmatter field, do NOT touch others.

The Edit tool with a tightly scoped `old_string` is the right approach. Avoid Write (full rewrite) for edits — too easy to silently drop fields.

If you DO need to update multiple frontmatter fields, do them as separate Edit calls, each with its own narrow scope. This makes intent clear in the diff.

## When to refactor more aggressively

Sometimes the user asks for a small change but you notice the agent has structural issues — wall-of-MUSTs, no clear workflow section, bloated tool list, contradictory instructions. It's tempting to fix these "while you're here." Don't, unless the user explicitly says so. Aggressive refactors:

- Inflate diffs and hide the actual requested change in review.
- Risk introducing regressions the user didn't ask for.
- Conflict with other in-flight changes if multiple iterations are happening.

If you see structural issues, surface them as a follow-up suggestion: "I noticed [issue] in this agent. Want me to address it as a separate change after this one lands?" Let the user decide.

## Reload semantics

Agent definitions load at Claude Code session start. Edits to existing agents do NOT take effect until the next session restart.

After any edit, tell the user explicitly: "This change won't take effect until you restart Claude Code." Otherwise they'll test the agent in the current session, see the old behavior, and report a phantom bug.

## Test after editing

Same checklist as creating:

- [ ] Frontmatter still has `name` and `description` (you didn't accidentally drop them)
- [ ] `name` and filename still match
- [ ] Tools list reflects the actual tools the prompt uses
- [ ] System prompt body is internally consistent (no contradictions introduced by the edit)
- [ ] Untouched fields are preserved verbatim

Then suggest the user invoke the agent in a fresh session and verify the behavior matches the change.

## Common pitfalls

- **Forgetting the session-restart caveat.** Mentioned above; bears repeating because it's the most common confusion after an edit.
- **Editing description without testing trigger.** Description changes affect whether Claude invokes the agent at all. Worth eyeballing the new description against a few imagined invocations.
- **Renaming without updating references.** Use Grep across `~/.claude/agents/` to find any agent that mentions the old name.
- **Refactoring beyond scope.** As noted above — surface as follow-up, don't bundle.
- **Dropping fields silently with Write.** If you must use Write (full rewrite), explicitly include every field that was in the original. Better: use Edit.
