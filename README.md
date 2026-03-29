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
# 1. Register marketplace (once)
claude plugins marketplace add kzzalews/dev-workflow-agents

# 2. Install plugin (skill)
claude plugins install dev-workflow-agents@kzzalews-dev-workflow-agents

# 3. Install agents (bash installer)
git clone https://github.com/kzzalews/dev-workflow-agents.git
cd dev-workflow-agents
./install-claude-code.sh
```

> The agents (`dev-coordinator`, `dev-executor`, `dev-verifier`) cannot be distributed via the plugin system — install them with the bash script. The skill (`/dev-workflow`) is installed via the plugin.

### VS Code Copilot

```bash
git clone https://github.com/kzzalews/dev-workflow-agents.git
cd dev-workflow-agents
./install-vscode.sh
```

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

Invoke agents manually in Copilot Chat using `@` mentions:

| Phase | Command | Model (recommended) |
|---|---|---|
| Phase 1 — Planning | `@dev-coordinator` | Claude Sonnet |
| Phase 2 — Implementation | `@dev-executor` + `@dev-coordinator` | Haiku (executor), Sonnet (coordinator) |
| Phase 3 — Verification | `@dev-verifier` | Claude Sonnet |
| Phase 4 — Fix routing | `@dev-coordinator` | Claude Sonnet |

Switch models using the model picker in Copilot Chat.

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
# Claude Code — plugin
claude plugins uninstall dev-workflow-agents@kzzalews-dev-workflow-agents

# Claude Code — agents (bash)
./uninstall-claude-code.sh

# VS Code Copilot
./uninstall-vscode.sh
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
- `~/.copilot/agents/dev-coordinator.md` — Coordinator agent (claude-sonnet-4-6)
- `~/.copilot/agents/dev-executor.md`    — Executor agent (claude-haiku-4-5)
- `~/.copilot/agents/dev-verifier.md`    — Verifier agent (claude-sonnet-4-6)

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
