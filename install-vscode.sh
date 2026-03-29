#!/usr/bin/env bash
set -euo pipefail

BASE="https://raw.githubusercontent.com/kzzalews/dev-workflow-agents/main"
AGENT_FILES=("dev-workflow" "dev-coordinator" "dev-executor" "dev-verifier")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — VS Code Copilot  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not installed."
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
  printf "         Continue anyway? [y/N] "
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then exit 0; fi
  echo ""
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

mkdir -p "$AGENTS_DST"

echo "Installing agents..."
for f in "${AGENT_FILES[@]}"; do
  download_with_prompt "$BASE/vscode-copilot/agents/$f.agent.md" "$AGENTS_DST/$f.agent.md"
done

echo ""
echo "✓ Done."
echo ""
echo "Usage: Open GitHub Copilot Chat → agent selector dropdown → dev-workflow"
