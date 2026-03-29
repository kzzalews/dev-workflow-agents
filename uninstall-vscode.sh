#!/usr/bin/env bash
set -euo pipefail

detect_vscode_agents_dir() {
  case "$(uname -s)" in
    Darwin)  echo "$HOME/Library/Application Support/Code/User/agents" ;;
    Linux)   echo "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/agents" ;;
    MINGW*|MSYS*|CYGWIN*) echo "${APPDATA}/Code/User/agents" ;;
    *)       echo "" ;;
  esac
}

REPO_DST="$HOME/.dev-workflow-agents"
AGENTS_DST="$(detect_vscode_agents_dir)"
AGENT_FILES=("dev-workflow" "dev-coordinator" "dev-executor" "dev-verifier")

echo "Uninstalling dev-workflow-agents from VS Code Copilot..."
echo ""

exit_code=0
for f in "${AGENT_FILES[@]}"; do
  dst="$AGENTS_DST/$f.agent.md"
  if [[ -f "$dst" ]]; then
    rm "$dst"
    echo "  Removed: $dst"
  else
    echo "  WARNING: not found: $dst"
    exit_code=1
  fi
done

# Remove VS Code agents from ~/.claude/agents/ (installed with .agent.md extension).
# Claude Code's own agents use .md extension, so there is no conflict.
CLAUDE_AGENTS_DST="$HOME/.claude/agents"
for f in "${AGENT_FILES[@]}"; do
  dst="$CLAUDE_AGENTS_DST/$f.agent.md"
  if [[ -f "$dst" ]]; then
    rm "$dst"
    echo "  Removed: $dst"
  fi
done

if [[ -d "$REPO_DST" ]]; then
  printf "\nRemove local repo cache (%s)? [y/N] " "$REPO_DST"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -rf "$REPO_DST"
    echo "  Removed: $REPO_DST"
  fi
fi

echo ""
if [[ $exit_code -eq 0 ]]; then
  echo "✓ Uninstall complete."
else
  echo "✓ Uninstall complete (some files were already missing)."
fi
exit $exit_code
