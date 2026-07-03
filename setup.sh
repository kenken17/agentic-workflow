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
mkdir -p "$PI_DIR/extensions"

# --- Global AGENTS.md (Orchestrator instructions) ---
cp "$SCRIPT_DIR/.pi/agent/AGENTS.md" "$PI_DIR/AGENTS.md"
echo "Installed: AGENTS.md (orchestrator instructions)"

# --- settings.json ---
if [ -f "$PI_DIR/settings.json" ]; then
    echo "settings.json already exists — backing up and overwriting"
    cp "$PI_DIR/settings.json" "$PI_DIR/settings.json.bak"
fi
cp "$SCRIPT_DIR/.pi/agent/settings.json" "$PI_DIR/settings.json"
echo "Installed: settings.json"

# --- models.json (don't overwrite if user already has one) ---
if [ -f "$PI_DIR/models.json" ]; then
    echo "models.json already exists — skipping (review manually if needed)"
else
    cp "$SCRIPT_DIR/.pi/agent/models.json" "$PI_DIR/models.json"
    echo "Installed: models.json"
fi

# --- sub-agents.json (sub-agent roster) ---
if [ -f "$PI_DIR/sub-agents.json" ]; then
    echo "sub-agents.json already exists — skipping (edit manually to add agents)"
else
    cp "$SCRIPT_DIR/.pi/agent/sub-agents.json" "$PI_DIR/sub-agents.json"
    echo "Installed: sub-agents.json"
fi

# --- Extension: sub-agent.ts ---
cp "$SCRIPT_DIR/.pi/agent/extensions/sub-agent.ts" "$PI_DIR/extensions/sub-agent.ts"
echo "Installed: extensions/sub-agent.ts"

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
echo "  1. Edit $PI_DIR/models.json to configure your provider API keys"
echo "  2. Edit $PI_DIR/sub-agents.json to adjust sub-agent models and personas"
echo "  3. Set API keys as environment variables:"
echo "     export ANTHROPIC_API_KEY=***     echo "     export OPENAI_API_KEY=***=***"
echo "     export GOOGLE_API_KEY=*** default model in $PI_DIR/settings.json (currently anthropic/claude-sonnet-4)"
echo "     This is the orchestrator model — pick a fast, capable model for routing"
echo "  5. Optional: Copy templates/AGENTS.md to your project root"
echo "  6. Run: pi"
echo ""
echo "Sub-agents available:"
echo "  frontend-developer  → Google Gemini 2 Flash"
echo "  software-engineer   → OpenAI o4-mini"
echo "  code-reviewer       → Anthropic Claude Sonnet 4"
echo "  devops-engineer     → Anthropic Claude Sonnet 4"
echo "  test-engineer       → OpenAI GPT-4o"