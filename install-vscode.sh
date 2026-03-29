#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/kzzalews/dev-workflow-agents.git"
REPO_DST="$HOME/.dev-workflow-agents"
AGENT_FILES=("dev-workflow" "dev-coordinator" "dev-executor" "dev-verifier")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — VS Code Copilot  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v git &>/dev/null; then
  echo "ERROR: git is required but not installed."
  exit 1
fi

# Detect VS Code user data agents directory
detect_vscode_agents_dir() {
  case "$(uname -s)" in
    Darwin)  echo "$HOME/Library/Application Support/Code/User/agents" ;;
    Linux)   echo "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/agents" ;;
    MINGW*|MSYS*|CYGWIN*) echo "${APPDATA}/Code/User/agents" ;;
    *)       echo "" ;;
  esac
}

AGENTS_DST="$(detect_vscode_agents_dir)"

if [[ -z "$AGENTS_DST" ]]; then
  echo "ERROR: Unsupported OS."
  echo "See: https://code.visualstudio.com/docs/copilot/customization/custom-agents"
  exit 1
fi

echo "Target: $AGENTS_DST"
echo ""

if ! command -v code &>/dev/null; then
  echo "WARNING: 'code' command not found — VS Code may not be installed on this machine."
  if [[ -t 0 ]]; then
    printf "         Continue anyway? [y/N] "
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then exit 0; fi
  else
    echo "         Continuing in non-interactive mode."
  fi
  echo ""
fi

# Clone or update repo
if [[ -d "$REPO_DST/.git" ]]; then
  echo "Updating local repo ($REPO_DST)..."
  git -C "$REPO_DST" pull --ff-only 2>&1 | sed 's/^/  /'
else
  echo "Cloning repo to $REPO_DST..."
  git clone --depth=1 "$REPO" "$REPO_DST" 2>&1 | sed 's/^/  /'
fi
echo ""

# Helper: copy with overwrite prompt
copy_with_prompt() {
  local src="$1"
  local dst_file="$2"
  local filename
  filename="$(basename "$dst_file")"

  if [[ -f "$dst_file" ]]; then
    if [[ -t 0 ]]; then
      printf "  %s already exists. Overwrite? [Y/n] " "$filename"
      read -r answer
      if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "  Skipped: $filename"
        return
      fi
    else
      echo "  Overwriting: $filename (non-interactive)"
    fi
  fi
  cp "$src" "$dst_file"
  echo "  Installed: $dst_file"
}

mkdir -p "$AGENTS_DST"

echo "Installing agents to VS Code user data ($AGENTS_DST)..."
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$REPO_DST/vscode-copilot/agents/$f.agent.md" "$AGENTS_DST/$f.agent.md"
done

# VS Code also loads agents from ~/.claude/agents/ (Claude-compatible global path).
# Install dev-workflow there so it is visible alongside the other pipeline agents,
# which are already placed in ~/.claude/agents/ by install-claude-code.sh.
CLAUDE_AGENTS_DST="$HOME/.claude/agents"
if [[ -d "$CLAUDE_AGENTS_DST" ]]; then
  echo ""
  echo "Installing dev-workflow to Claude agents dir ($CLAUDE_AGENTS_DST)..."
  copy_with_prompt "$REPO_DST/claude-code/agents/dev-workflow.md" "$CLAUDE_AGENTS_DST/dev-workflow.md"
else
  echo ""
  echo "Creating Claude agents dir and installing dev-workflow ($CLAUDE_AGENTS_DST)..."
  mkdir -p "$CLAUDE_AGENTS_DST"
  copy_with_prompt "$REPO_DST/claude-code/agents/dev-workflow.md" "$CLAUDE_AGENTS_DST/dev-workflow.md"
fi

echo ""
echo "Done."
echo ""
echo "Usage: Open GitHub Copilot Chat → agent selector dropdown → dev-workflow"
