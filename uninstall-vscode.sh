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

echo ""
if [[ $exit_code -eq 0 ]]; then
  echo "✓ Uninstall complete."
else
  echo "✓ Uninstall complete (some files were already missing)."
fi
exit $exit_code
