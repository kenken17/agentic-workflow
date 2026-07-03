---
description: "Refactor code via the software-engineer sub-agent"
argument-hint: "<file-or-directory>"
---
Refactor the following target by delegating to the software-engineer sub-agent: $@

Use the delegate tool with agent="software-engineer". Include in the task:
- The file/directory to refactor
- Specific issues to address (duplication, complexity, naming, dead code)
- Instruction to preserve behavior, run tests before and after
- Instruction to make small, incremental changes