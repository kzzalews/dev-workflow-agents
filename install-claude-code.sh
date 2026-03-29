#!/usr/bin/env bash
set -euo pipefail

BASE="https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main"
AGENTS_DST="$HOME/.claude/agents"
AGENT_FILES=("dev-coordinator" "dev-executor" "dev-verifier")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — Claude Code       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [[ ! -d "$HOME/.claude" ]]; then
  echo "ERROR: ~/.claude not found. Is Claude Code installed?"
  echo "Install Claude Code first: https://claude.ai/code"
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not installed."
  exit 1
fi

# Helper: download with overwrite prompt
download_with_prompt() {
  local url="$1"
  local dst_file="$2"
  local filename
  filename="$(basename "$dst_file")"

  if [[ -f "$dst_file" ]]; then
    printf "  %s already exists. Overwrite? [y/N] " "$filename"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "  Skipped: $filename"
      return
    fi
  fi
  curl -fsSL "$url" -o "$dst_file"
  echo "  Installed: $dst_file"
}

echo "Installing agents..."
mkdir -p "$AGENTS_DST"
for f in "${AGENT_FILES[@]}"; do
  download_with_prompt "$BASE/claude-code/agents/$f.md" "$AGENTS_DST/$f.md"
done

echo ""
echo "Installing skill (plugin)..."

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
