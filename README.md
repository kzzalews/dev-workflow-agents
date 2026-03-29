# dev-workflow-agents

Agentic development workflow for **Claude Code** and **VS Code Copilot**.

Orchestrates a Coordinator → Executor → Verifier pipeline with an adaptive fix loop. Quality-first: the Verifier reviews code with fresh eyes, without knowledge of implementation decisions.

---

## Requirements

| Platform | Requirement |
|---|---|
| Claude Code | [Claude Code CLI](https://claude.ai/code) installed |
| VS Code Copilot | VS Code + active GitHub Copilot subscription |

---

## Quick Install

### Claude Code

```bash
curl -fsSL https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main/install-claude-code.sh | bash
```

> Installs agents to `~/.claude/agents/` and registers the `/dev-workflow` skill via `claude plugins`.

### VS Code Copilot

```bash
curl -fsSL https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main/install-vscode.sh | bash
```

> Installs agents to the VS Code user data `agents/` directory.

---

## Usage

### Claude Code

Type `/dev-workflow` in Claude Code to start. You will see:

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
╚══════════════════════════════════════════╝
```

### VS Code Copilot

Select **`dev-workflow`** from the agent dropdown to start. It guides you through the entire pipeline — tells you which agent to switch to at each step and what to send.

| Agent | Role |
|---|---|
| `dev-workflow` | Entry point — collects requirements, guides the pipeline |
| `dev-coordinator` | Planning, pre-check approval, fix routing |
| `dev-executor` | Code analysis and implementation |
| `dev-verifier` | Fresh-eyes code review |

> Custom agents use the dropdown selector — they are NOT invoked via `@mention`. The `@mention` syntax only works for built-in chat participants (like `@github` or `@terminal`).

---

## Default Models

| Role | Claude Code | VS Code Copilot |
|---|---|---|
| Coordinator | `claude-sonnet-latest` | `claude-sonnet-4-6` |
| Executor | `claude-haiku-latest` | `claude-haiku-4-5` |
| Verifier | `claude-sonnet-latest` | `claude-sonnet-4-6` |

**Claude Code** uses `*-latest` aliases — automatically upgrades to the newest model version with no config changes needed.

**VS Code Copilot** uses fixed model IDs. Update `model:` in the agent frontmatter to upgrade.

### Override models at runtime (Claude Code only)

At the startup screen, type: `coordinator=claude-opus-latest`

Available roles: `coordinator`, `executor`, `verifier`

---

## Pipeline Overview

```
User → /dev-workflow
  │
  ▼
[Startup screen: mode + model config]
  │
  ▼
Phase 1 — Coordinator plans, Executor analyzes code
  │        User approves plan
  ▼
Phase 2 — Coordinator oversees, Executor implements
  │        (pre-check → approval → implementation per task)
  ▼
Phase 3 — Verifier reviews with fresh eyes [complex only]
  │        (receives: requirements + task titles + git diff only)
  ▼
Phase 4 — Fix loop (max 3 iterations)
  │   MINOR findings    → Executor fixes directly
  │   ARCHITECTURAL     → Coordinator plans → Executor fixes
  │   UNCERTAIN         → User decides
  ▼
Final report + cleanup
```

---

## Uninstall

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main/uninstall-claude-code.sh | bash

# VS Code Copilot
curl -fsSL https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main/uninstall-vscode.sh | bash
```

---

<!-- AGENT CONTEXT -->
## Package structure for agents

Installed files after `install-claude-code.sh`:
- `~/.claude/agents/dev-coordinator.md` — Coordinator agent (claude-sonnet-latest)
- `~/.claude/agents/dev-executor.md`    — Executor agent (claude-haiku-latest)
- `~/.claude/agents/dev-verifier.md`    — Verifier agent (claude-sonnet-latest)
- `~/.claude/plugins/cache/kzzalews-dev-workflow-agents/dev-workflow-agents/1.0.0/skills/dev-workflow/SKILL.md` — Orchestrating skill (invoked via /dev-workflow)

Installed files after `install-vscode.sh`:
- `<vscode-user-data>/agents/dev-coordinator.agent.md` — Coordinator agent (claude-sonnet-4-6)
- `<vscode-user-data>/agents/dev-executor.agent.md`    — Executor agent (claude-haiku-4-5)
- `<vscode-user-data>/agents/dev-verifier.agent.md`    — Verifier agent (claude-sonnet-4-6)

`<vscode-user-data>` per OS: macOS `~/Library/Application Support/Code/User`, Linux `~/.config/Code/User`, Windows `%APPDATA%\Code\User`

State file created at runtime (deleted on completion):
- `.dev-workflow-state.md` — pipeline memory: plan, pre-checks, results, verification findings

Pipeline agent call sequence:
1. dev-coordinator (Phase 1: analyze + plan, checkpoint with user)
2. dev-executor (Phase 1: code analysis, read-only)
3. dev-coordinator (Phase 2: approve pre-checks)
4. dev-executor (Phase 2: pre-check + implement, per task)
5. dev-verifier (Phase 3: fresh-eyes review, complex mode only)
6. Fix loop: MINOR→dev-executor, ARCHITECTURAL→dev-coordinator→dev-executor, UNCERTAIN→user
7. dev-coordinator (final report)

Model info: each agent outputs `[Model: <id>]` as the first line of every response.
<!-- END AGENT CONTEXT -->
