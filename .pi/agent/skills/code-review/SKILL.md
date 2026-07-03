---
name: code-review
description: "Structured code review workflow. Reviews staged changes, PR diffs, or specific files for bugs, security issues, performance problems, and style violations. Use when reviewing code before commits or PRs."
---

# Code Review Skill

## When to Use
- Before committing changes (`/review` or `/review staged`)
- Reviewing a pull request (`/review <PR-URL>`)
- Reviewing specific files (`/review src/app.ts src/utils.ts`)
- Full working-tree review (`/review` with no arguments)

## Workflow

### Step 1: Gather Changes

Determine what to review based on arguments:

- **No arguments**: `git diff HEAD` (all uncommitted changes)
- **"staged"**: `git diff --cached`
- **PR URL**: Fetch the PR diff via `gh pr diff <URL> > /tmp/pr-diff.patch` then review
- **File paths**: Review those files directly with `read`

### Step 2: Review Checklist

For each file changed, evaluate:

1. **Correctness**
   - Logic errors or edge cases not handled
   - Null/undefined/uninitialized access
   - Off-by-one errors, wrong operators, inverted conditions
   - Race conditions or async issues

2. **Security**
   - Injection vulnerabilities (SQL, command, path traversal)
   - Hardcoded secrets or credentials
   - Unsafe deserialization or eval
   - Missing input validation
   - Overly permissive file permissions

3. **Performance**
   - N+1 queries
   - Unnecessary allocations or copies in hot paths
   - O(n^2) where O(n) is achievable
   - Missing indexes for database queries
   - Blocking async paths

4. **Maintainability**
   - Dead code or unused imports
   - Commented-out code
   - Overly complex functions (high cyclomatic complexity)
   - Missing error handling
   - Inconsistent naming or style vs project conventions

5. **Testing**
   - New code without tests
   - Tests that don't actually assert behavior
   - Missing edge-case tests
   - Skipped or flaky tests not flagged

### Step 3: Output Format

Present findings as:

```
## Code Review: <file>

### Critical (must fix before merge)
- [line N] <issue description>

### Warnings (should fix)
- [line N] <issue description>

### Suggestions (nice to have)
- [line N] <issue description>

### Positive
- <what was done well>
```

If no issues found, say so explicitly. Don't invent problems.

### Step 4: Summary

After all files reviewed, give a one-line verdict:
- APPROVE: No critical issues
- REQUEST CHANGES: Critical issues must be fixed
- NEEDS DISCUSSION: Design-level concerns requiring human judgment

Do not fix issues yourself unless explicitly asked. Report findings only.