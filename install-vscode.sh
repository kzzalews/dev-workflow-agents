#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/vscode-copilot/agents"
AGENTS_DST="$HOME/.copilot/agents"

AGENT_FILES=("dev-coordinator.md" "dev-executor.md" "dev-verifier.md")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — VS Code Copilot  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Check VS Code is installed (warn only)
if ! command -v code &>/dev/null; then
  echo "WARNING: 'code' command not found. VS Code may not be installed or not in PATH."
  echo "Continuing anyway..."
  echo ""
fi

# Create destination dir if missing
if [[ ! -d "$AGENTS_DST" ]]; then
  echo "Creating $AGENTS_DST ..."
  mkdir -p "$AGENTS_DST"
fi

# Helper: copy with overwrite prompt
copy_with_prompt() {
  local src="$1"
  local dst="$2"
  local filename
  filename="$(basename "$src")"

  if [[ -f "$dst/$filename" ]]; then
    printf "  %s already exists. Overwrite? [y/N] " "$filename"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "  Skipped: $filename"
      return
    fi
  fi
  cp "$src" "$dst/$filename"
  echo "  Installed: $dst/$filename"
}

echo "Installing agents..."
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$AGENTS_SRC/$f" "$AGENTS_DST"
done

echo ""
echo "✓ Done."
echo "  In VS Code Copilot Chat, use @dev-coordinator to start Phase 1."
echo "  Recommended models: Coordinator/Verifier → Claude Sonnet, Executor → Claude Haiku"
