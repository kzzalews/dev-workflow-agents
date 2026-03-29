#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/kzzalews/dev-workflow-agents.git"
REPO_DST="$HOME/.dev-workflow-agents"
AGENT_FILES=("dev-workflow" "dev-coordinator" "dev-executor" "dev-verifier")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — OpenCode          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v git &>/dev/null; then
  echo "ERROR: git is required but not installed."
  exit 1
fi

AGENTS_DST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"

echo "Target: $AGENTS_DST"
echo ""

if ! command -v opencode &>/dev/null; then
  echo "WARNING: 'opencode' command not found."
  echo "         Install OpenCode: https://opencode.ai/docs"
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

echo "Installing agents..."
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$REPO_DST/opencode/agents/$f.md" "$AGENTS_DST/$f.md"
done

echo ""
echo "Done."
echo ""
echo "Usage:"
echo "  1. Start OpenCode in your project directory"
echo "  2. Press Tab to switch to the 'dev-workflow' agent"
echo "  3. Describe your task — the guide will walk you through the pipeline"
echo ""
echo "Optional: configure models per agent in ~/.config/opencode/opencode.json"
echo "  Recommended: sonnet for coordinator/verifier, haiku for executor"
