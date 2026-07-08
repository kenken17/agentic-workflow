#!/bin/bash
# init.sh — Create a new project with agentic-workflow pre-configured
# Usage:
#   /path/to/agentic-workflow/init.sh [project-name]
#   /path/to/agentic-workflow/init.sh my-app
# If no name given, it prompts interactively.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║   Agentic Workflow — Project Scaffolder    ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ─── 1. Project name ───
PROJECT_NAME="${1:-}"
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${BOLD}Project name?${RESET} ${DIM}(this will be the directory name)${RESET}"
    read -r -p "> " PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: project name required${RESET}"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$PROJECT_NAME")" 2>/dev/null && pwd)/$(basename "$PROJECT_NAME")"
if [[ "$PROJECT_NAME" != /* ]]; then
    PROJECT_DIR="$(pwd)/$PROJECT_NAME"
fi

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}Warning: $PROJECT_DIR already exists${RESET}"
    read -r -p "Overwrite? (y/N) " CONFIRM
    if [[ "$CONFIRM" != [yY] ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$PROJECT_DIR"
fi

mkdir -p "$PROJECT_DIR"
echo -e "${GREEN}✓${RESET} Created project directory: ${BOLD}$PROJECT_DIR${RESET}"
echo ""

# ─── 2. Copy agentic-workflow files ───
echo -e "${BOLD}Copying agentic workflow files...${RESET}"

cp -r "$SCRIPT_DIR/.pi" "$PROJECT_DIR/.pi"
echo -e "  ${GREEN}✓${RESET} .pi/ (settings, models, sub-agents, extensions, skills, prompts)"

cp "$SCRIPT_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
echo -e "  ${GREEN}✓${RESET} AGENTS.md (orchestrator instructions)"

cp "$SCRIPT_DIR/.gitignore" "$PROJECT_DIR/.gitignore" 2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} .gitignore"
echo ""

# ─── 3. API Key Setup ───
echo -e "${BOLD}${CYAN}═══ Provider Setup ═══${RESET}"
echo "Which providers do you want to configure? (Enter numbers, comma-separated)"
echo -e "  ${DIM}1${RESET}  Anthropic  ${DIM}(orchestrator + code-reviewer + devops)${RESET}"
echo -e "  ${DIM}2${RESET}  OpenAI     ${DIM}(software-engineer + test-engineer)${RESET}"
echo -e "  ${DIM}3${RESET}  Google     ${DIM}(frontend-developer)${RESET}"
echo -e "  ${DIM}4${RESET}  OpenRouter ${DIM}(all models via one API — alternative to above)${RESET}"
echo -e "  ${DIM}5${RESET}  Skip (use /login in Pi instead)${RESET}"
echo ""
read -r -p "Providers [1,2,3]: " PROVIDER_CHOICES

if [ -z "$PROVIDER_CHOICES" ]; then
    PROVIDER_CHOICES="1,2,3"
fi

ENV_FILE="$PROJECT_DIR/.env"
touch "$ENV_FILE"

has_provider() {
    echo "$PROVIDER_CHOICES" | grep -q "$1"
}

# Anthropic
if has_provider "1"; then
    echo ""
    echo -e "${BOLD}Anthropic API Key:${RESET} ${DIM}(get from console.anthropic.com)${RESET}"
    read -r -s -p "> " ANTHROPIC_KEY
    echo ""
    if [ -n "$ANTHROPIC_KEY" ]; then
        echo "ANTHROPIC_API_KEY=$ANTHROPIC_KEY" >> "$ENV_FILE"
        echo -e "  ${GREEN}✓${RESET} Anthropic configured"
    else
        echo -e "  ${YELLOW}⚠${RESET} Skipped (no key entered) — set ANTHROPIC_API_KEY later"
    fi
fi

# OpenAI
if has_provider "2"; then
    echo ""
    echo -e "${BOLD}OpenAI API Key:${RESET} ${DIM}(get from platform.openai.com)${RESET}"
    read -r -s -p "> " OPENAI_KEY
    echo ""
    if [ -n "$OPENAI_KEY" ]; then
        echo "OPENAI_API_KEY=$OPENAI_KEY" >> "$ENV_FILE"
        echo -e "  ${GREEN}✓${RESET} OpenAI configured"
    else
        echo -e "  ${YELLOW}⚠${RESET} Skipped (no key entered) — set OPENAI_API_KEY later"
    fi
fi

# Google
if has_provider "3"; then
    echo ""
    echo -e "${BOLD}Google API Key:${RESET} ${DIM}(get from aistudio.google.com)${RESET}"
    read -r -s -p "> " GOOGLE_KEY
    echo ""
    if [ -n "$GOOGLE_KEY" ]; then
        echo "GOOGLE_API_KEY=$GOOGLE_KEY" >> "$ENV_FILE"
        echo -e "  ${GREEN}✓${RESET} Google configured"
    else
        echo -e "  ${YELLOW}⚠${RESET} Skipped (no key entered) — set GOOGLE_API_KEY later"
    fi
fi

# OpenRouter (replaces all direct providers)
if has_provider "4"; then
    echo ""
    echo -e "${BOLD}OpenRouter API Key:${RESET} ${DIM}(get from openrouter.ai)${RESET}"
    read -r -s -p "> " OPENROUTER_KEY
    echo ""
    if [ -n "$OPENROUTER_KEY" ]; then
        echo "OPENROUTER_API_KEY=$OPENROUTER_KEY" >> "$ENV_FILE"
        echo -e "  ${GREEN}✓${RESET} OpenRouter configured"
        echo -e "  ${YELLOW}⚠${RESET} You'll need to update .pi/sub-agents.json to use openrouter/ model IDs"
    else
        echo -e "  ${YELLOW}⚠${RESET} Skipped (no key entered)"
    fi
fi

# Add .env to .gitignore if not already there
if ! grep -q "^\.env$" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
    # Ensure file ends with newline before appending
    [ -s "$PROJECT_DIR/.gitignore" ] && [ "$(tail -c1 "$PROJECT_DIR/.gitignore" 2>/dev/null)" != $'\n' ] && echo "" >> "$PROJECT_DIR/.gitignore"
    echo ".env" >> "$PROJECT_DIR/.gitignore"
fi

echo ""

# ─── 4. Orchestrator Model ───
echo -e "${BOLD}${CYAN}═══ Orchestrator Model ═══${RESET}"
echo "The orchestrator routes tasks to sub-agents. Pick a fast, capable model:"
echo -e "  ${DIM}1${RESET}  Anthropic Claude Sonnet 4  ${DIM}(default)${RESET}"
echo -e "  ${DIM}2${RESET}  OpenAI GPT-4o"
echo -e "  ${DIM}3${RESET}  Google Gemini 2 Flash"
echo -e "  ${DIM}4${RESET}  Custom (enter provider/model manually)"
echo ""
read -r -p "Choice [1]: " ORCH_CHOICE

case "$ORCH_CHOICE" in
    2)
        ORCH_PROVIDER="openai"
        ORCH_MODEL="gpt-4o"
        ;;
    3)
        ORCH_PROVIDER="google"
        ORCH_MODEL="gemini-2-flash"
        ;;
    4)
        read -r -p "Provider: " ORCH_PROVIDER
        read -r -p "Model: " ORCH_MODEL
        ;;
    *)
        ORCH_PROVIDER="anthropic"
        ORCH_MODEL="claude-sonnet-4-20250514"
        ;;
esac

# Patch settings.json
SETTINGS_FILE="$PROJECT_DIR/.pi/settings.json"
if command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    s = json.load(f)
s['defaultProvider'] = '$ORCH_PROVIDER'
s['defaultModel'] = '$ORCH_MODEL'
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null && echo -e "  ${GREEN}✓${RESET} Orchestrator set to ${BOLD}$ORCH_PROVIDER/$ORCH_MODEL${RESET}" \
    || echo -e "  ${YELLOW}⚠${RESET} Could not patch settings.json — edit manually"
elif command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const s = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf-8'));
s.defaultProvider = '$ORCH_PROVIDER';
s.defaultModel = '$ORCH_MODEL';
fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(s, null, 2));
" 2>/dev/null && echo -e "  ${GREEN}✓${RESET} Orchestrator set to ${BOLD}$ORCH_PROVIDER/$ORCH_MODEL${RESET}" \
    || echo -e "  ${YELLOW}⚠${RESET} Could not patch settings.json — edit manually"
else
    echo -e "  ${YELLOW}⚠${RESET} No python3/node — edit .pi/settings.json manually"
fi
echo ""

# ─── 5. Project Description (for AGENTS.md) ───
echo -e "${BOLD}${CYAN}═══ Project Info ═══${RESET}"
read -r -p "Short description of your project (optional): " PROJECT_DESC
if [ -n "$PROJECT_DESC" ]; then
    echo "# Project: $(basename "$PROJECT_DIR")" > "$PROJECT_DIR/AGENTS.md.tmp"
    echo "" >> "$PROJECT_DIR/AGENTS.md.tmp"
    echo "> $PROJECT_DESC" >> "$PROJECT_DIR/AGENTS.md.tmp"
    echo "" >> "$PROJECT_DIR/AGENTS.md.tmp"
    echo "---" >> "$PROJECT_DIR/AGENTS.md.tmp"
    echo "" >> "$PROJECT_DIR/AGENTS.md.tmp"
    cat "$PROJECT_DIR/AGENTS.md" >> "$PROJECT_DIR/AGENTS.md.tmp"
    mv "$PROJECT_DIR/AGENTS.md.tmp" "$PROJECT_DIR/AGENTS.md"
    echo -e "  ${GREEN}✓${RESET} Project description added to AGENTS.md"
fi
echo ""

# ─── 6. Git Init ───
echo -e "${BOLD}Initializing git...${RESET}"
cd "$PROJECT_DIR"
if [ ! -d .git ]; then
    git init -q
    echo -e "  ${GREEN}✓${RESET} Git initialized"
else
    echo -e "  ${DIM}Git already initialized${RESET}"
fi

# Make sure .env is ignored
if ! git check-ignore .env &>/dev/null; then
    if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        [ -s .gitignore ] && [ "$(tail -c1 .gitignore 2>/dev/null)" != $'\n' ] && echo "" >> .gitignore
        echo ".env" >> .gitignore
    fi
fi
echo ""

# ─── 7. Summary ───
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}  ✓ Project ready!${RESET}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}"
echo ""
echo -e "${BOLD}Location:${RESET}  $PROJECT_DIR"
echo -e "${BOLD}Config:${RESET}    .pi/ (project-level — isolated to this project)"
echo ""
echo -e "${BOLD}What's inside:${RESET}"
echo -e "  ${DIM}•${RESET} AGENTS.md          — Orchestrator instructions"
echo -e "  ${DIM}•${RESET} .pi/settings.json   — Orchestrator model: $ORCH_PROVIDER/$ORCH_MODEL"
echo -e "  ${DIM}•${RESET} .pi/models.json     — Provider config"
echo -e "  ${DIM}•${RESET} .pi/sub-agents.json  — 5 sub-agents (edit to customize)"
echo -e "  ${DIM}•${RESET} .pi/extensions/     — delegate tool + team roster"
echo -e "  ${DIM}•${RESET} .pi/skills/         — code-review, feature-builder, refactor"
echo -e "  ${DIM}•${RESET} .pi/prompts/        — /review /refactor /feature /debug /test"
if [ -f "$ENV_FILE" ] && [ -s "$ENV_FILE" ]; then
    echo -e "  ${DIM}•${RESET} .env               — API keys (gitignored)"
fi
echo ""
echo -e "${BOLD}Sub-agents:${RESET}"
echo -e "  frontend-developer  → Google Gemini 2 Flash"
echo -e "  software-engineer   → OpenAI o4-mini"
echo -e "  code-reviewer       → Anthropic Claude Sonnet 4"
echo -e "  devops-engineer     → Anthropic Claude Sonnet 4"
echo -e "  test-engineer       → OpenAI GPT-4o"
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo -e "  ${CYAN}cd${RESET} $PROJECT_DIR"
if [ -f "$ENV_FILE" ] && [ -s "$ENV_FILE" ]; then
    echo -e "  ${CYAN}source${RESET} .env  ${DIM}# load API keys into shell${RESET}"
else
    echo -e "  ${DIM}# Set API keys as env vars or use /login in Pi${RESET}"
fi
echo -e "  ${CYAN}pi${RESET}              ${DIM}# start coding with your agent team${RESET}"
echo ""
echo -e "${BOLD}Commands inside Pi:${RESET}"
echo -e "  /team           — see all sub-agents"
echo -e "  /team-detail    — sub-agent details with personas"
echo -e "  /feature <desc> — build a feature (delegates to sub-agents)"
echo -e "  /review         — review code changes"
echo -e "  /test [<file>]  — write/run tests"
echo -e "  /debug <error>  — debug an issue"
echo -e "  /refactor <f>   — refactor code"
