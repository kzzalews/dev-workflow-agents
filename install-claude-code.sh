#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/claude-code/agents"
AGENTS_DST="$HOME/.claude/agents"
AGENT_FILES=("dev-coordinator.md" "dev-executor.md" "dev-verifier.md")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — Claude Code       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Check Claude Code is installed
if [[ ! -d "$HOME/.claude" ]]; then
  echo "ERROR: ~/.claude not found. Is Claude Code installed?"
  echo "Install Claude Code first: https://claude.ai/code"
  exit 1
fi

# Helper: copy with overwrite prompt
copy_with_prompt() {
  local src="$1"
  local dst_dir="$2"
  local filename
  filename="$(basename "$src")"

  if [[ -f "$dst_dir/$filename" ]]; then
    printf "  %s already exists. Overwrite? [y/N] " "$filename"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "  Skipped: $filename"
      return
    fi
  fi
  cp "$src" "$dst_dir/$filename"
  echo "  Installed: $dst_dir/$filename"
}

# Install agents
echo "Installing agents..."
mkdir -p "$AGENTS_DST"
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$AGENTS_SRC/$f" "$AGENTS_DST"
done

echo ""
echo "Installing skill (plugin)..."

# Check if already installed
if claude plugins list 2>/dev/null | grep -q "dev-workflow-agents"; then
  echo "  Skill plugin already installed."
else
  echo "  Registering marketplace..."
  claude plugins marketplace add kzzalews/dev-workflow-agents 2>&1 | sed 's/^/  /'

  echo "  Installing plugin..."
  claude plugins install dev-workflow-agents@kzzalews-dev-workflow-agents 2>&1 | sed 's/^/  /'
fi

echo ""
echo "✓ Done. Restart Claude Code, then run /dev-workflow to start."
