#!/bin/bash
# init.sh - Scaffold agentic-workflow into an existing project
# Usage: cd /your/project && /path/to/agentic-workflow/init.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$(pwd)}"

echo "=== Agentic Workflow Init ==="
echo "Target project: $TARGET_DIR"
echo ""

# Backup existing .pi directory if present
if [ -d "$TARGET_DIR/.pi" ]; then
    BACKUP="$TARGET_DIR/.pi.backup.$(date +%Y%m%d%H%M%S)"
    echo "Existing .pi/ found. Backing up to $BACKUP"
    cp -r "$TARGET_DIR/.pi" "$BACKUP"
    echo ""
fi

# Copy .pi/ directory
cp -r "$SCRIPT_DIR/.pi" "$TARGET_DIR/.pi"
echo "Installed: .pi/ (settings, models, sub-agents, extensions, skills, prompts)"

# Copy or backup AGENTS.md
if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    cp "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md.bak"
    echo "Existing AGENTS.md backed up to AGENTS.md.bak"
fi
cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
echo "Installed: AGENTS.md (orchestrator instructions)"

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Set API keys:"
echo "     export ANTHROPIC_API_KEY=***"
echo "     export OPENAI_API_KEY=***"
echo "     export GOOGLE_API_KEY=***"
echo "  2. Edit .pi/sub-agents.json to adjust sub-agent models and personas"
echo "  3. Edit .pi/settings.json to set the orchestrator model"
echo "  4. Run: pi"
