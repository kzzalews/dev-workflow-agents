#!/usr/bin/env bash
set -euo pipefail

# Detect VS Code user data agents directory
detect_vscode_agents_dir() {
  case "$(uname -s)" in
    Darwin)
      echo "$HOME/Library/Application Support/Code/User/agents"
      ;;
    Linux)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/agents"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "${APPDATA}/Code/User/agents"
      ;;
    *)
      echo ""
      ;;
  esac
}

AGENTS_DST="$(detect_vscode_agents_dir)"

FILES=(
  "$AGENTS_DST/dev-coordinator.agent.md"
  "$AGENTS_DST/dev-executor.agent.md"
  "$AGENTS_DST/dev-verifier.agent.md"
)

echo "Uninstalling dev-workflow-agents from VS Code Copilot..."
echo ""

exit_code=0
for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    rm "$f"
    echo "  Removed: $f"
  else
    echo "  WARNING: not found: $f"
    exit_code=1
  fi
done

echo ""
if [[ $exit_code -eq 0 ]]; then
  echo "✓ Uninstall complete."
else
  echo "✓ Uninstall complete (some files were already missing)."
fi
exit $exit_code
