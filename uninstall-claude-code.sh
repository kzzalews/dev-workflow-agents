#!/usr/bin/env bash
set -euo pipefail

REPO_DST="$HOME/.dev-workflow-agents"
AGENTS_DST="$HOME/.claude/agents"
AGENT_FILES=(
  "$AGENTS_DST/dev-coordinator.md"
  "$AGENTS_DST/dev-executor.md"
  "$AGENTS_DST/dev-verifier.md"
)

echo "Uninstalling dev-workflow-agents from Claude Code..."
echo ""

exit_code=0

echo "Removing agents..."
for f in "${AGENT_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    rm "$f"
    echo "  Removed: $f"
  else
    echo "  WARNING: not found: $f"
    exit_code=1
  fi
done

echo ""
echo "Removing skill plugin..."
if claude plugins list 2>/dev/null | grep -q "dev-workflow-agents"; then
  claude plugins uninstall dev-workflow-agents@kzzalews-dev-workflow-agents 2>&1 | sed 's/^/  /'
else
  echo "  Skill plugin not installed, skipping."
fi

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
