# Agentic Workflow for Pi

A generic, project-agnostic agentic coding workflow for [Pi](https://pi.dev) — the terminal-based coding agent.

## What's Inside

```
agentic-workflow/
├── .pi/agent/
│   ├── AGENTS.md              # Global coding instructions (behavior, git discipline, safety)
│   ├── settings.json         # Pi settings (compaction, retry, steering, skills)
│   ├── models.json           # Provider/model config template (Anthropic, OpenAI, OpenRouter, OpenCode Go)
│   ├── skills/
│   │   ├── code-review/      # Structured code review workflow
│   │   │   ├── SKILL.md
│   │   │   ├── scripts/pr-diff.sh
│   │   │   └── references/checklist.md
│   │   ├── feature-builder/  # End-to-end feature building workflow (TDD)
│   │   │   ├── SKILL.md
│   │   │   └── references/planning-template.md
│   │   └── refactor/         # Safe refactoring workflow (behavior-preserving)
│   │       ├── SKILL.md
│   │       └── references/techniques.md
│   └── prompts/              # Slash-command prompt templates
│       ├── review.md         # /review [staged|<PR-URL>|<files>]
│       ├── refactor.md       # /refactor <file-or-dir>
│       ├── feature.md        # /feature <description>
│       ├── debug.md          # /debug <error-or-description>
│       └── test.md           # /test [<file-or-feature>]
├── templates/
│   └── AGENTS.md             # Project-level AGENTS.md template (drop into project root)
├── setup.sh                  # Installs everything into ~/.pi/agent/
└── README.md
```

## Quick Start

### 1. Install

```bash
git clone https://github.com/<your-username>/agentic-workflow.git
cd agentic-workflow
./setup.sh
```

This copies everything into `~/.pi/agent/` (backing up any existing config first).

### 2. Configure Your Provider

Edit `~/.pi/agent/models.json` and set your provider's API key. Two options:

**Environment variable** (recommended):
```bash
export ANTHROPIC_API_KEY=sk-ant-...
# or
export OPENAI_API_KEY=sk-...
# or
export OPENCODE_GO_API_KEY=...
```

**Or use /login in Pi** (subscription auth):
```bash
pi
/login
```

Set your default provider and model in `~/.pi/agent/settings.json`:
```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-20250514"
}
```

### 3. Use It

```bash
cd /your/project
pi
```

## Skills

### code-review
Structured review workflow. Reviews staged changes, PR diffs, or specific files. Checks correctness, security, performance, maintainability, and testing. Outputs findings by severity with an APPROVE/REQUEST CHANGES/NEEDS DISCUSSION verdict.

### feature-builder
End-to-end feature building. Reads existing code, writes a plan, waits for confirmation, implements with TDD, verifies, and commits. Won't guess when scope is ambiguous — asks.

### refactor
Behavior-preserving refactoring. Establishes a test baseline, applies one technique at a time (extract function, rename, simplify conditionals, remove duplication), runs tests after each step.

## Prompt Templates

| Command | Usage |
|---------|-------|
| `/review` | Review uncommitted changes |
| `/review staged` | Review staged changes only |
| `/review <PR-URL>` | Review a GitHub PR diff |
| `/review src/app.ts` | Review specific files |
| `/refactor <file>` | Refactor a file or directory |
| `/feature <description>` | Build a new feature |
| `/debug <error>` | Systematically debug an issue |
| `/test` | Run project tests |
| `/test <file>` | Write tests for a file |

## Project-Level Customization

Copy `templates/AGENTS.md` to your project root as `AGENTS.md` and fill it with project-specific info:

```bash
cp templates/AGENTS.md /your/project/AGENTS.md
```

Pi loads `AGENTS.md` from parent directories and the current directory at startup.

## License

MIT