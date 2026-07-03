---
name: feature-builder
description: "Structured workflow for building new features end-to-end. Includes scope analysis, implementation planning, TDD, and verification. Use when implementing a new feature, adding a significant capability, or extending an existing module."
---

# Feature Builder Skill

## When to Use
- Building a new feature from a description or ticket
- Extending an existing module with new capability
- Adding a new endpoint, route, command, or component

## Workflow

### Step 1: Understand Scope

Before writing any code:

1. Read the relevant existing code to understand architecture and patterns
2. Identify files that will need changes
3. Identify files that will need new tests
4. Check for existing similar features to follow as patterns
5. Note any conventions: naming, file structure, error handling, logging

If the scope is unclear or ambiguous, ask the user. Do not guess.

### Step 2: Plan

Write a brief implementation plan:

```
## Feature: <name>

### Files to modify
- `path/to/file.ts` — <what changes>

### Files to create
- `path/to/new-file.ts` — <purpose>

### Tests
- `path/to/test.ts` — <what to test>

### Approach
1. <step 1>
2. <step 2>
3. ...

### Risks
- <risk 1>
- <risk 2>
```

Present this to the user. Wait for confirmation before proceeding.

### Step 3: Implement (TDD where applicable)

1. Write tests first for the new behavior
2. Run tests — confirm they fail (RED)
3. Implement the minimum to make tests pass (GREEN)
4. Refactor while keeping tests green (REFACTOR)

If the project has no test framework, implement carefully and test manually via CLI.

### Step 4: Verify

1. Run the project's lint command (if any)
2. Run the project's test command
3. Run the project's build/typecheck command (if any)
4. Manually verify the feature works (CLI test, endpoint call, etc.)

All must pass. If any fails, fix before declaring done.

### Step 5: Commit

1. Stage files in logical groups (tests separate from implementation is OK)
2. Write a clear commit message:

```
feat: <short description of the feature>

<optional body explaining what and why>
```

3. Do not push unless asked.

### Step 6: Summary

Report:
- What was implemented
- Files changed (with counts)
- Test results
- Any follow-up work needed