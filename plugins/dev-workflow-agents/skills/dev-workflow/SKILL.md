---
name: dev-workflow
description: Agentic implementation workflow. Orchestrates the Coordinator → Executor → Verifier pipeline with an adaptive fix loop. Run via /dev-workflow before any non-trivial implementation task.
---

# dev-workflow

I'm using the dev-workflow skill to run the agentic implementation pipeline.

## Step 1 — Startup screen

Display the configuration to the user and collect their choices:

```
╔══════════════════════════════════════════╗
║  dev-workflow — configuration            ║
╠══════════════════════════════════════════╣
║  Coordinator : claude-sonnet-latest      ║
║  Executor    : claude-haiku-latest       ║
║  Verifier    : claude-sonnet-latest      ║
╠══════════════════════════════════════════╣
║  Project complexity?                     ║
║    simple  — skip Verifier               ║
║    complex — full pipeline (default)     ║
╠══════════════════════════════════════════╣
║  Override a model? (optional)            ║
║  Syntax: role=model                      ║
║  Example: verifier=claude-opus-latest    ║
║  Roles: coordinator / executor / verifier║
╚══════════════════════════════════════════╝
```

Collect from the user:
1. Complexity mode: `simple` or `complex` (default: `complex`)
2. Optional model overrides (format `role=model`)

Save the configuration — it will be used throughout the pipeline.

## Step 2 — Initialize state file

Create `.dev-workflow-state.md` in the current project directory:

```markdown
## Metadata
- Coordinator: [model]
- Executor: [model]
- Verifier: [model]
- Mode: [simple/complex]
- Started: [current date and time]
- Fix iterations: 0 / max 3
```

## Step 3 — Phase 1: Planning

Invoke agent `dev-coordinator` with the following context:
- User's prompt (original requirement)
- Path to `.dev-workflow-state.md`
- Path to the project directory
- Instruction: "Run Phase 1 per your instructions. Start by asking the Executor to analyze the codebase, then create a task plan and present it to the user for approval."

The Coordinator will invoke the Executor for code analysis on its own.

**Wait for the user to approve the plan before proceeding to Phase 2.**

## Step 4 — Phase 2: Implementation

Invoke agent `dev-coordinator` with:
- Approved plan from `.dev-workflow-state.md`
- Path to the project directory
- Instruction: "Run Phase 2. For each task: collect a pre-check from the Executor, approve it, then delegate implementation."

The Coordinator handles the pre-check → approval → Executor implementation loop on its own.

If the Executor escalates a task, the Coordinator records the decision in `.dev-workflow-state.md` under `## Phase 2 — Escalation [task name]` before passing the revised task back.

After each task is implemented, the Coordinator reviews the Executor's result in the state file (`## Phase 2 — Result [task name]`) to confirm it matches the plan before proceeding to the next task.

## Step 5 — Phase 3: Verification (complex mode only)

If mode is `simple` — skip this step and go to Step 7.

**Important:** Do not commit changes before verification — the Verifier needs to see them in the diff.

Prepare context for the Verifier (ONLY these elements, nothing more):
- User's original requirements (copied verbatim)
- List of task titles from `.dev-workflow-state.md` (no implementation details)
- Output of `git diff` in the project directory (staged + unstaged changes). If the diff is empty, also try `git diff HEAD` in case changes were committed.
- Path to the project directory

Invoke agent `dev-verifier` with this context.

## Step 6 — Phase 4: Fix loop (max 3 iterations)

The loop runs while the Verifier reports findings, up to 3 iterations.

### UNCERTAIN → Ask the user
If the Verifier reported `UNCERTAIN` findings:
- Ask the user the Verifier's questions.
- Save the answers to `.dev-workflow-state.md`.
- Pass the answers to the Verifier before routing remaining findings.

### ARCHITECTURAL → through the Coordinator
Invoke `dev-coordinator` with:
- `ARCHITECTURAL` findings from the Verifier
- Current state of `.dev-workflow-state.md`
- Instruction: "Plan and carry out architectural fixes via the Executor (with pre-checks)."

### MINOR → directly to the Executor
Invoke `dev-executor` with:
- List of `MINOR` findings
- Current state of `.dev-workflow-state.md`
- Instruction: "Fix the listed issues. For each fix: run a pre-check, send it to the Coordinator for approval, then implement."

### After fixes
- Update the iteration counter in `.dev-workflow-state.md` (the skill orchestrator is responsible for incrementing `Fix iterations`).
- Re-invoke `dev-verifier` with the same minimal context (requirements + new `git diff HEAD` + task titles).
- If the Verifier reports the same findings as in the previous iteration (no progress) — stop the loop immediately and escalate to the user instead of wasting remaining iterations.
- If 3 iterations pass without "No findings" — escalate to the user:

```
ITERATION LIMIT REACHED

The following issues could not be resolved after 3 iterations:
[list of unresolved findings]

Options:
1. Continue manually
2. Restart verification with new instructions
3. End workflow and accept the current state
```

## Step 7 — Final report

Invoke `dev-coordinator` with the instruction: "Prepare the final report based on `.dev-workflow-state.md`."

The report must include:
- List of completed tasks with status
- Verifier findings and how they were resolved (if complex mode)
- Number of fix iterations
- List of all files changed in the project (`git diff --name-only HEAD`)

## Step 8 — Cleanup

Delete `.dev-workflow-state.md` from the project directory.

---

## General principles

- **Quality > speed.** When the pipeline hits an unresolvable problem — stop and ask the user instead of continuing with an error.
- **Verifier isolation is intentional.** Never pass more than: requirements + task titles + git diff + project path to the Verifier.
- **The state file is the pipeline's only memory.** Every agent reads it for current state before acting.
- **`*-latest` models are used by default** — they always point to the newest version of the model family.

