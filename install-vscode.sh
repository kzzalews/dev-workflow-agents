#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/vscode-copilot/agents"
AGENT_FILES=("dev-coordinator.agent.md" "dev-executor.agent.md" "dev-verifier.agent.md")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — VS Code Copilot  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

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

if [[ -z "$AGENTS_DST" ]]; then
  echo "ERROR: Unsupported OS. Install agents manually to the VS Code user data agents directory."
  echo "See: https://code.visualstudio.com/docs/copilot/customization/custom-agents"
  exit 1
fi

echo "Target: $AGENTS_DST"
echo ""

# Warn if code CLI not found (non-fatal)
if ! command -v code &>/dev/null; then
  echo "WARNING: 'code' command not found — VS Code may not be installed on this machine."
  printf "         Continue anyway? [y/N] "
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    exit 0
  fi
  echo ""
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

mkdir -p "$AGENTS_DST"

echo "Installing agents..."
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$AGENTS_SRC/$f" "$AGENTS_DST"
done

echo ""
echo "✓ Done."
echo ""
echo "Usage: Open GitHub Copilot Chat → click the agent selector dropdown → choose an agent."
echo "Pipeline: dev-coordinator (plan) → dev-executor (implement) → dev-verifier (review)"
