---
name: rtk-token-optimization
description: "Install, configure, and use RTK (Rust Token Killer) for 60-90% token savings on terminal tool output. Apply when running shell commands that produce verbose output (git status, ls, grep, test runners, build output, etc.)."
---

# RTK Token Optimization

RTK (https://github.com/rtk-ai/rtk) is a single Rust binary that filters and compresses command outputs before they reach the LLM context. 100+ supported commands, <10ms overhead.

## When to Use

- Before running any shell command that produces verbose output
- When `git status`, `git diff`, `ls`, `grep`, `find`, test runners, or build output is about to be returned to the model
- When working with large directory listings or long log files
- As a default habit: prepend `rtk` to terminal commands whenever possible

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

Installs to `~/.local/bin/rtk`. Ensure it's on PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
# Or symlink system-wide:
ln -sf ~/.local/bin/rtk /usr/local/bin/rtk
```

Verify:

```bash
rtk --version
rtk gain    # shows historic token savings
```

## Usage

Prefix any supported command with `rtk`:

```bash
rtk git status
rtk git diff HEAD~5
rtk ls -la /var/log
rtk grep -r "TODO" src/
rtk npm test
rtk cargo build
```

RTK automatically detects the command and applies the appropriate filter.

## Key Commands

| Command | Purpose |
|---------|---------|
| `rtk <cmd>` | Run a command through RTK filtering |
| `rtk rewrite "<cmd>"` | Preview what RTK would rewrite the command to |
| `rtk gain` | Show accumulated token savings |
| `rtk list` | List all supported commands |

## Pitfalls

- **PATH issues**: If `rtk` is not in the shell's PATH, commands will fail with "rtk: command not found". Use the symlink to `/usr/local/bin/rtk` for reliability.
- **Unsupported commands**: RTK only rewrites commands it recognizes. Unknown commands pass through unchanged.
- **Version syntax**: RTK CLI syntax changed in v0.42.0. Always run `rtk --help` to verify flags for your installed version.

## Integration

For Hermes / Pi agentic workflows, RTK should be installed on the machine where the agent runs terminal commands. The orchestrator and sub-agents should use `rtk <command>` habitually to reduce context bloat.
