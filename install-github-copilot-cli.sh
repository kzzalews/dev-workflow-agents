#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/kzzalews/dev-workflow-agents.git"
REPO_DST="$HOME/.dev-workflow-agents"
AGENTS_DST="$HOME/.copilot/agents"
AGENT_FILES=("dev-coordinator" "dev-executor" "dev-verifier" "dev-workflow")

echo "╔══════════════════════════════════════════╗"
echo "║  dev-workflow-agents — GitHub Copilot CLI║"
echo "╚══════════════════════════════════════════╝"
echo ""

if ! command -v copilot &>/dev/null; then
  echo "ERROR: GitHub Copilot CLI (copilot) not found."
  echo "Install it first: https://docs.github.com/copilot/how-tos/copilot-cli"
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "ERROR: git is required but not installed."
  exit 1
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

echo "Installing agents..."
mkdir -p "$AGENTS_DST"
for f in "${AGENT_FILES[@]}"; do
  copy_with_prompt "$REPO_DST/claude-code/agents/$f.md" "$AGENTS_DST/$f.md"
done

echo ""
echo "Installing skill (plugin)..."

if copilot plugin list 2>/dev/null | grep -q "dev-workflow-agents"; then
  echo "  Skill plugin already installed."
else
  echo "  Registering marketplace..."
  copilot plugin marketplace add kzzalews/dev-workflow-agents 2>&1 | sed 's/^/  /' || true

  echo "  Installing plugin..."
  copilot plugin install dev-workflow-agents@kzzalews-dev-workflow-agents 2>&1 | sed 's/^/  /'
fi

echo ""
echo "✓ Done. Start a new copilot session, then run /dev-workflow to start."
