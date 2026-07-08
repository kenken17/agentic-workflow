# Agentic Workflow for Pi

A self-contained, project-level multi-agent orchestration config for [Pi](https://pi.dev) — the terminal-based coding agent by Earendil Inc.

No global install. No `~/.pi/agent/` pollution. Everything lives inside your project's `.pi/` directory. Run `init.sh` to create a new project, or copy the files manually.

## Architecture

```
USER
  │
  ▼
PI (ORCHESTRATOR)
  │  model: Anthropic Claude Sonnet 4 (configurable in .pi/settings.json)
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
├── .pi/
│   ├── settings.json         # Pi settings (orchestrator model, compaction, retry)
│   ├── models.json           # Provider config (Anthropic, OpenAI, Google, OpenRouter)
│   ├── sub-agents.json       # Sub-agent roster (models, personas — edit this!)
│   ├── extensions/
│   │   ├── sub-agent.ts      # Extension registering the "delegate" tool
│   │   └── team-roster.ts    # Extension registering "team_roster" tool + /team, /team-detail
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
├── AGENTS.md                 # Orchestrator instructions — delegate, never code
├── templates/
│   └── AGENTS.md             # Project-level template (for your actual projects)
├── init.sh                   # Interactive scaffolder: creates project, configures keys, ready to run
└── README.md
```

## Quick Start

### Create a new project (recommended)

```bash
git clone https://github.com/kenken17/agentic-workflow.git /tmp/awf
/tmp/awf/init.sh my-app
```

`init.sh` is an interactive wizard that:
1. Creates the project directory
2. Copies `.pi/` (settings, models, sub-agents, extensions, skills, prompts) and `AGENTS.md`
3. Asks which providers you want (Anthropic, OpenAI, Google, OpenRouter) and collects API keys
4. Writes keys to `.env` (gitignored)
5. Lets you pick the orchestrator model
6. Optionally adds a project description to `AGENTS.md`
7. Initializes git

When it's done:

```bash
cd my-app
source .env    # load API keys into shell
pi             # start coding with your agent team
```

### Manual copy (skip the wizard)

```bash
git clone https://github.com/kenken17/agentic-workflow.git /tmp/awf
cp -r /tmp/awf/.pi /your/project/
cp /tmp/awf/AGENTS.md /your/project/
cd /your/project

# Set API keys
export ANTHROPIC_API_KEY=***     # orchestrator + code-reviewer + devops
export OPENAI_API_KEY=***        # software-engineer + test-engineer
export GOOGLE_API_KEY=***        # frontend-developer

pi
```

Or use `/login` in Pi for subscription auth instead of env vars.

Alternative: use OpenRouter for all models — set `OPENROUTER_API_KEY` and change model IDs in `.pi/sub-agents.json` to OpenRouter format.

### Configure Sub-Agents

Edit `.pi/sub-agents.json` to adjust:

- **Models**: swap any sub-agent's model (e.g., use GPT-4o for frontend instead of Gemini)
- **Personas**: tweak what each sub-agent specializes in
- **Add/remove agents**: add new entries to the `agents` object

### Set Orchestrator Model

Edit `.pi/settings.json`:

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-20250514"
}
```

This is the model that routes tasks. Pick something fast and capable.

### Run

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

Run `/team` inside Pi for a compact table view of all agents and their models, or `/team-detail` for full details including personas.

### Team Roster Extension

The `team-roster.ts` extension provides:

- **`/team`** — Compact table showing all agents, their models, and providers
- **`/team-detail`** — Detailed view with full persona text for each agent
- **`team_roster` tool** — Call from the orchestrator to programmatically query the roster (pass `detailed: true` for personas)

Example `/team` output:
```
┌──────────────────────────────────────────────────┐
│ TEAM ROSTER                                      │
├──────────────────────────────────────────────────┤
│ Agent              │ Model           │ Provider  │
├──────────────────────────────────────────────────┤
│ frontend-developer │ gemini-2-flash  │ Google    │
│ software-engineer  │ o4-mini         │ OpenAI    │
│ code-reviewer      │ claude-sonnet-4 │ Anthropic │
│ devops-engineer    │ claude-sonnet-4 │ Anthropic │
│ test-engineer      │ gpt-4o          │ OpenAI    │
└──────────────────────────────────────────────────┘
```

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

This repo IS the project-level config. The `AGENTS.md` at the root contains the orchestrator instructions. The `.pi/` directory contains all the Pi config.

Each project gets its own isolated config. Copy `.pi/` and `AGENTS.md` into each project. Each can have different sub-agents, models, or personas in `sub-agents.json`.

## Customizing Sub-Agents

Edit `.pi/sub-agents.json`:

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

The extension reads this file at startup from `.pi/sub-agents.json` (project-local, preferred) or `~/.pi/agent/sub-agents.json` (global fallback). New agents appear in the `delegate` tool's enum automatically.

## License

MIT
