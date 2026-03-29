#!/usr/bin/env bash
set -euo pipefail

REPO_DST="$HOME/.dev-workflow-agents"
AGENTS_DST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"
AGENT_FILES=("dev-workflow" "dev-coordinator" "dev-executor" "dev-verifier")

echo "Uninstalling dev-workflow-agents from OpenCode..."
echo ""

exit_code=0
for f in "${AGENT_FILES[@]}"; do
  dst="$AGENTS_DST/$f.md"
  if [[ -f "$dst" ]]; then
    rm "$dst"
    echo "  Removed: $dst"
  else
    echo "  WARNING: not found: $dst"
    exit_code=1
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
  echo "Uninstall complete."
else
  echo "Uninstall complete (some files were already missing)."
fi
exit $exit_code
