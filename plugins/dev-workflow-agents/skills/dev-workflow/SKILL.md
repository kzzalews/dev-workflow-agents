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
- Coordinator actual model ID: [recorded on first invocation]
- Executor actual model ID: [recorded on first invocation]
- Verifier actual model ID: [recorded on first invocation]
```

If an agent's actual model ID changes between invocations within the same pipeline run, log a warning in the state file:
```
WARNING: [agent] model changed from [old] to [new] mid-pipeline.
```

## Step 3 — Phase 1: Planning

Invoke agent `dev-coordinator` with the following context:
- User's prompt (original requirement)
- `## Metadata` and `## Requirements` sections from `.dev-workflow-state.md` (do NOT pass other sections)
- Path to the project directory
- Instruction: "Run Phase 1 per your instructions. Start by asking the Executor to analyze the codebase, then create a task plan with a sprint contract (testable acceptance criteria) and present both to the user for approval."

The Coordinator will invoke the Executor for code analysis on its own.

**Wait for the user to approve both the plan AND the sprint contract before proceeding to Phase 2.**

## Step 4 — Phase 2: Implementation

Invoke agent `dev-coordinator` with:
- Approved plan and sprint contract from `.dev-workflow-state.md`
- Path to the project directory
- Instruction: "Run Phase 2. For each task: collect a pre-check from the Executor, approve it, delegate implementation, then run the post-task checkpoint before proceeding to the next task."

The Coordinator handles the pre-check → approval → Executor implementation → checkpoint loop on its own.

When delegating a task to the Executor, the Coordinator sends ONLY: the task description, its sprint contract criteria, and relevant file paths — not the full plan or other tasks' results.

If the Executor escalates a task, the Coordinator records the decision in `.dev-workflow-state.md` under `## Phase 2 — Escalation [task name]` before passing the revised task back.

After each task is implemented, the Coordinator reviews the Executor's result in the state file (`## Phase 2 — Result [task name]`), runs the post-task checkpoint against the sprint contract criteria, and confirms it passes before proceeding to the next task.

### Inter-task commits
After each task's checkpoint passes, create a git commit with message: `[dev-workflow] Task N: [task name]`. This enables:
- Clean per-task diffs for the Verifier
- Rollback to last-good-task if a later task breaks things
- Smaller, reviewable units of change

### Context reset protocol
If any agent signals `CONTEXT LIMIT`:
1. Save all completed work to `.dev-workflow-state.md`.
2. Re-invoke the same agent with a fresh context containing ONLY: the remaining work description + relevant sprint contract criteria + the specific file paths involved.
3. The state file serves as the handoff artifact — the new invocation reads its section to understand what was already done.

## Step 5 — Phase 3: Verification (complex mode only)

If mode is `simple` — skip this step and go to Step 7.

**Important:** Do not commit changes before verification — the Verifier needs to see them in the diff.

Prepare context for the Verifier (ONLY these elements, nothing more):
- User's original requirements (copied verbatim)
- List of task titles from `.dev-workflow-state.md` (no implementation details)
- The `## Sprint Contract` from `.dev-workflow-state.md` (testable criteria)
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
- Re-invoke `dev-verifier` with the same minimal context (requirements + sprint contract + new `git diff HEAD` + task titles).
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

## Context management

Each agent invocation should receive ONLY the state file sections relevant to its current task. Do not pass the entire state file when a subset suffices.

### Context windows per phase:
- **Phase 1 (Coordinator planning)**: `## Metadata` + `## Requirements` only
- **Phase 2 (Executor per-task)**: `## Metadata` + current task from `## Phase 1 — Coordinator Plan` + `## Sprint Contract` (current task criteria only). Do NOT pass prior task results.
- **Phase 2 (Coordinator pre-check approval)**: `## Metadata` + current task plan + Executor's pre-check
- **Phase 3 (Verifier)**: `## Metadata` + `## Requirements` + `## Sprint Contract` + task titles only + git diff (NO Phase 2 results, NO escalations, NO pre-checks)
- **Phase 4 (Fix routing)**: `## Metadata` + specific findings being fixed + `## Sprint Contract` criteria for affected tasks

### State file schema

The state file `.dev-workflow-state.md` has a strict section structure. Each section has an OWNER (the only agent allowed to write to it) and READERS.

| Section | Owner | Readers | Created |
|---|---|---|---|
| `## Metadata` | SKILL | All | Step 2 |
| `## Requirements` | SKILL | All | Step 2 |
| `## Sprint Contract` | Coordinator | Verifier, SKILL | Phase 1 |
| `## Phase 1 — Coordinator Plan` | Coordinator | Executor, SKILL | Phase 1 |
| `## Phase 1 — Code Analysis` | Executor | Coordinator | Phase 1 |
| `## Phase 2 — Pre-check [task]` | Executor | Coordinator | Phase 2 |
| `## Phase 2 — Result [task]` | Executor | Coordinator | Phase 2 |
| `## Phase 2 — Checkpoint [task]` | Coordinator | SKILL | Phase 2 |
| `## Phase 2 — Escalation [task]` | Coordinator | Executor | Phase 2 |
| `## Phase 2 — Summary` | Coordinator | Verifier, SKILL | Phase 2 end |
| `## Active Verification Results` | Verifier | Coordinator, SKILL | Phase 3 |
| `## Verification Score` | Verifier | Coordinator, SKILL | Phase 3 |
| `## Phase 3 — Verification [N]` | Verifier | Coordinator, Executor, SKILL | Phase 3 |
| `## Phase 4 — Fixes [N]` | Coordinator | Executor, SKILL | Phase 4 |
| `## Final Report` | Coordinator | SKILL, User | Step 7 |

Agents MUST NOT write to sections they do not own. Agents SHOULD NOT read sections not listed in their Readers column.

## General principles

- **Quality > speed.** When the pipeline hits an unresolvable problem — stop and ask the user instead of continuing with an error.
- **Verifier isolation is intentional.** Never pass more than: requirements + task titles + sprint contract + git diff + project path to the Verifier.
- **The state file is the pipeline's only memory.** Every agent reads it for current state before acting. Section ownership prevents conflicts.
- **`*-latest` models are used by default** — they always point to the newest version of the model family.
- **Always pass model explicitly.** When invoking any pipeline agent (coordinator, executor, verifier), pass the configured model parameter explicitly in the agent tool call. Frontmatter models may be overridden by the parent session's model if not passed explicitly — never rely on inheritance.
- **Context resets > context accumulation.** When an agent signals CONTEXT LIMIT, re-invoke with fresh context and a structured handoff via the state file.

