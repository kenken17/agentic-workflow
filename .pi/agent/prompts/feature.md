---
description: "Build a feature by delegating to sub-agents"
argument-hint: "<feature-description>"
---
Build the following feature: $@

Break this into subtasks and delegate to appropriate sub-agents:
1. delegate("software-engineer", "implement: $@") for backend/logic work
2. delegate("frontend-developer", "implement UI for: $@") if UI work is needed
3. delegate("code-reviewer", "review the implementation of: $@") after
4. delegate("test-engineer", "write tests for: $@") to verify

Not all steps may be needed. Use your judgment on which sub-agents to involve.