#!/bin/bash
# setup.sh — Install agentic-workflow into ~/.pi/agent/
# Usage: ./setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="$HOME/.pi/agent"

echo "=== Agentic Workflow Setup ==="
echo "Installing to: $PI_DIR"
echo ""

# Backup existing config if present
if [ -d "$PI_DIR" ]; then
    BACKUP="$PI_DIR.backup.$(date +%Y%m%d%H%M%S)"
    echo "Existing ~/.pi/agent found. Backing up to $BACKUP"
    cp -r "$PI_DIR" "$BACKUP"
    echo ""
fi

# Create directories
mkdir -p "$PI_DIR"
mkdir -p "$PI_DIR/skills"
mkdir -p "$PI_DIR/prompts"

# --- Global AGENTS.md ---
if [ -f "$PI_DIR/AGENTS.md" ]; then
    echo "AGENTS.md already exists — skipping (review manually if needed)"
else
    cp "$SCRIPT_DIR/.pi/agent/AGENTS.md" "$PI_DIR/AGENTS.md"
    echo "Installed: AGENTS.md"
fi

# --- settings.json ---
cp "$SCRIPT_DIR/.pi/agent/settings.json" "$PI_DIR/settings.json"
echo "Installed: settings.json"

# --- models.json (don't overwrite if user already has one) ---
if [ -f "$PI_DIR/models.json" ]; then
    echo "models.json already exists — skipping (review manually if needed)"
else
    cp "$SCRIPT_DIR/.pi/agent/models.json" "$PI_DIR/models.json"
    echo "Installed: models.json"
fi

# --- Skills ---
for skill_dir in "$SCRIPT_DIR"/.pi/agent/skills/*/; do
    skill_name=$(basename "$skill_dir")
    target="$PI_DIR/skills/$skill_name"
    mkdir -p "$target"
    cp -r "$skill_dir"* "$target/"
    echo "Installed skill: $skill_name"
done

# --- Prompt Templates ---
for prompt_file in "$SCRIPT_DIR"/.pi/agent/prompts/*.md; do
    prompt_name=$(basename "$prompt_file")
    cp "$prompt_file" "$PI_DIR/prompts/$prompt_name"
    echo "Installed prompt: /$(basename "$prompt_name" .md)"
done

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Edit $PI_DIR/models.json to configure your providers and API keys"
echo "  2. Set API keys as environment variables or use /login in pi"
echo "  3. Optional: Copy templates/AGENTS.md to your project root as AGENTS.md"
echo "     and fill it with project-specific instructions"
echo "  4. Rename 'git' remote: Uncomment GITHUB_TOKEN temporarily if loading models.json needs it"
echo ""
echo "To start pi with this config, run: pi"