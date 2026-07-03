# Agentic Workflow for Pi

A multi-agent orchestration workflow for [Pi](https://pi.dev) — the terminal-based coding agent.

The default Pi acts as an **orchestrator**. It never writes code itself. It delegates to specialized sub-agents, each with its own model and persona.

## Architecture

```
USER
  │
  ▼
PI (ORCHESTRATOR)
  │  model: Anthropic Claude Sonnet 4 (configurable)
  │  role: understand intent, break into tasks, delegate, review, relay
  │
  ├── delegate("frontend-developer", task)
  │     → spawns: pi -p --model google/gemini-2-flash
  │     → returns result to orchestrator
  │
  ├── delegate("software-engineer", task)
  │     → spawns: pi -p --model openai/o4-mini
  │     → returns result to orchestrator
  │
  ├── delegate("code-reviewer", task)
  │     → spawns: pi -p --model anthropic/claude-sonnet-4
  │     → returns result to orchestrator
  │
  ├── delegate("devops-engineer", task)
  │     → spawns: pi -p --model anthropic/claude-sonnet-4
  │     → returns result to orchestrator
  │
  └── delegate("test-engineer", task)
        → spawns: pi -p --model openai/gpt-4o
        → returns result to orchestrator
```

## What's Inside

```
agentic-workflow/
├── .pi/agent/
│   ├── AGENTS.md              # Orchestrator instructions — delegate, never code
│   ├── settings.json         # Pi settings (orchestrator model, compaction, retry)
│   ├── models.json           # Provider config (Anthropic, OpenAI, Google, OpenRouter)
│   ├── sub-agents.json       # Sub-agent roster (models, personas — edit this!)
│   ├── extensions/
│   │   └── sub-agent.ts      # Extension registering the "delegate" tool
│   ├── skills/
│   │   ├── code-review/      # Code review workflow (used by code-reviewer)
│   │   │   ├── SKILL.md
│   │   │   ├── scripts/pr-diff.sh
│   │   │   └── references/checklist.md
│   │   ├── feature-builder/  # Feature building workflow (used by software-engineer)
│   │   │   ├── SKILL.md
│   │   │   └── references/planning-template.md
│   │   └── refactor/         # Refactoring workflow (used by software-engineer)
│   │       ├── SKILL.md
│   │       └── references/techniques.md
│   └── prompts/              # Slash-command templates (orchestrated)
│       ├── review.md         # /review [staged|<PR-URL>|<files>]
│       ├── refactor.md       # /refactor <file-or-dir>
│       ├── feature.md        # /feature <description>
│       ├── debug.md          # /debug <error>
│       └── test.md           # /test [<file>]
├── templates/
│   └── AGENTS.md             # Project-level template (drop into project root)
├── setup.sh                  # Installs everything into ~/.pi/agent/
└── README.md
```

## Quick Start

### 1. Install

```bash
git clone https://github.com/kenken17/agentic-workflow.git
cd agentic-workflow
./setup.sh
```

This copies everything into `~/.pi/agent/` (backing up any existing config).

### 2. Configure Providers

Edit `~/.pi/agent/models.json` and set API keys. You can also set them as env vars:

```bash
export ANTHROPIC_API_KEY=***     # orchestrator + code-reviewer + devops
export OPENAI_API_KEY=***          # software-engineer + test-engineer
export GOOGLE_API_KEY=***       # frontend-developer
```

Or use `/login` in Pi for subscription auth.

Alternative: use OpenRouter for all models — just set `OPENROUTER_API_KEY` and change model IDs in `sub-agents.json` to OpenRouter format.

### 3. Configure Sub-Agents

Edit `~/.pi/agent/sub-agents.json` to adjust:

- **Models**: swap any sub-agent's model (e.g., use GPT-4o for frontend instead of Gemini)
- **Personas**: tweak what each sub-agent specializes in
- **Add/remove agents**: add new entries to the `agents` object

### 4. Set Orchestrator Model

Edit `~/.pi/agent/settings.json`:

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-20250514"
}
```

This is the model that routes tasks. Pick something fast and capable.

### 5. Run

```bash
cd /your/project
pi
```

## Sub-Agents

| Agent | Model | Specialty |
|-------|-------|-----------|
| `frontend-developer` | Google Gemini 2 Flash | UI/UX, React, CSS, responsive design, accessibility |
| `software-engineer` | OpenAI o4-mini | Backend logic, algorithms, API design, general coding |
| `code-reviewer` | Anthropic Claude Sonnet 4 | Code review — bugs, security, performance, style |
| `devops-engineer` | Anthropic Claude Sonnet 4 | CI/CD, Docker, infrastructure, deployment |
| `test-engineer` | OpenAI GPT-4o | Writing and running tests, coverage gaps |

Run `/agents` inside Pi to see the list.

## Prompt Templates

| Command | What It Does |
|---------|-------------|
| `/review [staged\|<PR-URL>\|<files>]` | Orchestrator delegates to code-reviewer |
| `/refactor <file>` | Orchestrator delegates to software-engineer |
| `/feature <description>` | Orchestrator delegates to relevant sub-agents |
| `/debug <error>` | Orchestrator delegates to software-engineer |
| `/test [<file>]` | Orchestrator delegates to test-engineer |

## How Delegation Works

1. You give the orchestrator a task
2. Orchestrator calls `delegate(agent="software-engineer", task="...")` 
3. The sub-agent extension spawns: `pi -p --model openai/o4-mini "You are a senior software engineer... TASK: ..."`
4. The sub-agent runs in print mode, does the work, returns output
5. Orchestrator reviews output and either relays to you or delegates again

The sub-agent has access to the same `read`, `write`, `edit`, `bash` tools in your project directory. It has no memory of the orchestrator's conversation — all context must be in the task description.

## Project-Level Customization

Copy `templates/AGENTS.md` to your project root as `AGENTS.md` and fill it with project-specific info:

```bash
cp templates/AGENTS.md /your/project/AGENTS.md
```

Pi loads this on top of the global AGENTS.md at startup.

## Customizing Sub-Agents

Edit `~/.pi/agent/sub-agents.json`:

```json
{
  "agents": {
    "my-new-agent": {
      "model": "openai/gpt-4o",
      "label": "My Custom Agent",
      "description": "What this agent does",
      "persona": "You are a ..."
    }
  }
}
```

The extension reads this file at startup. New agents appear in the `delegate` tool's enum automatically.

## License

MIT