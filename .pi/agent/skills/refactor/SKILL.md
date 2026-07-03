---
name: refactor
description: "Structured refactoring workflow that preserves behavior while improving code quality. Includes before/after diff, test verification, and safety checks. Use when cleaning up code, improving performance, reducing complexity, or modernizing patterns."
---

# Refactor Skill

## When to Use
- Cleaning up messy or duplicated code
- Reducing function/file complexity
- Modernizing deprecated patterns
- Improving performance without changing behavior
- Renaming for clarity

## Core Principle

**Behavior must not change.** The refactored code must produce the same outputs for the same inputs. Tests are the safety net.

## Workflow

### Step 1: Assess

1. Read the target code thoroughly
2. Identify the specific problems:
   - Duplication (DRY violations)
   - Long functions (> 40 lines is a yellow flag)
   - Deep nesting (> 3 levels)
   - Poor naming
   - Dead code
   - Tight coupling
   - Missing error handling
3. Decide what to refactor and what to leave alone. Don't refactor everything at once.

### Step 2: Safety Net

- If tests exist: run them first, confirm green. This is your baseline.
- If no tests: write characterization tests (tests that capture current behavior, not desired behavior) before refactoring.
- If no test framework: note the manual verification steps and run them before and after.

### Step 3: Refactor in Small Steps

Each step should be:
- Small enough to review in one glance
- Independently committable
- Test-verifiable

Apply one technique at a time:

1. **Extract function** — Move a block into a named function
2. **Rename** — Change variable/function/field names for clarity
3. **Simplify conditionals** — Early returns, guard clauses, replace nested if/else
4. **Remove duplication** — Extract shared logic into a function
5. **Move** — Relocate code to where it belongs (better module, better layer)
6. **Replace** — Swap deprecated/inefficient patterns with current ones

After each step: run tests. If red, undo and try a different approach.

### Step 4: Verify

1. Run all tests — must match baseline
2. Run linter — must be clean
3. Run type check — must be clean
4. Diff review: confirm only the intended changes are present

### Step 5: Commit

```
refactor: <what was refactored and why>

- Extracted X into function for clarity
- Removed duplicated Y logic
- Simplified Z conditionals with early returns
```

### What NOT to Do

- Do not fix bugs while refactoring. Do that in a separate commit.
- Do not add features while refactoring. Do that in a separate commit.
- Do not change formatting unless that's the explicit refactor goal.
- Do not rewrite working code just because you'd write it differently. Refactor when there's a concrete problem.