---
description: "Debug an issue via the software-engineer sub-agent"
argument-hint: "<error-message-or-description>"
---
Debug the following issue by delegating to the software-engineer sub-agent: $@

Use delegate tool with agent="software-engineer". Include in the task:
- The error message or issue description
- Instruction to understand the code before fixing
- Instruction to reproduce the issue first
- Instruction to make the minimal fix
- Instruction to run tests after fixing
- Instruction to write a regression test