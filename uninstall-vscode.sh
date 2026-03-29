#!/usr/bin/env bash
set -euo pipefail

AGENTS_DST="$HOME/.copilot/agents"

FILES=(
  "$AGENTS_DST/dev-coordinator.md"
  "$AGENTS_DST/dev-executor.md"
  "$AGENTS_DST/dev-verifier.md"
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
