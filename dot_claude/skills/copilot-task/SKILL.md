---
name: copilot-task
description: Invoke the GitHub Copilot CLI as a Coordinator-style subagent (planner, critic, or implementer for OpenSpec-based work) via the wrapper script this skill ships, so a calling agent can offload a planning/critique/implementation task to Copilot the same way it would spawn a Claude subagent. Use whenever the user says "use Copilot for this", "have Copilot plan/critique/implement X", "offload this to Copilot", "spawn a Copilot planner/critic/implementer", or when a Coordinator workflow needs Copilot as the planner/critic/implementer backend and you need to dispatch the task without spawning an in-process Claude subagent. Also trigger when the user mentions "copilot-task", "copilot subagent", or wants Copilot to read an OpenSpec change directory and produce/review/implement against it.
---

# copilot-task

A wrapper + role-prompt bundle that lets a Coordinator-style caller (a Claude session, or any orchestrator) dispatch a planner, critic, or implementer task to the GitHub Copilot CLI. The result is functionally analogous to spawning a Claude subagent via the Agent tool — same role contract, different model backend, returned as the subprocess stdout.

The wrapper lives at `scripts/copilot-task` (relative to this skill). The role prompts live in `roles/<role>.md`. The caller does not need to load the role prompts directly — the wrapper prepends them to the task prompt at invocation time.

The skill is deliberately independent of any specific orchestrator. The role bodies describe a generic Coordinator-style planner/critic/implementer workflow centered on OpenSpec change directories. The caller (whatever it is) supplies the project-specific bits — commit policy, branch policy, tracker context, methodology references — through the task prompt and `--add-dir` flags.

## When to use this skill

Use it any time the caller would otherwise spawn a planner / critic / implementer Claude subagent for OpenSpec-based work but wants Copilot to do the work instead. Concrete triggers:

- The user says "have Copilot plan this", "use Copilot for the critique", "spawn a Copilot implementer", "let Copilot handle this ticket".
- You're operating in a Coordinator session, you've just clarified scope, and the next step would be spawning a Planner — but the workflow policy says Copilot is the planner/critic/implementer backend for this kind of work.
- You need a context-isolated cold read of an OpenSpec proposal and the convention is to dispatch the Critic to Copilot.
- A tracker ticket for an OpenSpec change has come up for implementation and the caller routes it to Copilot via this wrapper.

Do **not** use this skill for:

- Fast-path inline work where the user is pairing directly with you (no Coordinator session, no managed-work framing).
- One-off Copilot calls unrelated to the planner/critic/implementer pattern (e.g. "just ask Copilot what it thinks of this regex"). Use `copilot -p ... --model gpt-5-mini` directly.
- Calling Copilot for non-shipped roles (security review, code review, etc.). The wrapper only ships planner/critic/implementer role prompts; other roles would need a new file in `roles/`.

## The wrapper contract

The wrapper is a synchronous, blocking subprocess. You invoke it from Bash, it runs Copilot non-interactively, and it writes Copilot's final response to stdout. Treat its stdout as you would the return message from an Agent-tool subagent call.

Under the hood the wrapper always asks Copilot for `--output-format json` and reconstructs the final response text from `assistant.message` events. This is transparent to the caller — the stdout contract is unchanged — but it matters because Copilot CLI's human-readable text renderer relies on TTY-only ANSI sequences and silently drops or garbles the final response when stdout is a pipe or file. Doing the JSON-then-extract dance internally makes the wrapper behave the same whether it's run from a real terminal, another Claude session's Bash tool, a background dispatcher, or CI.

The wrapper requires `jq` on `PATH` for that extraction. If `jq` is missing it fails fast with a clear message before invoking Copilot.

Invocation shape:

```bash
~/.claude/skills/copilot-task/scripts/copilot-task \
  --role <planner|critic|implementer> \
  --repo <absolute-path-to-repo> \
  --prompt-file <path-to-prompt-md>
```

Use `--prompt-file` for anything non-trivial — multi-paragraph prompts on the command line get unwieldy and shell-quoting bugs are silent. Write the prompt to a temp file (e.g. `/tmp/coordinator-prompt-<change-id>.md`) and pass the path. Use `--prompt "<short>"` only for one-liners.

Defaults the wrapper applies automatically:

- `--model gpt-5-mini` — the wrapper's default. Override with `--model <other>` if the user names a different model for that call.
- `-p`, `--allow-all-tools`, `--no-ask-user` — non-interactive, autonomous.
- `--output-format json` — always sent to Copilot internally; the wrapper extracts response text from the resulting event stream (see above).
- `-C <repo>` — sets Copilot's working directory and (by default) restricts its file access to that subtree.

Per-role defaults the wrapper applies:

- **planner** — no extra mounts. The repo is the work surface.
- **critic** — `--deny-tool='write'`. The Critic role is read-only by contract; this enforces it at the tool layer.
- **implementer** — no extra mounts. The repo is the work surface.

If a role needs to read files outside the repo (workflow contracts, methodology docs, sibling repos, a roadmap location), the caller passes those at invocation time via `--add-dir`. The wrapper deliberately does not auto-mount anything beyond cwd — that keeps the skill independent of any specific orchestrator's filesystem layout.

Useful flags you may pass through:

- `--add-dir <path>` (repeatable) — grant access beyond cwd. Use for cross-repo reads.
- `--name <session-name>` and `--resume <session>` — name a session so a later run can continue it. Useful for Verifier-rejection continuation runs to the implementer.
- `--output json` — instead of the reconstructed final-response text, forward Copilot's raw JSONL event stream verbatim (one event per line, including `assistant.message_start`, `assistant.message_delta`, tool requests, `result`, etc.). Use when you want to inspect tool calls, streaming deltas, or session metadata. Default `--output text` is what callers usually want — it's the same final-response contract as a Claude subagent.
- `--dry-run` — print the resolved `copilot ...` command without running it. Use when debugging the wrapper or when you want to eyeball the invocation before it fires.
- `-- <args...>` — anything after `--` is passed through to `copilot` verbatim. Escape hatch.

## How to write the task prompt

The wrapper prepends the role-prompt file to whatever you supply. So your prompt should be **task-specific**, not role-defining. The role prompt already tells Copilot it is the Planner / Critic / Implementer; you supply the situation.

Include, at minimum:

- **Stage indicator** for planner/critic: `proposal` or `decomposition`.
- **Commit/branch policy** for implementer: which branch to commit to, whether to open a PR. (Or rely on the repo's `CLAUDE.md`/`AGENTS.md` saying so.)
- **Absolute paths** to anything Copilot needs to read (the change directory, referenced specs, any tracker-context blob).
- **Scope**: project goal, hard constraints, success criteria. Already-clarified material from the caller's clarification round.
- **For revision/continuation runs**: the feedback to address, plus the prior artifact paths (so Copilot reads them before rewriting).

Do **not** include:

- The role definition (the wrapper provides it).
- Caller session history or framing the role file already warns against. The Critic in particular will treat any of that as an inside-view leak.

## Output handling

The wrapper exits with Copilot's exit code (or `3` if Copilot exited cleanly but produced no `assistant.message` event for the wrapper to extract). Stdout is Copilot's final response text, reconstructed from the JSON event stream — concatenated across turns with blank-line separators when there is more than one assistant message. The caller should:

1. Capture stdout into a variable or a file.
2. Treat it as the subagent's return message — same handling you'd give to an Agent-tool result.
3. For **planner** outputs: verify the file paths Copilot named actually exist before circulating to the approver or the Critic.
4. For **critic** outputs: parse the `Verdict` line (Approve / Revise / Revise proposal first) and route accordingly.
5. For **implementer** outputs: parse the `Status` line (`ready-for-verification` or `needs-coordinator-input: <reason>`) and route to the Verifier or back to the approver.

If stdout looks empty or the exit code is non-zero, surface that to the user rather than guessing. Copilot's non-interactive mode will sometimes refuse a tool call and exit cleanly with a short message; don't assume silence means success.

## Examples

Concrete paths below are placeholders — substitute the actual repo path and change ID at the call site.

### Spawn a Planner for a new change

```bash
cat > /tmp/planner-prompt.md <<'EOF'
Stage: proposal
Repo: <ABS_REPO_PATH>
Tracker context: TICKET-142 — "<one-line summary>"
Goal: <clarified scope statement>
Hard constraints: <must-not-change items, deadlines, compatibility requirements>
Success criteria: <how the approver will recognize completion>
Out of scope: <items the planner should not include>
EOF

~/.claude/skills/copilot-task/scripts/copilot-task \
  --role planner \
  --repo <ABS_REPO_PATH> \
  --prompt-file /tmp/planner-prompt.md
```

### Spawn a Critic against an existing proposal directory

```bash
~/.claude/skills/copilot-task/scripts/copilot-task \
  --role critic \
  --repo <ABS_REPO_PATH> \
  --prompt "Stage: proposal
Artifact: <ABS_REPO_PATH>/openspec/changes/<change-slug>/
Repo root (your cwd): <ABS_REPO_PATH>
Read only the artifact and any specs it directly references. Apply proposal-stage heuristics."
```

### Spawn an Implementer against a ticket

```bash
~/.claude/skills/copilot-task/scripts/copilot-task \
  --role implementer \
  --repo <ABS_REPO_PATH> \
  --name "impl-<TICKET-ID>" \
  --prompt "Change directory: <ABS_REPO_PATH>/openspec/changes/<change-slug>/
Tracker ticket: <TICKET-ID>
Commit policy: <e.g. 'commit directly to main' or 'open a PR against develop'>
Execute end-to-end against the change directory's tasks.md / design.md / specs. Signal done when ready for the Verifier."
```

### Dry-run to verify the resolved command

```bash
~/.claude/skills/copilot-task/scripts/copilot-task \
  --role planner --repo /tmp --prompt "hi" --dry-run
```

## Anti-patterns

- **Calling the wrapper without `--role`** — the role definition is the value-add; without it you might as well use `copilot -p` directly.
- **Stuffing caller session history into the prompt** — especially for the Critic. The role file explicitly tells Copilot to ignore that, but it pollutes the prompt and wastes tokens.
- **Re-reading Copilot's stdout aloud** — surface the meaningful parts (paths, verdict, status) to the user. The raw stream is for the caller's machinery.
- **Forgetting to override `--model` for a one-off model swap** — the default is `gpt-5-mini`; pass `--model <name>` to override per call.
- **Treating the wrapper as a background task** — it's synchronous. If you need parallelism, run multiple wrapper calls in parallel from Bash (one per subagent).

## Files in this skill

- `SKILL.md` — this file (the contract).
- `scripts/copilot-task` — the wrapper. Executable. Bash; depends on `copilot` and `jq` on `PATH`.
- `roles/planner.md` — Planner role prompt, Copilot-adapted.
- `roles/critic.md` — Critic role prompt, Copilot-adapted, tool-restricted.
- `roles/implementer.md` — Implementer role prompt for OpenSpec-driven work.

To add a new role, drop a `roles/<name>.md` file with a role-defining prompt and invoke the wrapper with `--role <name>`. Consider adding per-role defaults to the wrapper's `case "$ROLE"` block if the role needs special permissions.
